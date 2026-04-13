"""家庭、成员、健康档案业务逻辑。"""
import uuid

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.family import Family
from app.models.family_member import FamilyMember
from app.models.health_profile import HealthProfile
from app.schemas.family import (
    AddDependentRequest,
    CreateFamilyRequest,
    FamilyOut,
    HealthProfileIn,
    HealthProfileOut,
    MemberOut,
)


# ── helpers ──

def _member_out(m: FamilyMember) -> MemberOut:
    hp = None
    if m.health_profile:
        p = m.health_profile
        hp = HealthProfileOut(
            birthDate=p.birth_date,
            gender=p.gender,
            heightCm=p.height_cm,
            weightKg=p.weight_kg,
            bloodType=p.blood_type,
            medicalHistory=p.medical_history or [],
            allergyList=p.allergy_list or [],
            chronicMeds=p.chronic_meds or [],
            notes=p.notes,
        )
    return MemberOut(
        id=m.id,
        displayName=m.display_name,
        role=m.role,
        relationship=m.relationship_label,
        healthProfile=hp,
    )


def _family_out(f: Family, role: str) -> FamilyOut:
    return FamilyOut(id=f.id, name=f.name, inviteCode=f.invite_code, myRole=role)


# ── 家庭 ──

async def create_family(
    data: CreateFamilyRequest, user_id: uuid.UUID, db: AsyncSession,
) -> FamilyOut:
    family = Family(name=data.name, owner_id=user_id)
    db.add(family)
    await db.flush()

    owner = FamilyMember(
        family_id=family.id,
        user_id=user_id,
        display_name="我",
        role="owner",
    )
    db.add(owner)
    await db.commit()
    await db.refresh(family)
    return _family_out(family, "owner")


async def list_families(user_id: uuid.UUID, db: AsyncSession) -> list[FamilyOut]:
    stmt = (
        select(FamilyMember)
        .where(FamilyMember.user_id == user_id)
        .options(selectinload(FamilyMember.family))
    )
    result = await db.scalars(stmt)
    return [_family_out(m.family, m.role) for m in result]


async def join_family(
    invite_code: str, user_id: uuid.UUID, db: AsyncSession,
) -> FamilyOut:
    family = await db.scalar(select(Family).where(Family.invite_code == invite_code))
    if not family:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="邀请码无效")

    exists = await db.scalar(
        select(FamilyMember).where(
            FamilyMember.family_id == family.id,
            FamilyMember.user_id == user_id,
        )
    )
    if exists:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="您已是该家庭成员")

    member = FamilyMember(
        family_id=family.id,
        user_id=user_id,
        display_name="我",
        role="member",
    )
    db.add(member)
    await db.commit()
    return _family_out(family, "member")


# ── 权限校验 ──

async def _check_family_access(
    family_id: uuid.UUID, user_id: uuid.UUID, db: AsyncSession,
) -> FamilyMember:
    """校验用户是否属于该家庭，返回其成员记录。"""
    member = await db.scalar(
        select(FamilyMember).where(
            FamilyMember.family_id == family_id,
            FamilyMember.user_id == user_id,
        )
    )
    if not member:
        raise HTTPException(status.HTTP_403_FORBIDDEN, detail="您不是该家庭成员")
    return member


async def _check_member_in_family(
    family_id: uuid.UUID, member_id: uuid.UUID, db: AsyncSession,
) -> None:
    """校验 member 确实属于该家庭。"""
    exists = await db.scalar(
        select(FamilyMember).where(
            FamilyMember.id == member_id,
            FamilyMember.family_id == family_id,
        )
    )
    if not exists:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="该成员不属于此家庭")


# ── 成员 ──

async def list_members(family_id: uuid.UUID, db: AsyncSession) -> list[MemberOut]:
    stmt = (
        select(FamilyMember)
        .where(FamilyMember.family_id == family_id)
        .options(selectinload(FamilyMember.health_profile))
    )
    result = await db.scalars(stmt)
    return [_member_out(m) for m in result]


async def add_dependent(
    family_id: uuid.UUID,
    data: AddDependentRequest,
    manager_id: uuid.UUID,
    db: AsyncSession,
) -> MemberOut:
    await _check_family_access(family_id, manager_id, db)
    member = FamilyMember(
        family_id=family_id,
        user_id=None,
        display_name=data.displayName,
        role="dependent",
        relationship_label=data.relationship,
        managed_by=manager_id,
    )
    db.add(member)
    await db.flush()

    if data.healthProfile:
        hp = _build_health_profile(member.id, data.healthProfile)
        db.add(hp)

    await db.commit()

    # 重新加载以获取 health_profile 关系
    refreshed = await db.scalar(
        select(FamilyMember)
        .where(FamilyMember.id == member.id)
        .options(selectinload(FamilyMember.health_profile))
    )
    return _member_out(refreshed)


# ── 健康档案 ──

def _build_health_profile(member_id: uuid.UUID, data: HealthProfileIn) -> HealthProfile:
    return HealthProfile(
        member_id=member_id,
        birth_date=data.birthDate,
        gender=data.gender,
        height_cm=data.heightCm,
        weight_kg=data.weightKg,
        blood_type=data.bloodType,
        medical_history=data.medicalHistory,
        allergy_list=data.allergyList,
        chronic_meds=data.chronicMeds,
        notes=data.notes,
    )


async def get_health_profile(
    family_id: uuid.UUID, member_id: uuid.UUID, user_id: uuid.UUID, db: AsyncSession,
) -> HealthProfileOut:
    await _check_family_access(family_id, user_id, db)
    member = await db.scalar(
        select(FamilyMember)
        .where(FamilyMember.id == member_id, FamilyMember.family_id == family_id)
        .options(selectinload(FamilyMember.health_profile))
    )
    if not member:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="成员不存在")

    p = member.health_profile
    if not p:
        return HealthProfileOut()

    return HealthProfileOut(
        birthDate=p.birth_date,
        gender=p.gender,
        heightCm=p.height_cm,
        weightKg=p.weight_kg,
        bloodType=p.blood_type,
        medicalHistory=p.medical_history or [],
        allergyList=p.allergy_list or [],
        chronicMeds=p.chronic_meds or [],
        notes=p.notes,
    )


async def update_health_profile(
    family_id: uuid.UUID, member_id: uuid.UUID, user_id: uuid.UUID,
    data: HealthProfileIn, db: AsyncSession,
) -> HealthProfileOut:
    await _check_family_access(family_id, user_id, db)
    member = await db.scalar(
        select(FamilyMember)
        .where(FamilyMember.id == member_id, FamilyMember.family_id == family_id)
        .options(selectinload(FamilyMember.health_profile))
    )
    if not member:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="成员不存在")

    if member.health_profile:
        p = member.health_profile
        p.birth_date = data.birthDate
        p.gender = data.gender
        p.height_cm = data.heightCm
        p.weight_kg = data.weightKg
        p.blood_type = data.bloodType
        p.medical_history = data.medicalHistory
        p.allergy_list = data.allergyList
        p.chronic_meds = data.chronicMeds
        p.notes = data.notes
    else:
        hp = _build_health_profile(member_id, data)
        db.add(hp)

    await db.commit()
    # expire_on_commit=False 导致 member.health_profile 可能缓存旧值，
    # 只过期这一个对象，让下次访问重新加载
    db.expire(member)
    return await get_health_profile(family_id, member_id, user_id, db)
