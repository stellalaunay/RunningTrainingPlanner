import firebase_admin
from firebase_admin import credentials
import os
import base64
import json

def init_firebase() -> None:
    if firebase_admin._apps:
        return
    encoded = os.getenv("FIREBASE_CREDENTIALS")
    cred_dict = json.loads(base64.b64decode(encoded))
    cred = credentials.Certificate(cred_dict)
    firebase_admin.initialize_app(cred)