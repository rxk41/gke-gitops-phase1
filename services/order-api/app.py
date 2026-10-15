import os
import time
from contextlib import asynccontextmanager
from decimal import Decimal
from urllib.parse import quote_plus

from fastapi import Depends, FastAPI, HTTPException, status
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy import Integer, Numeric, String, create_engine, select, text
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, sessionmaker


def make_database_url() -> str:
    explicit = os.getenv("DATABASE_URL")
    if explicit:
        return explicit
    user = os.getenv("DB_USER", "store")
    password = os.getenv("DB_PASSWORD", "local-only-change-me")
    host = os.getenv("DB_HOST", "postgresql")
    port = os.getenv("DB_PORT", "5432")
    name = os.getenv("DB_NAME", "store")
    return f"postgresql+psycopg://{quote_plus(user)}:{quote_plus(password)}@{host}:{port}/{name}"


engine = create_engine(make_database_url(), pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


class Base(DeclarativeBase):
    pass


class OrderRow(Base):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    item: Mapped[str] = mapped_column(String(120), nullable=False)
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    unit_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    status: Mapped[str] = mapped_column(String(24), nullable=False, default="pending")


class OrderCreate(BaseModel):
    item: str = Field(min_length=1, max_length=120)
    quantity: int = Field(ge=1, le=10000)
    unit_price: Decimal = Field(ge=0, max_digits=10, decimal_places=2)


class OrderOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    item: str
    quantity: int
    unit_price: Decimal
    status: str


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@asynccontextmanager
async def lifespan(_):
    last_error = None
    for attempt in range(20):
        try:
            Base.metadata.create_all(bind=engine)
            break
        except Exception as exc:
            last_error = exc
            if attempt == 19:
                raise last_error
            time.sleep(2)
    yield


app = FastAPI(title="Store Order API", version="1.0.0", lifespan=lifespan)


@app.get("/health/live")
def live():
    return {"status": "alive"}


@app.get("/health/ready")
def ready(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ready"}
    except Exception as exc:
        raise HTTPException(status_code=503, detail="Database is not ready") from exc


@app.get("/api/orders", response_model=list[OrderOut])
def list_orders(db: Session = Depends(get_db)):
    return db.scalars(select(OrderRow).order_by(OrderRow.id.desc())).all()


@app.get("/api/orders/{order_id}", response_model=OrderOut)
def get_order(order_id: int, db: Session = Depends(get_db)):
    order = db.get(OrderRow, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    return order


@app.post("/api/orders", response_model=OrderOut, status_code=status.HTTP_201_CREATED)
def create_order(payload: OrderCreate, db: Session = Depends(get_db)):
    item = payload.item.strip()
    if not item:
        raise HTTPException(status_code=422, detail="Item cannot be blank")
    row = OrderRow(item=item, quantity=payload.quantity, unit_price=payload.unit_price, status="pending")
    db.add(row)
    db.commit()
    db.refresh(row)
    return row
