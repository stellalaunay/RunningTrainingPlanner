import os
import dotenv
import asyncpg
from typing import Optional
from loguru import logger




dotenv.load_dotenv()

conn_pool: Optional[asyncpg.Pool] = None 


async def init_postgres() -> None:
    """
    Initialize the PostgreSQL connection pool
    This function is meant to be called at the startup of the FastAPI app to
    initialize a connection pool to PostgreSQL
    """
    global conn_pool
    try: 
        logger.info("Initializing PostgreSQL connection pool...")

        conn_pool = await asyncpg.create_pool(
            dsn = os.getenv("DATABASE_URL"), min_size = 1, max_size = 10, statement_cache_size=0
        )
        logger.info("PostgreSQL connection pool created successfully.")

    except Exception as e:
        logger.error(f"Error initializing PostgreSQL connection pool: {e}")
        raise


async def get_postgres() -> asyncpg.Pool:
    """
    Return the PostgreSQL connection pool.
    This function returns the connection pool object, from which individual
    connections can be acquired as needed for database operations. The caller
    is responsible for acquiring and releasing connections from the pool.
    Returns
    -------
    asyncpg.Pool
        The connection pool object to the PostgreSQL database.
    Raises
    ------
    ConnectionError
        Raised if the connection pool is not initialized.
    """
    global conn_pool
    if conn_pool is None:
        logger.error("Connection pool is not initialized.")
        raise ConnectionError("PostgreSQL connection pool is not initialized.")
    try:
        return conn_pool
    except Exception as e:
        logger.error(f"Failed to return PostgreSQL connection pool: {e}")
        raise


async def close_postgres() -> None:
    """
    Close the PostgreSQL connection pool.
    This function should be called during the shutdown of the FastAPI app
    to properly close all connections in the pool and release resources.
    """

    global conn_pool
    if conn_pool is not None:
        try:
            logger.info("Closing PostgreSQL connection pool...")
            await conn_pool.close()
            logger.info("PostgreSQL connection pool closed successfully.")
        except Exception as e:
            logger.error(f"Error closing PostgreSQL connection pool: {e}")
            raise
    else:
        logger.warning("PostgreSQL connection pool was not initialized.")