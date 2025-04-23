from google.oauth2 import id_token
from google.auth.transport import requests
from fastapi import HTTPException
import os
from db.database import get_db_connection
import logging
logging.basicConfig(level=logging.INFO)
def verify_google_token(token: str) -> str:
    try:
        idinfo = id_token.verify_oauth2_token(token, requests.Request(), os.getenv("GOOGLE_CLIENT_ID"))
        email = idinfo["email"]
        return email
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid Google token")

def is_user_in_db(email: str) -> bool:
    print(f"🔍 Sprawdzam email w bazie: {email}")
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM users WHERE email = %s", (email,))
    result = cursor.fetchone()
    print(f"📊 Wynik zapytania SQL: {result}")
    conn.close()
    return result[0] > 0



