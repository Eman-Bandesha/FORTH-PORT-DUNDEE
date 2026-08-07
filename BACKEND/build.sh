#!/usr/bin/env bash
# Render build command (Root Directory = BACKEND)
set -o errexit
pip install -r requirements.txt
python manage.py collectstatic --no-input
python manage.py migrate --no-input
python manage.py ensure_superuser
