"""
Manchester Triage System question-tree traversal.

The question_tree.json has this shape:
{
  "nodes": {
    "<node_id>": {
      "question_es": "...",
      "options": [
        {"label_es": "...", "next_node_id": "<id>"},
        ...
      ]
    }
    | {
      "triage_level": 1-5,
      "complaint_category": "...",
      "max_wait_minutes": 0|10|60|120|240
    }
  },
  "root": "<node_id>"
}
"""
import json
from pathlib import Path

_TREE: dict | None = None
_TREE_PATH = Path(__file__).parent.parent / "seed" / "question_tree.json"

MTS_LABELS = {
    1: "Inmediato",
    2: "Muy urgente",
    3: "Urgente",
    4: "Menos urgente",
    5: "No urgente",
}

MTS_COLORS = {
    1: "#FF0000",  # Red
    2: "#FF6600",  # Orange
    3: "#FFD700",  # Yellow
    4: "#008000",  # Green
    5: "#0000FF",  # Blue
}


def _load_tree() -> dict:
    global _TREE
    if _TREE is None:
        _TREE = json.loads(_TREE_PATH.read_text(encoding="utf-8"))
    return _TREE


def get_full_tree() -> dict:
    return _load_tree()


def evaluate(answers: list[dict]) -> dict:
    """
    Traverse the question tree given a list of {node_id, answer_index} pairs.
    Returns the leaf node data enriched with MTS metadata.
    """
    tree = _load_tree()
    nodes = tree["nodes"]

    # Build a lookup map answer_index by node_id
    answer_map: dict[str, int] = {a["node_id"]: a["answer_index"] for a in answers}

    current_id: str = tree["root"]

    for _ in range(200):  # safety cap
        node = nodes.get(current_id)
        if node is None:
            raise ValueError(f"Nodo no encontrado: {current_id}")

        if "triage_level" in node:
            level = node["triage_level"]
            return {
                "level": level,
                "label": MTS_LABELS[level],
                "color_hex": MTS_COLORS[level],
                "max_wait_minutes": node["max_wait_minutes"],
                "complaint_category": node["complaint_category"],
            }

        if current_id not in answer_map:
            raise ValueError(f"Respuesta faltante para nodo: {current_id}")

        idx = answer_map[current_id]
        options = node.get("options", [])
        if idx < 0 or idx >= len(options):
            raise ValueError(f"Índice de respuesta inválido {idx} para nodo {current_id}")

        current_id = options[idx]["next_node_id"]

    raise ValueError("Árbol de decisión demasiado profundo o ciclo detectado")
