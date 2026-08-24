import firebase_admin
from firebase_admin import credentials

def init_firebase() -> None:
    if firebase_admin._apps:
        return
    cred = credentials.Certificate("secrets/firebase-service-account.json")
    firebase_admin.initialize_app(cred)