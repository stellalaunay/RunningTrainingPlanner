from fastapi.testclient import TestClient
from uuid import uuid4, UUID
from main import app
from auth.dependencies import get_current_user_id, get_current_firebase_uid
from database.postgres import get_postgres
from unittest.mock import patch


client = TestClient(app)

# Run using: 
# 
# uv run pytest
# uv run pytest tests/test_users.py
# uv run pytest src/tests/test_users.py::[method_name]
# 



# ------------- Create User ------------

def test_create_user_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        response = client.post(
            "/users",
            json={
                "first_name": "Stella",
                "last_name": "Launay",
            },
        )

        assert response.status_code == 201
        body = response.json()
        assert body["first_name"] == "Stella"
        assert body["last_name"] == "Launay"
        assert "user_id" in body

def test_create_user_unauthorized():
    with TestClient(app) as client:
        response = client.post(
            "/users",
            json={
                "first_name": "Stella",
                "last_name": "Launay",
            },
            headers={"Authorization": "Bearer invalid-token"},
        )
        assert response.status_code == 401



# ------------- Get My User ------------



def test_get_my_user_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        created_user_id = create_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(created_user_id)
        response = client.get("/users/me")

        assert response.status_code == 200
        body = response.json()
        assert body["user_id"] == created_user_id
        assert body["first_name"] == "Stella"
        assert body["last_name"] == "Launay"


def test_get_my_user_not_found():
    with TestClient(app) as client:
            fake_user_id = uuid4()
    
            app.dependency_overrides[get_current_user_id] = lambda: fake_user_id
            response = client.get("/users/me")
    
            assert response.status_code == 404
            assert response.json()["detail"] == "User not found"


def test_get_my_user_unauthorized():
    with TestClient(app) as client:
        response = client.get("/users/me", headers={"Authorization": "Bearer invalid-token"})
        assert response.status_code == 401


# ------------- Edit User ------------


def test_edit_my_profile_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        created_user_id = create_response.json()["user_id"]
          
        app.dependency_overrides[get_current_user_id] = lambda: UUID(created_user_id)
        response = client.put(
            "/users",
            json={
                "first_name": "Adrien",
                "default_distance_unit": "mi",
                "easy_pace": 330,
            },
        )


        assert response.status_code == 200
        body = response.json()
        assert body["user_id"] == created_user_id
        assert body["first_name"] == "Adrien"
        assert body["last_name"] == "Launay"
        assert body["default_distance_unit"] == "mi"
        assert body["easy_pace"] == 330


# ------------- Delete User ------------


def test_delete_my_profile_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid
    
    with TestClient(app) as client:
        create_response = client.post("/users", json={
            "first_name": "Xavier",
            "last_name": "Launay",
        })

        created_user_id = create_response.json()["user_id"]
                  
        app.dependency_overrides[get_current_user_id] = lambda: UUID(created_user_id)

        with patch("routes.user_routes.auth.delete_user") as mock_delete:
            response = client.delete("/users")


        assert response.status_code == 204
        mock_delete.assert_called_once_with(fake_firebase_uid)
        