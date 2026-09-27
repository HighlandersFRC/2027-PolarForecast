from dotenv import load_dotenv
import os
from pathlib import Path

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

TBA_KEY = os.getenv("TBA_KEY")
MONGO_URI = os.getenv("MONGO_URI")


TBA_API_URL = "https://www.thebluealliance.com/api/v3/"

if TBA_KEY == None or TBA_KEY == "":
    print("PLEASE INPUT TBA API KEY INTO .env")

KEYCLOAK_BASE_URL = os.getenv("KEYCLOAK_BASE_URL", "http://localhost:8000")
KEYCLOAK_MASTER_REALM = os.getenv("KEYCLOAK_MASTER_REALM", "master")
KEYCLOAK_REALM = os.getenv("KEYCLOAK_REALM", "polarforecast-web")
KEYCLOAK_ADMIN_AUTH_MODE = os.getenv(
    "KEYCLOAK_ADMIN_AUTH_MODE",
    "auto",
).strip().lower()
KEYCLOAK_ADMIN_USERNAME = os.getenv(
    "KEYCLOAK_ADMIN_USERNAME",
    "admin",
).strip()
KEYCLOAK_ADMIN_PASSWORD = os.getenv(
    "KEYCLOAK_ADMIN_PASSWORD",
    "admin",
)
KEYCLOAK_ADMIN_CLIENT_ID = os.getenv(
    "KEYCLOAK_ADMIN_CLIENT_ID",
    "admin-cli",
).strip()
KEYCLOAK_ADMIN_CLIENT_SECRET = os.getenv("KEYCLOAK_ADMIN_CLIENT_SECRET", "").strip()
KEYCLOAK_ADMIN_REALM = os.getenv("KEYCLOAK_ADMIN_REALM", "").strip()

if KEYCLOAK_ADMIN_AUTH_MODE not in {
    "auto",
    "password",
    "client_credentials",
}:
    raise ValueError(
        "KEYCLOAK_ADMIN_AUTH_MODE must be auto, password, or "
        "client_credentials"
    )

if not KEYCLOAK_ADMIN_REALM:
    KEYCLOAK_ADMIN_REALM = (
        KEYCLOAK_REALM
        if (
            KEYCLOAK_ADMIN_AUTH_MODE == "client_credentials"
            or (
                KEYCLOAK_ADMIN_AUTH_MODE == "auto"
                and bool(KEYCLOAK_ADMIN_CLIENT_SECRET)
            )
        )
        else KEYCLOAK_MASTER_REALM
    )

if (
    KEYCLOAK_ADMIN_AUTH_MODE == "password"
    and not KEYCLOAK_ADMIN_PASSWORD
):
    print("PLEASE INPUT KEYCLOAK_ADMIN_PASSWORD INTO .env")

if (
    KEYCLOAK_ADMIN_AUTH_MODE == "client_credentials"
    and not KEYCLOAK_ADMIN_CLIENT_SECRET
):
    print("PLEASE INPUT KEYCLOAK_ADMIN_CLIENT_SECRET INTO .env")





_default_allow_origins = [
    "http://127.0.0.1:3000",
    "http://localhost:3000",
    "http://localhost:8080",
    "https://polarforecastfrc.com",
    "https://polarforecastfrc.com:8443"
]

_allow_origins_from_env = os.environ.get("ALLOW_ORIGINS", "").strip()
_env_allow_origins = []

if _allow_origins_from_env:
    _env_allow_origins = [origin.strip() for origin in _allow_origins_from_env.split(",") if origin.strip()]
    
ALLOW_ORIGINS = list(dict.fromkeys(_default_allow_origins + _env_allow_origins))
