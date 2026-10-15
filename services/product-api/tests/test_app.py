from collections.abc import Generator

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app import Base, app, get_db


@pytest.fixture()
def client() -> Generator[TestClient, None, None]:
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
    Base.metadata.create_all(bind=engine)

    def override_get_db() -> Generator[Session, None, None]:
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    # Do not use TestClient as a context manager: that would run the production
    # lifespan and try to connect to the configured PostgreSQL database.
    yield TestClient(app)
    app.dependency_overrides.clear()
    Base.metadata.drop_all(bind=engine)
    engine.dispose()


def test_liveness_endpoint(client: TestClient) -> None:
    response = client.get("/health/live")
    assert response.status_code == 200
    assert response.json() == {"status": "alive"}


def test_create_and_list_products(client: TestClient) -> None:
    create_response = client.post("/api/products", json={"name": "Keyboard", "price": 2499})
    assert create_response.status_code == 201
    created = create_response.json()
    assert created["name"] == "Keyboard"
    assert created["price"] == 2499

    list_response = client.get("/api/products")
    assert list_response.status_code == 200
    assert len(list_response.json()) == 1
    assert list_response.json()[0]["name"] == "Keyboard"


def test_missing_product_returns_404(client: TestClient) -> None:
    response = client.get("/api/products/999")
    assert response.status_code == 404
    assert response.json()["detail"] == "Product not found"


def test_negative_price_is_rejected(client: TestClient) -> None:
    response = client.post("/api/products", json={"name": "Keyboard", "price": -1})
    assert response.status_code == 422


def test_blank_product_name_is_rejected(client: TestClient) -> None:
    response = client.post("/api/products", json={"name": "   ", "price": 1})
    assert response.status_code == 422
