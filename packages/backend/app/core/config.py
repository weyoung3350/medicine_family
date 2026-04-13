from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    APP_NAME: str = "家庭健康管家"
    DEBUG: bool = True
    PORT: int = 3000
    API_V1_PREFIX: str = "/api/v1"

    # JWT
    JWT_SECRET: str = "your-jwt-secret-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 10080  # 7 天

    # 千问 AI
    QWEN_API_KEY: str = ""
    QWEN_BASE_URL: str = "https://dashscope.aliyuncs.com/compatible-mode/v1"

    # 高德地图
    AMAP_API_KEY: str = ""

    # 文件上传
    UPLOAD_DIR: str = "uploads"

    # 数据库
    DB_HOST: str = "localhost"
    DB_PORT: int = 5432
    DB_USERNAME: str = "med_user"
    DB_PASSWORD: str = "med_pass_2026"
    DB_DATABASE: str = "med_family"

    @property
    def DATABASE_URL(self) -> str:
        return f"postgresql+asyncpg://{self.DB_USERNAME}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_DATABASE}"

    @property
    def DATABASE_URL_SYNC(self) -> str:
        return f"postgresql+psycopg2://{self.DB_USERNAME}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_DATABASE}"

    model_config = {"env_file": ".env", "extra": "ignore"}


settings = Settings()
