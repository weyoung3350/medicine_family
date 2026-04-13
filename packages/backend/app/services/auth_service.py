"""注册、登录、用户查询业务逻辑。"""
from fastapi import HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password, verify_password
from app.models.user import User
from app.schemas.auth import AuthResponse, RegisterRequest, UserOut


async def register(data: RegisterRequest, db: AsyncSession) -> AuthResponse:
    exists = await db.scalar(select(User).where(User.phone == data.phone))
    if exists:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="该手机号已注册")

    user = User(
        phone=data.phone,
        nickname=data.nickname,
        password_hash=hash_password(data.password),
        email=data.email,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    token = create_access_token(str(user.id))
    return AuthResponse(access_token=token, user=UserOut.model_validate(user))


async def login(account: str, password: str, db: AsyncSession) -> AuthResponse | None:
    stmt = select(User).where(or_(User.phone == account, User.email == account))
    user = await db.scalar(stmt)
    if not user or not verify_password(password, user.password_hash):
        return None

    token = create_access_token(str(user.id))
    return AuthResponse(access_token=token, user=UserOut.model_validate(user))


async def get_user_by_id(user_id: str, db: AsyncSession) -> User | None:
    return await db.get(User, user_id)
