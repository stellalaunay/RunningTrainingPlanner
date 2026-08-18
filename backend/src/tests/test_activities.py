from fastapi.testclient import TestClient
from uuid import uuid4, UUID
from main import app
from auth.dependencies import get_current_user_id, get_current_firebase_uid
from database.postgres import get_postgres


client = TestClient(app)

# Run using:
#
# uv run pytest
# uv run pytest tests/test_activities.py
# uv run pytest src/tests/test_activities.py::[method_name]
#



# ------------- Create Activity ------------

def test_create_activity_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_user_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        real_user_id = create_user_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(real_user_id)

        response = client.post("/activities", json={
            "name": "Morning Run",
            "date": "2026-08-20",
            "type": "Run",
            "distance": 5.0,
            "distance_unit": "km",
        })

        assert response.status_code == 200
        body = response.json()
        assert body["name"] == "Morning Run"
        assert body["date"] == "2026-08-20"
        assert body["type"] == "Run"
        assert body["distance"] == 5.0
        assert body["distance_unit"] == "km"
        assert body["user_id"] == real_user_id


def test_create_activity_unauthorized():
    with TestClient(app) as client:
        response = client.post(
            "/activities",
            json={
                "name": "Morning Run",
                "date": "2026-08-20",
                "type": "Run",
            },
            headers={"Authorization": "Bearer invalid-token"},
        )
        assert response.status_code == 401


def test_create_activity_uses_default_distance_unit():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_user_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
            "default_distance_unit": "mi",
        })
        real_user_id = create_user_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(real_user_id)

        response = client.post("/activities", json={
            "name": "Morning Run",
            "date": "2026-08-20",
            "type": "Run",
            "distance": 3.1,
        })

        assert response.status_code == 200
        body = response.json()
        assert body["distance_unit"] == "mi"


# ------------- Get Activity ------------

def test_get_own_activity_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_user_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        user_id = create_user_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(user_id)
        create_activity_response = client.post("/activities", json={
            "name": "Morning Run",
            "date": "2026-08-20",
            "type": "Run",
        })
        activity_id = create_activity_response.json()["activity_id"]

        response = client.get(f"/activities/{activity_id}")

        assert response.status_code == 200
        body = response.json()
        assert body["activity_id"] == activity_id
        assert body["name"] == "Morning Run"
        assert body["user_id"] == user_id


def test_get_other_activity_public_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_owner_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        owner_id = create_owner_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(owner_id)
        create_activity_response = client.post("/activities", json={
            "name": "Morning Run",
            "date": "2026-08-20",
            "type": "Run",
            "is_public": True,
        })
        activity_id = create_activity_response.json()["activity_id"]

        other_firebase_uid = f"test-firebase-uid-{uuid4()}"
        app.dependency_overrides[get_current_firebase_uid] = lambda: other_firebase_uid
        create_other_response = client.post("/users", json={
            "first_name": "Adrien",
            "last_name": "Launay",
        })
        other_user_id = create_other_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(other_user_id)
        response = client.get(f"/activities/{activity_id}")

        assert response.status_code == 200
        body = response.json()
        assert body["activity_id"] == activity_id
        assert body["is_public"] == True


def test_get_activity_public_via_plan_success():
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

        create_activity_response = client.post("/activities", json={
            "plan_id": plan_id,
            "name": "Long Run",
            "date": "2026-08-20",
            "type": "Run",
            "is_public": False,
        })
        activity_id = create_activity_response.json()["activity_id"]

        other_firebase_uid = f"test-firebase-uid-{uuid4()}"
        app.dependency_overrides[get_current_firebase_uid] = lambda: other_firebase_uid
        create_other_response = client.post("/users", json={
            "first_name": "Adrien",
            "last_name": "Launay",
        })
        other_user_id = create_other_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(other_user_id)
        response = client.get(f"/activities/{activity_id}")

        assert response.status_code == 200
        body = response.json()
        assert body["activity_id"] == activity_id
        assert body["plan_id"] == plan_id
        assert body["is_public"] == False


def test_get_activity_not_found():
    with TestClient(app) as client:
        user_id = uuid4()
        app.dependency_overrides[get_current_user_id] = lambda: user_id

        activity_id = uuid4()
        response = client.get(f"/activities/{activity_id}")

        assert response.status_code == 404
        assert response.json()["detail"] == "Activity not found"


def test_get_other_activity_not_authorized():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_owner_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        owner_id = create_owner_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(owner_id)
        create_activity_response = client.post("/activities", json={
            "name": "Morning Run",
            "date": "2026-08-20",
            "type": "Run",
            "is_public": False,
        })
        activity_id = create_activity_response.json()["activity_id"]

        other_firebase_uid = f"test-firebase-uid-{uuid4()}"
        app.dependency_overrides[get_current_firebase_uid] = lambda: other_firebase_uid
        create_other_response = client.post("/users", json={
            "first_name": "Adrien",
            "last_name": "Launay",
        })
        other_user_id = create_other_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(other_user_id)
        response = client.get(f"/activities/{activity_id}")

        assert response.status_code == 403
        assert response.json()["detail"] == "Not authorized to view activity"


# ------------- Edit Activity ------------

def test_update_activity_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_user_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        user_id = create_user_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(user_id)
        create_activity_response = client.post("/activities", json={
            "name": "Morning Run",
            "date": "2026-08-20",
            "type": "Run",
            "distance": 5.0,
            "distance_unit": "km",
        })
        activity_id = create_activity_response.json()["activity_id"]

        response = client.put(
            f"/activities/{activity_id}",
            json={
                "name": "Evening Run",
                "distance": 8.0,
            },
        )

        assert response.status_code == 200
        body = response.json()
        assert body["activity_id"] == activity_id
        assert body["name"] == "Evening Run"
        assert body["distance"] == 8.0
        assert body["distance_unit"] == "km"


def test_update_activity_not_found():
    with TestClient(app) as client:
        user_id = uuid4()
        app.dependency_overrides[get_current_user_id] = lambda: user_id

        activity_id = uuid4()
        response = client.put(f"/activities/{activity_id}", json={"name": "Doesn't Exist"})

        assert response.status_code == 404
        assert response.json()["detail"] == "Activity not found"


def test_update_activity_not_authorized():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_owner_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        owner_id = create_owner_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(owner_id)
        create_activity_response = client.post("/activities", json={
            "name": "Morning Run",
            "date": "2026-08-20",
            "type": "Run",
        })
        activity_id = create_activity_response.json()["activity_id"]

        other_firebase_uid = f"test-firebase-uid-{uuid4()}"
        app.dependency_overrides[get_current_firebase_uid] = lambda: other_firebase_uid
        create_other_response = client.post("/users", json={
            "first_name": "Adrien",
            "last_name": "Launay",
        })
        other_user_id = create_other_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(other_user_id)
        response = client.put(f"/activities/{activity_id}", json={"name": "Hijacked Run"})

        assert response.status_code == 403
        assert response.json()["detail"] == "Not authorized to edit this activity"


# ------------- Delete Activity ------------

def test_delete_activity_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_user_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        user_id = create_user_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(user_id)
        create_activity_response = client.post("/activities", json={
            "name": "Morning Run",
            "date": "2026-08-20",
            "type": "Run",
        })
        activity_id = create_activity_response.json()["activity_id"]

        response = client.delete(f"/activities/{activity_id}")

        assert response.status_code == 200
        assert response.json()["message"] == "Activity deleted successfully"


def test_delete_activity_not_found():
    with TestClient(app) as client:
        user_id = uuid4()
        app.dependency_overrides[get_current_user_id] = lambda: user_id

        activity_id = uuid4()
        response = client.delete(f"/activities/{activity_id}")

        assert response.status_code == 404
        assert response.json()["detail"] == "Activity not found"


def test_delete_activity_not_authorized():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_owner_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        owner_id = create_owner_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(owner_id)
        create_activity_response = client.post("/activities", json={
            "name": "Morning Run",
            "date": "2026-08-20",
            "type": "Run",
        })
        activity_id = create_activity_response.json()["activity_id"]

        other_firebase_uid = f"test-firebase-uid-{uuid4()}"
        app.dependency_overrides[get_current_firebase_uid] = lambda: other_firebase_uid
        create_other_response = client.post("/users", json={
            "first_name": "Adrien",
            "last_name": "Launay",
        })
        other_user_id = create_other_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(other_user_id)
        response = client.delete(f"/activities/{activity_id}")

        assert response.status_code == 403
        assert response.json()["detail"] == "Not authorized to delete this activity"


# ------------- Filter Activities by Week ------------

def test_filter_activities_by_week_success():
    fake_firebase_uid = f"test-firebase-uid-{uuid4()}"
    app.dependency_overrides[get_current_firebase_uid] = lambda: fake_firebase_uid

    with TestClient(app) as client:
        create_user_response = client.post("/users", json={
            "first_name": "Stella",
            "last_name": "Launay",
        })
        user_id = create_user_response.json()["user_id"]

        app.dependency_overrides[get_current_user_id] = lambda: UUID(user_id)

        client.post("/activities", json={
            "name": "In Range Run",
            "date": "2026-08-19",
            "type": "Run",
        })
        client.post("/activities", json={
            "name": "Out Of Range Run",
            "date": "2026-08-31",
            "type": "Run",
        })

        response = client.get(
            "/activities/filter/week",
            params={"monday": "2026-08-17", "sunday": "2026-08-23"},
        )

        assert response.status_code == 200
        body = response.json()
        names = [activity["name"] for activity in body]
        assert "In Range Run" in names
        assert "Out Of Range Run" not in names
