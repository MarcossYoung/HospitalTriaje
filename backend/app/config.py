import logging
import warnings

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Database
    database_url: str = "postgresql+asyncpg://triaje:triaje_pass@db:5432/hospitaltriaje"

    @field_validator("database_url", mode="before")
    @classmethod
    def fix_db_url(cls, v: str) -> str:
        # Railway PostgreSQL addon provides postgresql:// — asyncpg needs postgresql+asyncpg://
        if isinstance(v, str) and v.startswith("postgresql://"):
            return v.replace("postgresql://", "postgresql+asyncpg://", 1)
        return v

    # Security
    secret_key: str = "change-me-in-production"
    access_token_expire_minutes: int = 60
    algorithm: str = "HS256"

    # Google OAuth
    google_client_id: str = ""

    # Firebase
    firebase_credentials_json: str = "./firebase-credentials.json"

    # App
    app_env: str = "development"
    backend_cors_origins: str = (
        "http://localhost,http://localhost:80,http://localhost:8080,"
        "http://localhost:8000,http://localhost:3000,"
        "http://10.0.2.2:8000"
    )

    # SSE
    sse_max_connections_per_ip: int = 10

    @property
    def cors_origins(self) -> list[str]:
        return [o.strip() for o in self.backend_cors_origins.split(",") if o.strip()]


settings = Settings()

if settings.secret_key == "change-me-in-production" and settings.app_env != "development":
    warnings.warn(
        "SECRET_KEY is using the insecure default value! Set SECRET_KEY env var for production.",
        stacklevel=1,
    )
    logging.getLogger(__name__).warning(
        "SECURITY WARNING: SECRET_KEY is using the insecure default. JWTs can be forged."
    )
