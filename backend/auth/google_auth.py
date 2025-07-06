from google.oauth2 import id_token
from google.auth.transport import requests
from fastapi import HTTPException
from db.database import get_db_connection
from dotenv import load_dotenv
import os
import logging

# 🔃 Wczytaj .env
load_dotenv()

# 🔧 Konfiguracja logów
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 📥 Lista dozwolonych Client ID z .env
VALID_CLIENT_IDS = os.getenv("GOOGLE_CLIENT_IDS", "").split(",")


def verify_google_token(token: str) -> str:
    logger.info("🧪 Próba weryfikacji tokena Google")
    try:
        idinfo = id_token.verify_oauth2_token(token, requests.Request())
        aud = idinfo.get("aud")
        if aud not in VALID_CLIENT_IDS:
            raise ValueError(f"Token has wrong audience: {aud}")
        email = idinfo["email"]
        logger.info(f"✅ Token poprawny — email: {email}")
        return email
    except Exception as e:
        logger.error(f"❌ Błąd weryfikacji tokena: {e}")
        raise HTTPException(status_code=401, detail="Invalid Google token")


def is_user_in_db(email: str) -> bool:
    logger.info(f"🔍 Sprawdzam, czy email istnieje w bazie: {email}")
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM users WHERE email = %s", (email,))
        result = cursor.fetchone()
        conn.close()
        if result and result[0] > 0:
            logger.info(f"✅ Email {email} istnieje w bazie danych")
            return True
        else:
            logger.warning(f"⚠️ Email {email} NIE istnieje w bazie danych")
            return False
    except Exception as db_error:
        logger.error(f"💥 Błąd połączenia z bazą danych: {db_error}")
        raise HTTPException(status_code=500, detail="Database error")
