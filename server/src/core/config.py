from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=[".env", ".secrets"],
        env_file_encoding="utf-8",
    )

    host: str = "0.0.0.0"
    port: int = 3000
    log_level: str = "INFO"
    cache_dir: str = ".cache"
    http_timeout_seconds: float = 30.0
    news_update_interval_min: int = 30
    mensa_update_cron: str = "0 7,13 * * *"
    helpful_numbers_update_cron: str = "0 7 * * *"
    map_update_cron: str = "0 8 * * *"

    # Secrets — loaded from .secrets, never logged
    server_address: str = ""
    proxy_url: str = ""
    mensa_api_key: SecretStr = SecretStr("")
    sentry_dsn: SecretStr = SecretStr("")
    smtp_host: str = ""
    smtp_user: str = ""
    smtp_password: SecretStr = SecretStr("")


settings = Settings()
