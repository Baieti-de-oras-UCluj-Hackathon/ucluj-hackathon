# UmbraRo (ucluj-hackathon)

Tactical intelligence Flutter client and FastAPI backend (ML stays on the server).

## How to run (local)

1. **Backend** - from `backend/` with Python 3.11+:
   - `python -m venv .venv` and activate
   - `pip install -r requirements.txt`
   - Copy `backend/.env.example` to `backend/.env` and set `JWT_SECRET`
   - Set `FIREBASE_PROJECT_ID` and optionally `FIREBASE_CREDENTIALS_PATH` if you use Firebase sign-in
   - Start Uvicorn from `backend/` with your `app.main:app` entry (see `backend/app/main.py`).

2. **Flutter** - from repo root:
   - `flutter pub get`
   - Default: **legacy** email/password to FastAPI; JWTs stored in secure storage.
   - **Firebase hybrid (dev):** run `flutterfire configure` and replace `lib/firebase_options.dart` with real project values.
   - **Stable local URL (recommended):** always open `http://127.0.0.1:8080` using:
     - `./scripts/run_web_firebase.ps1`
     - `./scripts/run_web_legacy.ps1`
   - Add `http://127.0.0.1:8080` to backend `CORS_ORIGINS` if the browser blocks API calls.

3. **Firestore rules** (cloud data):
   - `firebase deploy --only firestore:rules`

## How to roll back (Firebase off)

- Build or run without `USE_FIREBASE_AUTH=true` (default `false`).
- Legacy `POST /auth/login` and `POST /auth/register` remain available.

## Verification (quick)

- `USE_FIREBASE_AUTH=false` - sign in, restart app, still logged in (`/auth/me` succeeds).
- `USE_FIREBASE_AUTH=true` - sign in with Firebase, CatBoost logic still runs via FastAPI.
