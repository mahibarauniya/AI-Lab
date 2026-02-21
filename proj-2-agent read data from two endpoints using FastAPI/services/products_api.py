"""
Products API – FastAPI service for products.csv (port 8002)

Endpoints:
  GET /products               – list all products (supports ?category= filter)
  GET /products/{id}          – get a single product by ID
  GET /products/search        – search by ?name= query string
"""

import csv
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, HTTPException, Query

DATA_FILE = Path(__file__).parent.parent / "data" / "products.csv"

app = FastAPI(title="Products API", version="1.0.0")


def _load_products() -> list[dict]:
    """Read products.csv and return a list of dicts."""
    if not DATA_FILE.exists():
        raise FileNotFoundError(f"Data file not found: {DATA_FILE}")
    with open(DATA_FILE, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        return [row for row in reader]


@app.get("/products")
def list_products(category: Optional[str] = Query(None, description="Filter by category")):
    """Return all products, optionally filtered by category."""
    products = _load_products()
    if category:
        products = [p for p in products if p["category"].lower() == category.lower()]
    return {"count": len(products), "products": products}


@app.get("/products/search")
def search_products(name: str = Query(..., description="Partial name to search for")):
    """Return products whose name contains the search string (case-insensitive)."""
    products = _load_products()
    results = [p for p in products if name.lower() in p["name"].lower()]
    return {"count": len(results), "products": results}


@app.get("/products/{product_id}")
def get_product(product_id: int):
    """Return a single product by ID."""
    products = _load_products()
    for prod in products:
        if int(prod["id"]) == product_id:
            return prod
    raise HTTPException(status_code=404, detail=f"Product with id={product_id} not found")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("products_api:app", host="0.0.0.0", port=8002, reload=True)
