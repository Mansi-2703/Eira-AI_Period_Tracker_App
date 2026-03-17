# HerCycle backend setup

Backend development spins up a Django + DRF API that targets PostgreSQL for persistence only.

## Dependencies

Backend setup now demands PostgreSQL credentials because the Django backend refuses to run without them.

- Install the pinned Python packages before running any commands:

```bash
python -m pip install -r requirements.txt
```

- `psycopg2-binary` is required for the PostgreSQL driver; it is already listed in `requirements.txt`.

## PostgreSQL (local) setup

1. Install PostgreSQL on your machine (e.g., via `brew install postgresql`, the official installer, or your package manager).
2. Create a database and user for HerCycle (replace `YOUR_SECURE_PASSWORD` with your own strong password):

```sql
CREATE DATABASE hercycle;
CREATE USER hercycle_user WITH PASSWORD 'YOUR_SECURE_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE hercycle TO hercycle_user;
```

3. Configure the Django database settings via environment variables (all are required). Create a `.env` file in the backend directory or set these as system environment variables:

| Variable | Example Value |
|----------|-----------------------|
| `DJANGO_DB_ENGINE` | `django.db.backends.postgresql` |
| `DJANGO_DB_NAME` | `hercycle` |
| `DJANGO_DB_USER` | `hercycle_user` |
| `DJANGO_DB_PASSWORD` | Your secure password (never commit this) |
| `DJANGO_DB_HOST` | `localhost` |
| `DJANGO_DB_PORT` | `5432` |

**IMPORTANT:** Never hardcode credentials in code or commit them to version control. Use environment variables or a `.env` file (which is git-ignored).

On Windows (Command Prompt):

```powershell
set DJANGO_DB_ENGINE=django.db.backends.postgresql
set DJANGO_DB_NAME=hercycle
set DJANGO_DB_USER=hercycle_user
set DJANGO_DB_PASSWORD=your_secure_password_here
set DJANGO_DB_HOST=localhost
set DJANGO_DB_PORT=5432
```

On macOS/Linux (Bash):

```bash
export DJANGO_DB_ENGINE=django.db.backends.postgresql
export DJANGO_DB_NAME=hercycle
export DJANGO_DB_USER=hercycle_user
export DJANGO_DB_PASSWORD=your_secure_password_here
export DJANGO_DB_HOST=localhost
export DJANGO_DB_PORT=5432
```

Alternatively, create a `.env.local` file in the backend directory with the above values (this file is git-ignored):

```
DJANGO_DB_ENGINE=django.db.backends.postgresql
DJANGO_DB_NAME=hercycle
DJANGO_DB_USER=hercycle_user
DJANGO_DB_PASSWORD=your_secure_password_here
DJANGO_DB_HOST=localhost
DJANGO_DB_PORT=5432
```

4. Run migrations to materialize the schema in PostgreSQL:

```bash
python manage.py migrate
```

5. Start the dev server as usual:

```bash
python manage.py runserver
```
