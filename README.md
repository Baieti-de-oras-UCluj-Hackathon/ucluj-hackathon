# UmbraRo

Tactical intelligence Flutter client and FastAPI backend (ML stays on the server).

## How to run (local)

1. **Backend** — from `backend/` with Python 3.11+:
  - `python -m venv .venv` and activate
  - `pip install -r requirements.txt`
  - Copy `backend/.env.example` to `backend/.env` and set `JWT_SECRET`
  - Set `FIREBASE_PROJECT_ID` and optionally `FIREBASE_CREDENTIALS_PATH` if you use Firebase sign-in
  - Start Uvicorn from `backend/` with your `app.main:app` entry (see `backend/app/main.py`).
2. **Flutter** — from repo root:
  - `flutter pub get`
  - Default: **legacy** email/password to FastAPI; JWTs stored in secure storage.
  - **Firebase hybrid (dev):** run `flutterfire configure` and replace `lib/firebase_options.dart` with real project values.  
  Example:  
  `flutter run -d chrome --dart-define=USE_FIREBASE_AUTH=true --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://localhost:8000/api/v1`
  - **Stable local URL (recommended):** always open `http://127.0.0.1:8080` by pinning hostname/port:  
  `.\scripts\run_web_firebase.ps1` or `.\scripts\run_web_legacy.ps1`  
  (or use VS Code launch configs **UmbraRo Web … fixed :8080**).  
  Add `http://127.0.0.1:8080` to backend `CORS_ORIGINS` if the browser blocks API calls.
  - With no `USE_FIREBASE_AUTH` flag, the value is `false` (safe rollback default).
3. **Firestore rules** (when using cloud data): from repo root with Firebase CLI:
  `firebase deploy --only firestore:rules` (use the matching dev/staging/prod project)

## How to roll back (Firebase off)

- Build or run **without** `USE_FIREBASE_AUTH=true` (default `false`).
- The app keeps legacy `POST /auth/login` and `POST /auth/register` and the same API JWT flow; tokens use secure storage, with a one-time migration from older `shared_preferences` keys.
- The backend still exposes the legacy auth routes. Firestore can remain unused without deleting data.

## Verification (quick)

- `USE_FIREBASE_AUTH=false` — sign in, restart app, still logged in (`/auth/me` succeeds).
- `USE_FIREBASE_AUTH=true` (after `flutterfire configure` + matching backend `FIREBASE_`*) — sign in with Firebase, CatBoost still via FastAPI.
- `firebase deploy` rules for the correct project before relying on `users/{uid}` writes.