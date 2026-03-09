from datetime import datetime, timedelta, timezone

import httpx
from jose import JWTError, jwt
import bcrypt as _bcrypt

from app.config import settings


def hash_password(password: str) -> str:
    return _bcrypt.hashpw(password.encode(), _bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    return _bcrypt.checkpw(plain.encode(), hashed.encode())


def create_access_token(subject: int | str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.access_token_expire_minutes)
    payload = {"sub": str(subject), "exp": expire}
    return jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)


def decode_token(token: str) -> dict:
    return jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])


async def verify_google_id_token(id_token: str) -> dict:
    """
    Verify a Google ID token by calling Google's tokeninfo endpoint.
    Returns the decoded payload or raises ValueError.
    """
    url = f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}"
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(url)
    if resp.status_code != 200:
        raise ValueError("Google ID token inválido")
    data = resp.json()
    if data.get("aud") != settings.google_client_id:
        raise ValueError("Google client_id no coincide")
    return data
