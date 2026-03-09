import pytest

from app.services.triage_engine import evaluate, get_full_tree


def test_get_full_tree():
    tree = get_full_tree()
    assert "root" in tree
    assert "nodes" in tree
    assert tree["root"] in tree["nodes"]


def test_evaluate_level1_cardiac():
    # chest pain → severe → cardiac symptoms
    answers = [
        {"node_id": "start", "answer_index": 0},          # Dolor en pecho
        {"node_id": "chest_pain_initial", "answer_index": 0},  # Intenso
        {"node_id": "chest_severe", "answer_index": 0},    # Sudoración + brazo
    ]
    result = evaluate(answers)
    assert result["level"] == 1
    assert result["complaint_category"] == "cardiaco"
    assert result["max_wait_minutes"] == 0


def test_evaluate_level2_neuro():
    answers = [
        {"node_id": "start", "answer_index": 1},          # Pérdida de conciencia
        {"node_id": "neuro_initial", "answer_index": 2},  # Dificultad para hablar
    ]
    result = evaluate(answers)
    assert result["level"] == 2
    assert result["complaint_category"] == "neurologico"


def test_evaluate_level5_general():
    answers = [
        {"node_id": "start", "answer_index": 4},            # Fiebre / malestar
        {"node_id": "general_initial", "answer_index": 2},  # No tengo fiebre
        {"node_id": "general_symptoms", "answer_index": 2}, # Otros síntomas leves
    ]
    result = evaluate(answers)
    assert result["level"] == 5
    assert result["max_wait_minutes"] == 240


def test_evaluate_missing_answer():
    with pytest.raises(ValueError, match="Respuesta faltante"):
        evaluate([{"node_id": "start", "answer_index": 0}])


def test_evaluate_invalid_answer_index():
    with pytest.raises(ValueError, match="Índice de respuesta inválido"):
        evaluate([{"node_id": "start", "answer_index": 99}])
