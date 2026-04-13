from sqlalchemy import inspect

from app.models.user import User


def test_user_table_exists(engine):
    inspector = inspect(engine)
    assert "user" in inspector.get_table_names()


def test_user_table_columns(engine):
    inspector = inspect(engine)
    columns = {col["name"] for col in inspector.get_columns("user")}
    expected = {"id", "phone", "email", "nickname", "password_hash", "avatar_url", "created_at", "updated_at"}
    assert expected.issubset(columns)


def test_user_create_and_query(db):
    user = User(phone="13800000001", nickname="测试用户", password_hash="hashed")
    db.add(user)
    db.flush()

    found = db.query(User).filter_by(phone="13800000001").first()
    assert found is not None
    assert found.nickname == "测试用户"
    assert found.id is not None
