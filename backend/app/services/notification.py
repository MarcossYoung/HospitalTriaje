"""
Firebase Cloud Messaging notification service.
Initialisation is lazy and safe to skip when credentials are missing (dev mode).
"""
import logging
import os
from pathlib import Path

logger = logging.getLogger(__name__)

_firebase_app = None
_firebase_initialized = False


def _init_firebase() -> bool:
    global _firebase_app, _firebase_initialized
    if _firebase_initialized:
        return _firebase_app is not None
    _firebase_initialized = True

    creds_path = os.getenv("FIREBASE_CREDENTIALS_JSON", "./firebase-credentials.json")
    if not Path(creds_path).exists():
        logger.warning("Firebase credentials not found at %s — push notifications disabled", creds_path)
        return False

    try:
        import firebase_admin
        from firebase_admin import credentials

        cred = credentials.Certificate(creds_path)
        _firebase_app = firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin SDK initialised")
        return True
    except Exception as exc:
        logger.error("Failed to initialise Firebase: %s", exc)
        return False


async def send_triage_notification(fcm_token: str, triage_level: int, label: str) -> None:
    if not _init_firebase():
        return
    try:
        from firebase_admin import messaging

        message = messaging.Message(
            notification=messaging.Notification(
                title=f"Resultado de triaje: {label}",
                body=f"Nivel {triage_level} — por favor siga las instrucciones en la aplicación.",
            ),
            data={"triage_level": str(triage_level), "label": label},
            token=fcm_token,
        )
        response = messaging.send(message)
        logger.info("FCM message sent: %s", response)
    except Exception as exc:
        logger.error("FCM send failed: %s", exc)
