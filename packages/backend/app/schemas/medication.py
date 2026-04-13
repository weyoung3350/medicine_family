"""服药计划、打卡、依从性的请求/响应模型。"""
import uuid
from datetime import date, datetime, time

from pydantic import BaseModel, Field


# ---------- 时间点 ----------

class ScheduleIn(BaseModel):
    timeOfDay: str   # "HH:MM"
    label: str | None = None


class ScheduleOut(BaseModel):
    id: uuid.UUID
    timeOfDay: str
    label: str | None = None
    sortOrder: int = 0


# ---------- 计划 ----------

class CreatePlanRequest(BaseModel):
    medicineId: uuid.UUID
    dosageAmount: float
    dosageUnit: str
    frequencyType: str          # daily / every_other_day / weekly / custom
    frequencyDays: list[int] | None = None
    customInterval: int | None = None
    mealRelation: str | None = None
    startDate: date
    endDate: date | None = None
    gracePeriodMinutes: int = 15
    schedules: list[ScheduleIn]
    notes: str | None = None


class PlanOut(BaseModel):
    id: uuid.UUID
    medicineId: uuid.UUID
    medicineName: str
    dosageAmount: float
    dosageUnit: str
    frequencyType: str
    frequencyDays: list[int] | None = None
    customInterval: int | None = None
    mealRelation: str | None = None
    startDate: date
    endDate: date | None = None
    gracePeriodMinutes: int
    isActive: bool
    schedules: list[ScheduleOut] = Field(default_factory=list)


# ---------- 今日计划项 ----------

class TodayItem(BaseModel):
    logId: uuid.UUID
    planId: uuid.UUID
    scheduleId: uuid.UUID
    medicineId: uuid.UUID
    medicineName: str
    dosageAmount: float
    dosageUnit: str
    mealRelation: str | None = None
    scheduledTime: str
    timeLabel: str | None = None
    status: str  # pending / taken / skipped / missed


# ---------- 打卡 ----------

class CheckInRequest(BaseModel):
    status: str          # taken / skipped
    skipReason: str | None = None
    notes: str | None = None


class CheckInResult(BaseModel):
    logId: uuid.UUID
    status: str
    takenAt: datetime | None = None
    skipReason: str | None = None


# ---------- 依从性 ----------

class AdherenceStats(BaseModel):
    total: int
    taken: int
    skipped: int
    missed: int
    adherenceRate: float
    dailyBreakdown: list[dict] = Field(default_factory=list)
