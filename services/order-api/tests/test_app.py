from collections.abc import Generator

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app import Base, app, get_db


@pytest.fixture()
def client() -> Generator[TestClient, None, None]:
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool
    )
    testing_session = sessionmaker(bind=engine, autoflush=False, autocommit=False)
    Base.metadata.create_all(bind=engine)

    def override_get_db() -> Generator[Session, None, None]:
        db = testing_session()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)
    app.dependency_overrides.clear()
    Base.metadata.drop_all(bind=engine)
    engine.dispose()


def test_liveness_endpoint(client: TestClient) -> None:
    response = client.get("/health/live")
    assert response.status_code == 200
    assert response.json() == {"status": "alive"}


def test_create_and_list_orders(client: TestClient) -> None:
    response = client.post("/api/orders", json={"item": "Keyboard", "quantity": 2, "unit_price": "199.90"})
    assert response.status_code == 201
    assert response.json()["item"] == "Keyboard"
    assert client.get("/api/orders").status_code == 200


def test_invalid_quantity_is_rejected(client: TestClient) -> None:
    response = client.post("/api/orders", json={"item": "Keyboard", "quantity": 0, "unit_price": "10"})
    assert response.status_code == 422
