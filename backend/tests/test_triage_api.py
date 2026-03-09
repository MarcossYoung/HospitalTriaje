import pytest


@pytest.mark.asyncio
async def test_get_questions(client):
    resp = await client.get("/triage/questions")
    assert resp.status_code == 200
    data = resp.json()
    assert "root" in data
    assert "nodes" in data


@pytest.mark.asyncio
async def test_evaluate_triage(client):
    answers = [
        {"node_id": "start", "answer_index": 0},
        {"node_id": "chest_pain_initial", "answer_index": 0},
        {"node_id": "chest_severe", "answer_index": 0},
    ]
    resp = await client.post("/triage/evaluate", json={"answers": answers})
    assert resp.status_code == 200
    data = resp.json()
    assert data["level"] == 1
    assert data["session_id"] > 0


@pytest.mark.asyncio
async def test_evaluate_invalid_tree_path(client):
    resp = await client.post("/triage/evaluate", json={"answers": [{"node_id": "start", "answer_index": 0}]})
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_evaluate_persists_session(client):
    answers = [
        {"node_id": "start", "answer_index": 4},
        {"node_id": "general_initial", "answer_index": 2},
        {"node_id": "general_symptoms", "answer_index": 2},
    ]
    resp = await client.post("/triage/evaluate", json={"answers": answers})
    assert resp.status_code == 200
    session_id = resp.json()["session_id"]

    resp2 = await client.get(f"/triage/sessions/{session_id}")
    assert resp2.status_code == 200
    assert resp2.json()["id"] == session_id
