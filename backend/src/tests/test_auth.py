from fastapi.testclient import TestClient
from uuid import uuid4, UUID
from main import app
from auth.dependencies import get_current_user_id, get_current_firebase_uid
from database.postgres import get_postgres

client = TestClient(app)

# Run using: 
# 
# uv run pytest
# uv run pytest tests/test_auth.py
# uv run pytest src/tests/test_auth.py::[method_name]
# 



def test_get_current_user_id_no_matching_row():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        response = client.get("/users/me", headers={"Authorization": "Bearer fake-token"})
        assert response.status_code == 404