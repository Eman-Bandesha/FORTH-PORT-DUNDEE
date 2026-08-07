# Forth Ports Dundee — Stock API (Django REST Framework)

Base URL (local): `http://127.0.0.1:8000/api/v1`

## Quick start

```bash
cd BACKEND
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py seed_demo
python manage.py runserver
```

Replace catalogue from the Dundee store spreadsheet:

```bash
python manage.py import_dundee_store --fresh
```

Default file path: `../Dundee Store List 29.05.26.xls` (project root). Use `--file` to override, `--dry-run` to preview.

**Default login:** `eman@gmail.com` / `123456` (give this user role **Administrator** in the Users admin if managing staff)  
**Also available:** `johndoe` / `Password123!`

### Staff auth (no public signup)

- Accounts are created only in the web admin Users page (or Django admin).
- Temporary passwords are emailed via Brevo SMTP (console email in local DEBUG).
- Forgot-password uses hashed 6-digit codes (10 min expiry, 5 attempts, 60s resend cooldown).
- JWT: short-lived access tokens, refresh rotation + blacklist on password change / deactivate.

Copy `BACKEND/.env.example` to `BACKEND/.env` and set Brevo / Postgres values for deployment.

```bash
# Auth tests
python manage.py test accounts.tests.test_auth_security
```

---

## Postman authentication

1. `POST {{base}}/auth/login/` with JSON body `{"username":"johndoe","password":"Password123!"}`  
2. Copy `tokens.access` from the response.  
3. For protected routes, set header: `Authorization: Bearer <access_token>`

Optional collection variables: `base` = `http://127.0.0.1:8000/api/v1`, `access_token` = your JWT.

---

## Health (no auth)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health/` | API status |

---

## Auth (`/auth/`)

| Method | Path | Auth | Body / notes |
|--------|------|------|----------------|
| POST | `/auth/register/` | No | `username`, `email`, `password`, optional `first_name`, `last_name`, `role`, `department`, `phone` |
| POST | `/auth/login/` | No | `username` or `email`, `password` → `user`, `tokens` |
| POST | `/auth/token/refresh/` | No | `refresh` → new `access` |
| POST | `/auth/logout/` | Yes | Client discards tokens |
| GET | `/auth/me/` | Yes | Current user + profile |
| PATCH | `/auth/me/` | Yes | Update profile fields |
| POST | `/auth/password/forgot/` | No | `email` → OTP (demo OTP in response when DEBUG) |
| POST | `/auth/password/verify-otp/` | No | `email`, `otp` → `{valid: true}` |
| POST | `/auth/password/reset/` | No | `email`, `otp`, `new_password` |
| POST | `/auth/password/change/` | Yes | `current_password`, `new_password` |

---

## Dashboard

| Method | Path | Description |
|--------|------|-------------|
| GET | `/dashboard/stats/` | Totals, alerts, stock out today, recent stock-out, alert items |

---

## Items (`/items/`)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/items/` | List — query: `search`, `status` (comma: `in_stock,low_stock,out_of_stock`), `category`, `location`, `sort` (`name_asc`, `name_desc`, `qty_high_low`, `qty_low_high`), `page`, `page_size` |
| POST | `/items/` | Create item |
| GET | `/items/{code}/` | Detail |
| PUT/PATCH | `/items/{code}/` | Update |
| DELETE | `/items/{code}/` | Delete |
| GET | `/items/meta/categories/` | Distinct categories |
| GET | `/items/meta/locations/` | Distinct locations |
| GET | `/items/{code}/analytics/` | Stock history from movements |
| GET | `/items/{code}/last-stock-out/` | Label + movement for tablet “Last Out” |

**Item JSON fields:** `code`, `name`, `image`, `status` (read-only), `quantity`, `category`, `unit`, `reorder_level`, `location`, `description`, `last_updated`

---

## Movements (`/movements/`)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/movements/` | List — `search`, `type` (`stock_in` / `stock_out`), `location`, `from_date`, `to_date`, `sort` (`newest_first`, `oldest_first`, `qty_high_low`, `qty_low_high`) |
| POST | `/movements/` | Record stock in/out (updates item quantity) |
| GET | `/movements/{id}/` | Detail (UUID) |
| GET | `/movements/reasons/` | Stock-out reason list |
| GET | `/movements/next-reference/` | Next `WO#####` reference |
| GET | `/movements/summary/` | Month-to-date in/out/net + stock out today |
| GET | `/movements/recent-stock-out/?limit=5` | Recent stock-out rows |

**Create body example (stock out):**

```json
{
  "type": "stock_out",
  "item_code": "PRN13DGTF",
  "quantity": 2,
  "requested_by": "John Doe",
  "location": "Main Warehouse",
  "notes": "WO job",
  "reason": "Maintenance work order"
}
```

---

## Notifications

| Method | Path | Description |
|--------|------|-------------|
| GET | `/notifications/?sort=name_asc` | Low + out-of-stock items for reorder UI |

---

## Reports (`/reports/`)

| Method | Path | Query |
|--------|------|-------|
| GET | `/reports/stock-summary/` | optional `location` |
| GET | `/reports/low-stock/` | optional `location` |
| GET | `/reports/by-category/` | optional `location` |
| GET | `/reports/by-location/` | — |
| GET | `/reports/stock-in-out/` | optional `from_date`, `to_date` (YYYY-MM-DD) |
| GET | `/reports/issued-stock/` | optional `location` |
| POST | `/reports/export/` | `{ "report_type": "stock_summary" }` (stub) |

---

## Android emulator

Use `http://10.0.2.2:8000/api/v1` as base URL from the Flutter app.

Import `postman/Forth_Ports_Stock_API.postman_collection.json` into Postman for ready-made requests.
