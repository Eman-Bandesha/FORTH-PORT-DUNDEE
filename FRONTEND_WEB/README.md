# Forth Ports Dundee — Web Admin

React + Vite admin console for inventory management. Uses the Django REST API in `BACKEND`.

## Quick start

1. Start the API (if not already running):

```powershell
cd "..\BACKEND"
.\.venv\Scripts\activate
python manage.py runserver 8000
```

2. Start the web admin:

```powershell
cd FRONTEND_WEB
npm install
npm run dev
```

Open **http://127.0.0.1:5173**

Vite proxies `/api` → `http://127.0.0.1:8000`.

If your API is on another port (e.g. `8010`), start Vite like this:

```powershell
$env:VITE_API_PROXY="http://127.0.0.1:8010"; npm run dev
```

Or run Django on 8000 to match the default:

```powershell
python manage.py runserver 8000
```

## Default login

| Field | Value |
|-------|--------|
| Email | `eman@gmail.com` |
| Password | `123456` |

## Features

- **Login** — JWT auth against `/api/v1/auth/login/`
- **Dashboard** — totals, low/out-of-stock, 7-day trend, recent stock-in, category donut, alert preview
- **Items** — search, category filter, add / edit / delete
- **Stock In** — list filters + record new stock-in (updates item quantity)
- **Stock History** — all movements
- **Low Stock Alerts** — low/out list with one-click restock

Reports / Users / Settings appear in the sidebar as placeholders.

## Build

```powershell
npm run build
npm run preview
```
