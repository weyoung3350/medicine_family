"""认证相关的请求与响应模型，字段对齐前端 api/auth.ts。"""
import uuid

from pydantic import BaseModel, ConfigDict


class RegisterRequest(BaseModel):
    phone: str
    nickname: str
    password: str
    email: str | None = None


class LoginRequest(BaseModel):
    account: str          # 手机号或邮箱
    password: str


class UserOut(BaseModel):
    """返回给前端的用户信息，不含 password_hash。"""
    id: uuid.UUID
    phone: str
    email: str | None = None
    nickname: str
    avatar_url: str | None = None

    model_config = ConfigDict(from_attributes=True)


class AuthResponse(BaseModel):
    """注册/登录统一返回，对齐前端 { access_token, user }。"""
    access_token: str
    user: UserOut
