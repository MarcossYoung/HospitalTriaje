import bcrypt as _bcrypt
from fastapi import Depends, HTTPException, Security, status
from fastapi.security import APIKeyHeader
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.hospital import Hospital

_api_key_header = APIKeyHeader(name="X-API-Token", auto_error=True)


async def verify_hospital_token(
    hospital_id: int,
    token: str = Security(_api_key_header),
    db: AsyncSession = Depends(get_db),
) -> Hospital:
    result = await db.execute(select(Hospital).where(Hospital.id == hospital_id))
    hospital = result.scalar_one_or_none()
    if not hospital or not hospital.api_token_hash:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Token inválido")
    if not _bcrypt.checkpw(token.encode(), hospital.api_token_hash.encode()):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Token inválido")
    return hospital
