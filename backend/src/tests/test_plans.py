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
# uv run pytest tests/test_plans.py
# uv run pytest src/tests/test_plans.py::[method_name]
# 



# ------------- Create Plan ------------

def test_create_plan_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_user_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        real_user_id = create_user_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(real_user_id)

        response = client.post("/plans", json={
            "name": "Marathon Training",
            "distance": 26.2,
            "race_date": "2026-11-01",
        })

        assert response.status_code == 200
        body = response.json()
        assert body["name"] == "Marathon Training"
        assert body["distance"] == 26.2
        assert body["race_date"] == "2026-11-01"
        assert body["user_id"] == real_user_id


def test_create_plan_unauthorized():
    with TestClient(app) as client:
        response = client.post(
            "/plans",
            json={
                "name": "Marathon Training",
                "distance": 26.2,
                "race_date": "2026-11-01",
            },
            headers={"Authorization": "Bearer invalid-token"},
        )
        assert response.status_code == 401


# ------------- Get Plan ------------

def test_get_other_plan_public_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid
    
    with TestClient(app) as client:
        create_owner_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        owner_id = create_owner_response.json()["user_id"]
    
        app.dependency_overrides[get_current_user_id] = lambda: UUID(owner_id)
        create_plan_response = client.post("/plans", json={
            "name": "Marathon Training",
            "distance": 26.2,
            "race_date": "2026-11-01",
            "is_public": True,
        })
        plan_id = create_plan_response.json()["plan_id"]


        other_firebase_uid = f"test-firebase-uid-{uuid4()}"
        app.dependency_overrides[get_current_firebase_uid] = lambda: other_firebase_uid
        create_other_response = client.post("/users", json={
            "first_name": "Adrien",
            "last_name": "Launay",
        })
        other_user_id = create_other_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(other_user_id)
        response = client.get(f"/plans/{plan_id}")

        assert response.status_code == 200
        body = response.json()
        assert body["name"] == "Marathon Training"
        assert body["distance"] == 26.2
        assert body["race_date"] == "2026-11-01"
        assert body["plan_id"] == plan_id
        assert body["is_public"] == True
        
    

def test_get_plan_not_found():
    with TestClient(app) as client:
    

        user_id = uuid4()
        
        app.dependency_overrides[get_current_user_id] = lambda: user_id
    
    
        plan_id = uuid4()
    
        response = client.get(f"/plans/{plan_id}")
    
        assert response.status_code == 404
        assert response.json()["detail"] == "Plan not found"

def test_get_my_plan_private_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid
        
    with TestClient(app) as client:
        create_user_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })

        user_id = create_user_response.json()["user_id"]
        
        app.dependency_overrides[get_current_user_id] = lambda: UUID(user_id)
        create_plan_response = client.post("/plans", json={
            "name": "Marathon Training",
            "distance": 26.2,
            "race_date": "2026-11-01",
            "is_public": False,
        })

        plan_id = create_plan_response.json()["plan_id"]

        response = client.get(f"/plans/{plan_id}")

        assert response.status_code == 200
        body = response.json()
        assert body["name"] == "Marathon Training"
        assert body["distance"] == 26.2
        assert body["race_date"] == "2026-11-01"
        assert body["plan_id"] == plan_id
        assert body["user_id"] == user_id


def test_get_other_plan_not_authorized():

    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid
    
    with TestClient(app) as client:
        create_owner_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        owner_id = create_owner_response.json()["user_id"]
    
        app.dependency_overrides[get_current_user_id] = lambda: UUID(owner_id)
        create_plan_response = client.post("/plans", json={
            "name": "Marathon Training",
            "distance": 26.2,
            "race_date": "2026-11-01",
            "is_public": False,
        })
        plan_id = create_plan_response.json()["plan_id"]


        other_firebase_uid = f"test-firebase-uid-{uuid4()}"
        app.dependency_overrides[get_current_firebase_uid] = lambda: other_firebase_uid
        create_other_response = client.post("/users", json={
            "first_name": "Adrien",
            "last_name": "Launay",
        })
        other_user_id = create_other_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(other_user_id)
        response = client.get(f"/plans/{plan_id}")

        assert response.status_code == 402
        assert response.json()["detail"] == "Not authorized to view plan"


# ------------- Edit Plan ------------

def test_update_plan_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_user_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        user_id = create_user_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(user_id)
        create_plan_response = client.post("/plans", json={
            "name": "Marathon Training",
            "distance": 26.2,
            "race_date": "2026-11-01",
        })
        plan_id = create_plan_response.json()["plan_id"]

        response = client.put(
            f"/plans/{plan_id}",
            json={
                "name": "Marathon Training v2",
                "goal_time_seconds": 10800,
            },
        )

        assert response.status_code == 200
        body = response.json()
        assert body["plan_id"] == plan_id
        assert body["name"] == "Marathon Training v2"
        assert body["distance"] == 26.2
        assert body["goal_time_seconds"] == 10800


def test_update_plan_not_found():
    with TestClient(app) as client:
        user_id = uuid4()
        app.dependency_overrides[get_current_user_id] = lambda: user_id

        plan_id = uuid4()
        response = client.put(f"/plans/{plan_id}", json={"name": "Doesn't Exist"})

        assert response.status_code == 404
        assert response.json()["detail"] == "Plan not found"


def test_update_plan_not_authorized():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_owner_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        owner_id = create_owner_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(owner_id)
        create_plan_response = client.post("/plans", json={
            "name": "Marathon Training",
            "distance": 26.2,
            "race_date": "2026-11-01",
        })
        plan_id = create_plan_response.json()["plan_id"]

        other_firebase_uid = f"test-firebase-uid-{uuid4()}"
        app.dependency_overrides[get_current_firebase_uid] = lambda: other_firebase_uid
        create_other_response = client.post("/users", json={
            "first_name": "Adrien",
            "last_name": "Launay",
        })
        other_user_id = create_other_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(other_user_id)
        response = client.put(f"/plans/{plan_id}", json={"name": "Hijacked Plan"})

        assert response.status_code == 403
        assert response.json()["detail"] == "Not authorized to edit this plan"


# ------------- Delete Plan ------------

def test_delete_plan_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_user_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        user_id = create_user_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(user_id)
        create_plan_response = client.post("/plans", json={
            "name": "Marathon Training",
            "distance": 26.2,
            "race_date": "2026-11-01",
        })
        plan_id = create_plan_response.json()["plan_id"]

        response = client.delete(f"/plans/{plan_id}")

        assert response.status_code == 200
        assert response.json()["message"] == "Plan deleted successfully"


def test_delete_plan_not_found():
    with TestClient(app) as client:
        plan_id = uuid4()
        response = client.delete(f"/plans/{plan_id}")

        assert response.status_code == 404
        assert response.json()["detail"] == "Plan not found for deletion"


# ------------- Get All My Plans ------------

def test_get_all_my_plans_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_user_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        user_id = create_user_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(user_id)
        client.post("/plans", json={
            "name": "Marathon Training",
            "distance": 26.2,
            "race_date": "2026-11-01",
            "is_public": True,
        })
        client.post("/plans", json={
            "name": "5k Training",
            "distance": 3.1,
            "race_date": "2026-09-15",
            "is_public": False,
        })

        response = client.get("/plans/me")

        assert response.status_code == 200
        body = response.json()
        names = [plan["name"] for plan in body]
        assert len(body) == 2
        assert "Marathon Training" in names
        assert "5k Training" in names


# ------------- Get All Plans By User ------------

def test_get_all_plans_by_user_id_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_user_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        user_id = create_user_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(user_id)
        client.post("/plans", json={
            "name": "Public Marathon Training",
            "distance": 26.2,
            "race_date": "2026-11-01",
            "is_public": True,
        })
        client.post("/plans", json={
            "name": "Private 5k Training",
            "distance": 3.1,
            "race_date": "2026-09-15",
            "is_public": False,
        })

        response = client.get(f"/plans/user/{user_id}")

        assert response.status_code == 200
        body = response.json()
        names = [plan["name"] for plan in body]
        assert len(body) == 1
        assert "Public Marathon Training" in names
        assert "Private 5k Training" not in names


# ------------- Get All Plans ------------

def test_get_all_plans_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_owner_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        owner_id = create_owner_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(owner_id)
        client.post("/plans", json={
            "name": "Public Marathon Training",
            "distance": 26.2,
            "race_date": "2026-11-01",
            "is_public": True,
        })

        other_firebase_uid = f"test-firebase-uid-{uuid4()}"
        app.dependency_overrides[get_current_firebase_uid] = lambda: other_firebase_uid
        create_other_response = client.post("/users", json={
            "first_name": "Adrien",
            "last_name": "Launay",
        })
        other_user_id = create_other_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(other_user_id)
        client.post("/plans", json={
            "name": "Private 5k Training",
            "distance": 3.1,
            "race_date": "2026-09-15",
            "is_public": False,
        })

        response = client.get("/plans/")

        assert response.status_code == 200
        body = response.json()
        names = [plan["name"] for plan in body]
        assert "Public Marathon Training" in names
        assert "Private 5k Training" not in names
