"""家庭、成员、健康档案的请求/响应模型，对齐前端 api/family.ts。"""
import uuid
from datetime import date

from pydantic import BaseModel, ConfigDict, Field


# ---------- 健康档案 ----------

class HealthProfileIn(BaseModel):
    birthDate: date | None = None
    gender: int | None = None
    heightCm: float | None = None
    weightKg: float | None = None
    bloodType: str | None = None
    medicalHistory: list[str] = Field(default_factory=list)
    allergyList: list[str] = Field(default_factory=list)
    chronicMeds: list[str] = Field(default_factory=list)
    notes: str | None = None


class HealthProfileOut(BaseModel):
    birthDate: date | None = None
    gender: int | None = None
    heightCm: float | None = None
    weightKg: float | None = None
    bloodType: str | None = None
    medicalHistory: list[str] = Field(default_factory=list)
    allergyList: list[str] = Field(default_factory=list)
    chronicMeds: list[str] = Field(default_factory=list)
    notes: str | None = None


# ---------- 成员 ----------

class AddDependentRequest(BaseModel):
    displayName: str
    relationship: str | None = None
    healthProfile: HealthProfileIn | None = None


class MemberOut(BaseModel):
    id: uuid.UUID
    displayName: str
    role: str
    relationship: str | None = None
    healthProfile: HealthProfileOut | None = None


# ---------- 家庭 ----------

class CreateFamilyRequest(BaseModel):
    name: str


class JoinFamilyRequest(BaseModel):
    inviteCode: str


class FamilyOut(BaseModel):
    id: uuid.UUID
    name: str
    inviteCode: str
    myRole: str
