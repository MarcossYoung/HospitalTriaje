import pytest


@pytest.mark.asyncio
async def test_register_and_login(client):
    # Register
    resp = await client.post("/auth/register", json={"email": "test@example.com", "password": "secret123"})
    assert resp.status_code == 201
    data = resp.json()
    assert "access_token" in data

    # Login
    resp2 = await client.post("/auth/login", json={"email": "test@example.com", "password": "secret123"})
    assert resp2.status_code == 200
    assert "access_token" in resp2.json()


@pytest.mark.asyncio
async def test_register_duplicate_email(client):
    await client.post("/auth/register", json={"email": "dup@example.com", "password": "pass"})
    resp = await client.post("/auth/register", json={"email": "dup@example.com", "password": "pass2"})
    assert resp.status_code == 409


@pytest.mark.asyncio
async def test_login_wrong_password(client):
    await client.post("/auth/register", json={"email": "wrong@example.com", "password": "correct"})
    resp = await client.post("/auth/login", json={"email": "wrong@example.com", "password": "wrong"})
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_get_profile_authenticated(client):
    reg = await client.post("/auth/register", json={"email": "profile@example.com", "password": "pass"})
    token = reg.json()["access_token"]
    resp = await client.get("/patients/me", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert resp.json()["email"] == "profile@example.com"


@pytest.mark.asyncio
async def test_get_profile_unauthenticated(client):
    resp = await client.get("/patients/me")
    assert resp.status_code == 401
