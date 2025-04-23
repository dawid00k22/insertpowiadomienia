# backend/scheduler.py
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime
from db.database import get_db_connection
from google.oauth2 import service_account
from google.auth.transport.requests import Request
import requests

SERVICE_ACCOUNT_FILE = 'firebase-key.json'
PROJECT_ID = 'fcm-flutter-app-71750'
SCOPES = ['https://www.googleapis.com/auth/firebase.messaging']

def send_fcm_notification(title, body, image):
    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=SCOPES)
    credentials.refresh(Request())
    access_token = credentials.token

    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json; UTF-8',
    }

    message = {
        "message": {
            "topic": "all",
            "notification": {
                "title": title,
                "body": body,
                "image": image
            },
            "data": {
                "click_action": "FLUTTER_NOTIFICATION_CLICK"
            }
        }
    }

    response = requests.post(
        f'https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send',
        headers=headers,
        json=message
    )
    print(f"Wysłano powiadomienie: {title}, status: {response.status_code}")

def update_and_send_notifications():
    now = datetime.utcnow()
    print(f"⏰ Sprawdzam powiadomienia: {now}")

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT * FROM notificationsigora
        WHERE sent = FALSE AND scheduled_time <= %s
    """, (now,))
    notifications = cursor.fetchall()

    for notif in notifications:
        send_fcm_notification(notif['title'], notif['content'], notif['leadingImage'])
        cursor.execute("""
            UPDATE notificationsigora
            SET sent = TRUE
            WHERE id = %s
        """, (notif['id'],))
        conn.commit()

    print(f"✅ Wysłano i zaktualizowano {len(notifications)} powiadomienie(a)")
    cursor.close()
    conn.close()

def start_scheduler():
    scheduler = BackgroundScheduler()
    scheduler.add_job(update_and_send_notifications, 'interval', minutes=1)
    scheduler.start()
    print("🚀 Scheduler wystartował")