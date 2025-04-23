from fastapi import APIRouter, HTTPException
from db.database import get_db_connection
from models.notification import Notification, NotificationCreate
from datetime import datetime

router = APIRouter()

def generate_excerpt(content: str) -> str:
    return content.strip().split('.')[0] + '.' if '.' in content else content

@router.get("/notifications", response_model=list[Notification])
def get_notifications():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # Pokazuj tylko te, które mają `sent = True` i są już zaplanowane
    now = datetime.utcnow()
    cursor.execute("""
        SELECT * FROM notificationsigora
        WHERE scheduled_time <= %s AND sent = 1
        ORDER BY DATE(scheduled_time) asc, TIME(scheduled_time) desc
    """, (now,))
    notifications = cursor.fetchall()

    conn.close()
    return notifications

@router.post("/notifications", response_model=Notification)
def create_notification(notification: NotificationCreate):
    excerpt = generate_excerpt(notification.content)

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    sql = """
        INSERT INTO notificationsigora (title, content, excerpt, leadingImage, scheduled_time, sent)
        VALUES (%s, %s, %s, %s, %s, %s)
    """
    values = (
        notification.title,
        notification.content,
        excerpt,
        notification.leadingImage,
        notification.scheduled_time,
        False
    )
    cursor.execute(sql, values)
    conn.commit()

    inserted_id = cursor.lastrowid

    cursor.execute("SELECT * FROM notificationsigora WHERE id = %s", (inserted_id,))
    new_notification = cursor.fetchone()

    conn.close()
    if not new_notification:
        raise HTTPException(status_code=500, detail="Nie udało się dodać powiadomienia")

    return new_notification
