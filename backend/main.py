from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from auth.google_auth import verify_google_token, is_user_in_db
from routes import notifications
from scheduler import start_scheduler
from routes.notifications import get_notifications

app = FastAPI()

# Opcjonalnie: CORS, jeśli potrzebujesz
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

start_scheduler()

app.include_router(notifications.router)





@app.get("/auth/google")
def auth_google(token: str):
    print(f"🔐 Otrzymany token: {token}")
    
    email = verify_google_token(token)
    if not email:
        print("❌ Nieprawidłowy token")
        raise HTTPException(status_code=401, detail="Invalid token")

    print(f"📩 Email z tokena: {email}")
    
    if is_user_in_db(email):
        print("✅ Email jest w bazie da  nych")
        return {"status": "success", "email": email}
    else:
        print("❌ Email NIE istnieje w bazie danych")
        raise HTTPException(status_code=403, detail="Unauthorized user")
@app.get("/notifications")
def read_notifications():
    return get_notifications()

