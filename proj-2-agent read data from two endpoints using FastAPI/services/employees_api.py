"""
Employees API – FastAPI service for employees.csv (port 8001)

Endpoints:
  GET /employees              – list all employees (supports ?department= filter)
  GET /employees/{id}         – get a single employee by ID
  GET /employees/search       – search by ?name= query string
"""

import csv
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, HTTPException, Query

DATA_FILE = Path(__file__).parent.parent / "data" / "employees.csv"

app = FastAPI(title="Employees API", version="1.0.0")


def _load_employees() -> list[dict]:
    """Read employees.csv and return a list of dicts."""
    if not DATA_FILE.exists():
        raise FileNotFoundError(f"Data file not found: {DATA_FILE}")
    with open(DATA_FILE, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        return [row for row in reader]


@app.get("/employees")
def list_employees(department: Optional[str] = Query(None, description="Filter by department")):
    """Return all employees, optionally filtered by department."""
    employees = _load_employees()
    if department:
        employees = [e for e in employees if e["department"].lower() == department.lower()]
    return {"count": len(employees), "employees": employees}


@app.get("/employees/search")
def search_employees(name: str = Query(..., description="Partial name to search for")):
    """Return employees whose name contains the search string (case-insensitive)."""
    employees = _load_employees()
    results = [e for e in employees if name.lower() in e["name"].lower()]
    return {"count": len(results), "employees": results}


@app.get("/employees/{employee_id}")
def get_employee(employee_id: int):
    """Return a single employee by ID."""
    employees = _load_employees()
    for emp in employees:
        if int(emp["id"]) == employee_id:
            return emp
    raise HTTPException(status_code=404, detail=f"Employee with id={employee_id} not found")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("employees_api:app", host="0.0.0.0", port=8001, reload=True)
