import pytest
from sqlalchemy import create_engine, event
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.base import Base
import app.models  # noqa: F401 — 确保所有模型注册到 Base.metadata


@pytest.fixture(scope="session")
def engine():
    engine = create_engine(settings.DATABASE_URL_SYNC)
    Base.metadata.create_all(engine)
    yield engine
    engine.dispose()


@pytest.fixture()
def db(engine):
    """使用 savepoint 隔离：即使测试调用 commit() 也能安全回滚。"""
    connection = engine.connect()
    transaction = connection.begin()
    session = Session(bind=connection, join_transaction_mode="create_savepoint")

    yield session

    session.close()
    transaction.rollback()
    connection.close()
