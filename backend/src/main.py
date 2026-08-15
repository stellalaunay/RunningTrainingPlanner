from fastapi import FastAPI
from contextlib import asynccontextmanager
from database.postgres import init_postgres, close_postgres
from routes.product_routes import product_router
import uvicorn


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_postgres()
    yield
    await close_postgres()

app: FastAPI = FastAPI(lifespan = lifespan, title = "Async FastAPI PostgreSQL Inventory Manager")
app.include_router(product_router)

if __name__ == "__main__":
    uvicorn.run("main:app", host = "0.0.0.0", port = 8080, reload = True)


# add security management with CORS


# run using: uv run src/main.py


"""
Once the server is running, you can access the API documentation and test the endpoints directly in your browser:

Interactive API Docs (Swagger UI):
Visit http://127.0.0.1:8080/docs to access the automatically generated API documentation where you can test the endpoints.
Alternative Docs (ReDoc):
Visit http://127.0.0.1:8080/redoc for another style of API documentation.

"""




    




