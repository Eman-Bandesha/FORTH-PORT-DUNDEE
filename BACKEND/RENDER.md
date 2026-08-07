# Render deploy notes for Forth Ports Dundee API
#
# Free plan note: Render free Postgres was discontinued.
# Use a free Neon Postgres DB and paste its DATABASE_URL into Render.
#
# Service settings (Root Directory = BACKEND):
#   Build Command:  bash build.sh
#   Start Command:  gunicorn config.wsgi:application --bind 0.0.0.0:$PORT
#
# Required env vars are listed in .env.example (DJANGO_*, DATABASE_URL, etc.).
