"""服药计划、打卡、依从性统计业务逻辑。"""
import uuid
from datetime import date, datetime, time, timedelta, timezone

from fastapi import HTTPException, status
from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.medication_log import MedicationLog
from app.models.medication_plan import MedicationPlan
from app.models.medication_schedule import MedicationSchedule
from app.schemas.medication import (
    AdherenceStats,
    CheckInRequest,
    CheckInResult,
    CreatePlanRequest,
    PlanOut,
    ScheduleOut,
    TodayItem,
)


# ── helpers ──

def _schedule_out(s: MedicationSchedule) -> ScheduleOut:
    return ScheduleOut(
        id=s.id,
        timeOfDay=s.time_of_day.strftime("%H:%M"),
        label=s.label,
        sortOrder=s.sort_order,
    )


def _plan_out(p: MedicationPlan) -> PlanOut:
    return PlanOut(
        id=p.id,
        medicineId=p.medicine_id,
        medicineName=p.medicine.name if p.medicine else "",
        dosageAmount=float(p.dosage_amount),
        dosageUnit=p.dosage_unit,
        frequencyType=p.frequency_type,
        frequencyDays=p.frequency_days,
        customInterval=p.custom_interval,
        mealRelation=p.meal_relation,
        startDate=p.start_date,
        endDate=p.end_date,
        gracePeriodMinutes=p.grace_period_minutes,
        isActive=p.is_active,
        schedules=[_schedule_out(s) for s in (p.schedules or [])],
    )


def _should_take_today(plan: MedicationPlan, today: date) -> bool:
    """判断今天是否需要服药。"""
    if plan.start_date > today:
        return False
    if plan.end_date and plan.end_date < today:
        return False

    ft = plan.frequency_type
    if ft == "daily":
        return True
    if ft == "every_other_day":
        delta = (today - plan.start_date).days
        return delta % 2 == 0
    if ft == "weekly":
        return today.isoweekday() in (plan.frequency_days or [])
    if ft == "custom":
        interval = plan.custom_interval or 1
        delta = (today - plan.start_date).days
        return delta % interval == 0
    return True


# ── 计划 ──

async def create_plan(
    member_id: uuid.UUID, data: CreatePlanRequest,
    user_id: uuid.UUID, db: AsyncSession,
) -> PlanOut:
    plan = MedicationPlan(
        member_id=member_id,
        medicine_id=data.medicineId,
        dosage_amount=data.dosageAmount,
        dosage_unit=data.dosageUnit,
        frequency_type=data.frequencyType,
        frequency_days=data.frequencyDays,
        custom_interval=data.customInterval,
        meal_relation=data.mealRelation,
        start_date=data.startDate,
        end_date=data.endDate,
        grace_period_minutes=data.gracePeriodMinutes,
        notes=data.notes,
        created_by=user_id,
    )
    db.add(plan)
    await db.flush()

    for i, s in enumerate(data.schedules):
        h, m = map(int, s.timeOfDay.split(":"))
        sched = MedicationSchedule(
            plan_id=plan.id,
            time_of_day=time(h, m),
            label=s.label,
            sort_order=i,
        )
        db.add(sched)

    await db.commit()

    result = await db.scalar(
        select(MedicationPlan)
        .where(MedicationPlan.id == plan.id)
        .options(selectinload(MedicationPlan.schedules),
                 selectinload(MedicationPlan.medicine))
    )
    return _plan_out(result)


async def list_plans(member_id: uuid.UUID, db: AsyncSession) -> list[PlanOut]:
    stmt = (
        select(MedicationPlan)
        .where(MedicationPlan.member_id == member_id, MedicationPlan.is_active.is_(True))
        .options(selectinload(MedicationPlan.schedules),
                 selectinload(MedicationPlan.medicine))
    )
    result = await db.scalars(stmt)
    return [_plan_out(p) for p in result]


# ── 今日计划 ──

async def get_today(member_id: uuid.UUID, db: AsyncSession) -> list[TodayItem]:
    """生成今日服药条目：为每个 schedule 确保有 log 行，返回所有条目。"""
    today = date.today()
    plans = await db.scalars(
        select(MedicationPlan)
        .where(MedicationPlan.member_id == member_id, MedicationPlan.is_active.is_(True))
        .options(selectinload(MedicationPlan.schedules),
                 selectinload(MedicationPlan.medicine))
    )

    items: list[TodayItem] = []
    for plan in plans:
        if not _should_take_today(plan, today):
            continue
        for sched in plan.schedules:
            # 查找或创建 log
            log = await db.scalar(
                select(MedicationLog).where(
                    MedicationLog.schedule_id == sched.id,
                    MedicationLog.scheduled_date == today,
                )
            )
            if not log:
                log = MedicationLog(
                    schedule_id=sched.id,
                    plan_id=plan.id,
                    member_id=member_id,
                    scheduled_date=today,
                    scheduled_time=sched.time_of_day,
                    status="pending",
                )
                db.add(log)
                await db.flush()

            items.append(TodayItem(
                logId=log.id,
                planId=plan.id,
                scheduleId=sched.id,
                medicineId=plan.medicine_id,
                medicineName=plan.medicine.name if plan.medicine else "",
                dosageAmount=float(plan.dosage_amount),
                dosageUnit=plan.dosage_unit,
                mealRelation=plan.meal_relation,
                scheduledTime=sched.time_of_day.strftime("%H:%M"),
                timeLabel=sched.label,
                status=log.status,
            ))

    await db.commit()
    items.sort(key=lambda x: x.scheduledTime)
    return items


# ── 打卡 ──

async def check_in(
    schedule_id: uuid.UUID, data: CheckInRequest,
    user_id: uuid.UUID, db: AsyncSession,
) -> CheckInResult:
    today = date.today()
    log = await db.scalar(
        select(MedicationLog).where(
            MedicationLog.schedule_id == schedule_id,
            MedicationLog.scheduled_date == today,
        )
    )
    if not log:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="今日无该条服药记录")

    log.status = data.status
    log.recorded_by = user_id
    log.notes = data.notes
    if data.status == "taken":
        log.taken_at = datetime.now(timezone.utc)
    elif data.status == "skipped":
        log.skip_reason = data.skipReason

    await db.commit()
    await db.refresh(log)
    return CheckInResult(
        logId=log.id,
        status=log.status,
        takenAt=log.taken_at,
        skipReason=log.skip_reason,
    )


# ── 依从性统计 ──

async def get_adherence(
    member_id: uuid.UUID, range_type: str, db: AsyncSession,
) -> AdherenceStats:
    today = date.today()
    if range_type == "month":
        start = today - timedelta(days=30)
    else:
        start = today - timedelta(days=7)

    logs = await db.scalars(
        select(MedicationLog).where(
            MedicationLog.member_id == member_id,
            MedicationLog.scheduled_date >= start,
            MedicationLog.scheduled_date <= today,
        )
    )
    logs_list = list(logs)
    total = len(logs_list)
    taken = sum(1 for l in logs_list if l.status == "taken")
    skipped = sum(1 for l in logs_list if l.status == "skipped")
    missed = sum(1 for l in logs_list if l.status == "missed")

    rate = round(taken / total * 100, 1) if total > 0 else 0.0

    # 按日分组
    daily: dict[str, dict] = {}
    for l in logs_list:
        d = l.scheduled_date.isoformat()
        if d not in daily:
            daily[d] = {"date": d, "total": 0, "taken": 0, "missed": 0, "skipped": 0}
        daily[d]["total"] += 1
        if l.status in daily[d]:
            daily[d][l.status] += 1

    return AdherenceStats(
        total=total,
        taken=taken,
        skipped=skipped,
        missed=missed,
        adherenceRate=rate,
        dailyBreakdown=sorted(daily.values(), key=lambda x: x["date"]),
    )
