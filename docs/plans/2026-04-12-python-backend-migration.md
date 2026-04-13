# Python Backend Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rewrite the current NestJS backend as a Python FastAPI backend while preserving the `/api/v1` contract, the demo flow, and the existing Web/Mobile clients.

**Architecture:** Keep the system as a modular monolith. Replace the backend in `packages/backend` in place, preserve the current route shapes and JSON payloads, and keep the Web Vite proxy pointing at port `3000` so the front end does not need to change during the rewrite. Use FastAPI, SQLAlchemy, Pydantic, Alembic, APScheduler, and a Python seed script so the implementation is easy to explain in a student competition setting.

**Tech Stack:** Python 3.11+, FastAPI, Uvicorn, SQLAlchemy 2.x, Pydantic v2, Alembic, PostgreSQL 16, pytest, httpx, APScheduler, PyJWT or python-jose, passlib/bcrypt, requests/httpx for external API calls.

---

## Execution Notes
- Keep the backend service boundary at `packages/backend`.
- Keep the API prefix at `/api/v1`.
- Keep the Web client and Flutter client unchanged unless a task explicitly calls for a contract change.
- Do not introduce microservices, message queues, or real-time infrastructure during this migration.
- Use small commits after each task.

---

### Task 1: Python backend scaffold and health check

**Files:**
- Create: `packages/backend/pyproject.toml`
- Create: `packages/backend/requirements.txt`
- Create: `packages/backend/requirements-dev.txt`
- Create: `packages/backend/pytest.ini`
- Create: `packages/backend/app/__init__.py`
- Create: `packages/backend/app/main.py`
- Create: `packages/backend/app/core/__init__.py`
- Create: `packages/backend/app/core/config.py`
- Create: `packages/backend/app/core/database.py`
- Create: `packages/backend/app/api/__init__.py`
- Create: `packages/backend/app/api/router.py`
- Create: `packages/backend/app/api/health.py`
- Create: `packages/backend/tests/test_health.py`
- Modify: `packages/backend/package.json`

**Step 1: Write the failing test**

Create a test that expects `GET /api/v1/health` to return `200` with a JSON body like `{"status": "ok"}`.

**Step 2: Run the test and verify it fails**

Run: `cd packages/backend && pytest tests/test_health.py -q`
Expected: fail because the FastAPI app does not exist yet.

**Step 3: Write the minimal implementation**

Implement the FastAPI app, include the `/api/v1` router prefix, and add a basic health endpoint.

**Step 4: Run the test and verify it passes**

Run: `cd packages/backend && pytest tests/test_health.py -q`
Expected: pass.

**Step 5: Commit**

Commit the scaffold and health endpoint before moving on.

---

### Task 2: Database foundation, models, and Alembic

**Files:**
- Create: `packages/backend/alembic.ini`
- Create: `packages/backend/alembic/env.py`
- Create: `packages/backend/alembic/script.py.mako`
- Create: `packages/backend/alembic/versions/.gitkeep`
- Create: `packages/backend/app/db/base.py`
- Create: `packages/backend/app/db/session.py`
- Create: `packages/backend/app/models/__init__.py`
- Create: `packages/backend/app/models/user.py`
- Create: `packages/backend/tests/test_db_schema.py`
- Modify: `packages/backend/app/core/config.py`
- Modify: `packages/backend/app/core/database.py`

**Step 1: Write the failing test**

Create a schema test that checks the `user` table can be created and queried through SQLAlchemy against the test database.

**Step 2: Run the test and verify it fails**

Run: `cd packages/backend && pytest tests/test_db_schema.py -q`
Expected: fail because the DB layer and model do not exist yet.

**Step 3: Write the minimal implementation**

Add SQLAlchemy session management, declare the `user` model, and wire Alembic to load the model metadata.

**Step 4: Run the test and verify it passes**

Run: `cd packages/backend && pytest tests/test_db_schema.py -q`
Expected: pass.

**Step 5: Commit**

Commit the DB foundation before adding business endpoints.

---

### Task 3: Auth, JWT, and demo user login

**Files:**
- Create: `packages/backend/app/core/security.py`
- Create: `packages/backend/app/schemas/auth.py`
- Create: `packages/backend/app/services/auth_service.py`
- Create: `packages/backend/app/api/routes/auth.py`
- Create: `packages/backend/tests/test_auth.py`
- Create: `packages/backend/alembic/versions/0001_user_auth.py`
- Modify: `packages/backend/app/api/router.py`
- Modify: `packages/backend/app/models/user.py`
- Modify: `packages/backend/package.json`

**Step 1: Write the failing test**

Add integration tests for:
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/profile`

The tests should confirm that a newly registered user can log in and receive a JWT.

**Step 2: Run the test and verify it fails**

Run: `cd packages/backend && pytest tests/test_auth.py -q`
Expected: fail because auth endpoints are not implemented yet.

**Step 3: Write the minimal implementation**

Implement password hashing, JWT creation/validation, registration, login, and profile lookup.

**Step 4: Run the test and verify it passes**

Run: `cd packages/backend && pytest tests/test_auth.py -q`
Expected: pass.

**Step 5: Commit**

Keep the response shape compatible with the current Web login page.

---

### Task 4: Family management and health profiles

**Files:**
- Create: `packages/backend/app/models/family.py`
- Create: `packages/backend/app/models/family_member.py`
- Create: `packages/backend/app/models/health_profile.py`
- Create: `packages/backend/app/services/family_service.py`
- Create: `packages/backend/app/api/routes/family.py`
- Create: `packages/backend/app/api/routes/members.py`
- Create: `packages/backend/app/schemas/family.py`
- Create: `packages/backend/tests/test_family.py`
- Create: `packages/backend/alembic/versions/0002_family_and_health.py`
- Create: `packages/backend/app/services/default_medicines.py`
- Modify: `packages/backend/app/api/router.py`

**Step 1: Write the failing test**

Add tests for:
- creating a family
- listing current user families
- joining by invite code
- adding a dependent member
- reading and updating health profile

The tests should assert that `relationship` is stored and returned.

**Step 2: Run the test and verify it fails**

Run: `cd packages/backend && pytest tests/test_family.py -q`
Expected: fail because family endpoints and models do not exist yet.

**Step 3: Write the minimal implementation**

Implement family CRUD, member creation, health profile update, and the default medicine seed-on-family-create behavior.

**Step 4: Run the test and verify it passes**

Run: `cd packages/backend && pytest tests/test_family.py -q`
Expected: pass.

**Step 5: Commit**

Keep the API responses aligned with the current Web `family` pages.

---

### Task 5: Medicine, inventory, OCR, and upload

**Files:**
- Create: `packages/backend/app/models/medicine.py`
- Create: `packages/backend/app/models/medicine_inventory.py`
- Create: `packages/backend/app/services/medicine_service.py`
- Create: `packages/backend/app/services/inventory_service.py`
- Create: `packages/backend/app/services/ocr_service.py`
- Create: `packages/backend/app/services/upload_service.py`
- Create: `packages/backend/app/api/routes/medicine.py`
- Create: `packages/backend/app/api/routes/upload.py`
- Create: `packages/backend/app/schemas/medicine.py`
- Create: `packages/backend/tests/test_medicine.py`
- Create: `packages/backend/alembic/versions/0003_medicine_and_inventory.py`
- Modify: `packages/backend/app/api/router.py`

**Step 1: Write the failing test**

Add tests for:
- `GET /api/v1/families/{family_id}/medicines`
- `POST /api/v1/families/{family_id}/medicines`
- `POST /api/v1/families/{family_id}/medicines/{id}/inventory`
- `GET /api/v1/families/{family_id}/medicines/expiring`
- `GET /api/v1/families/{family_id}/medicines/low-stock`
- `POST /api/v1/families/{family_id}/medicines/ocr`

**Step 2: Run the test and verify it fails**

Run: `cd packages/backend && pytest tests/test_medicine.py -q`
Expected: fail because medicine and OCR features are not implemented yet.

**Step 3: Write the minimal implementation**

Implement medicine CRUD, inventory creation and status calculation, OCR parsing, and file upload URL generation.

**Step 4: Run the test and verify it passes**

Run: `cd packages/backend && pytest tests/test_medicine.py -q`
Expected: pass.

**Step 5: Commit**

Keep the response fields compatible with the current Web and Mobile medicine pages.

---

### Task 6: Medication plans, check-in, scheduler, and in-app notifications

**Files:**
- Create: `packages/backend/app/models/medication_plan.py`
- Create: `packages/backend/app/models/medication_schedule.py`
- Create: `packages/backend/app/models/medication_log.py`
- Create: `packages/backend/app/models/notification_message.py`
- Create: `packages/backend/app/services/medication_service.py`
- Create: `packages/backend/app/services/scheduler_service.py`
- Create: `packages/backend/app/services/notification_service.py`
- Create: `packages/backend/app/api/routes/medication.py`
- Create: `packages/backend/app/api/routes/notifications.py`
- Create: `packages/backend/app/schemas/medication.py`
- Create: `packages/backend/tests/test_medication.py`
- Create: `packages/backend/tests/test_notifications.py`
- Create: `packages/backend/alembic/versions/0004_medication_and_notifications.py`
- Modify: `packages/backend/app/api/router.py`

**Step 1: Write the failing test**

Add tests for:
- creating a medication plan
- listing plans
- getting today’s schedule
- checking in / skipping a schedule
- calculating adherence
- creating and listing in-app notification messages

**Step 2: Run the test and verify it fails**

Run: `cd packages/backend && pytest tests/test_medication.py tests/test_notifications.py -q`
Expected: fail because medication and notification center are not implemented yet.

**Step 3: Write the minimal implementation**

Implement plan generation, schedule generation, check-in logic, adherence stats, and a simple in-app message center for reminders.

**Step 4: Run the test and verify it passes**

Run: `cd packages/backend && pytest tests/test_medication.py tests/test_notifications.py -q`
Expected: pass.

**Step 5: Commit**

Keep the reminder path internal to the app first; do not add SMS/email/push integration yet.

---

### Task 7: Medical records and AI assistant

**Files:**
- Create: `packages/backend/app/models/medical_record.py`
- Create: `packages/backend/app/models/ai_consultation.py`
- Create: `packages/backend/app/services/medical_record_service.py`
- Create: `packages/backend/app/services/medical_record_ocr_service.py`
- Create: `packages/backend/app/services/ai_service.py`
- Create: `packages/backend/app/api/routes/medical_records.py`
- Create: `packages/backend/app/api/routes/ai.py`
- Create: `packages/backend/app/schemas/medical_record.py`
- Create: `packages/backend/app/schemas/ai.py`
- Create: `packages/backend/tests/test_medical_record_ai.py`
- Create: `packages/backend/alembic/versions/0005_medical_records_and_ai.py`
- Modify: `packages/backend/app/api/router.py`

**Step 1: Write the failing test**

Add tests for:
- creating/listing/updating/deleting medical records
- OCR parsing for medical records
- AI chat endpoint
- AI image analysis endpoint
- AI consultation history endpoint

The AI tests can mock the external model call, but they must verify the response contract and saved consultation record.

**Step 2: Run the test and verify it fails**

Run: `cd packages/backend && pytest tests/test_medical_record_ai.py -q`
Expected: fail because the medical record and AI service are not implemented yet.

**Step 3: Write the minimal implementation**

Implement medical record CRUD, OCR parsing, consultation persistence, and structured AI responses.

**Step 4: Run the test and verify it passes**

Run: `cd packages/backend && pytest tests/test_medical_record_ai.py -q`
Expected: pass.

**Step 5: Commit**

Preserve the current AI prompts conceptually, but move toward structured JSON output so the front end can render cards instead of raw chat only.

---

### Task 8: Pharmacy, seed data, docs, and legacy cleanup

**Files:**
- Create: `packages/backend/app/services/pharmacy_service.py`
- Create: `packages/backend/app/api/routes/pharmacy.py`
- Create: `packages/backend/scripts/seed.py`
- Modify: `scripts/seed.sh`
- Modify: `packages/backend/package.json`
- Modify: `packages/backend/README.md` or `README.md`
- Modify: `docs/架构改进清单.md` if implementation details changed
- Delete: `packages/backend/src/**`
- Delete: `packages/backend/nest-cli.json`
- Delete: `packages/backend/tsconfig.json`

**Step 1: Write the failing test**

Add a smoke test for:
- nearby pharmacy lookup with a mocked external response
- the seed script producing a demo user, family, members, medicines, inventory, and plans

**Step 2: Run the test and verify it fails**

Run: `cd packages/backend && pytest tests/test_pharmacy.py -q`
Expected: fail because the pharmacy service is not implemented yet.

**Step 3: Write the minimal implementation**

Implement the pharmacy lookup wrapper, port the demo seed logic to Python, and update the docs/README with the new run flow.

**Step 4: Run the test and verify it passes**

Run:
- `cd packages/backend && pytest tests/test_pharmacy.py -q`
- `bash scripts/seed.sh`

Expected: pass, and the seed script should populate the demo account and family tree.

**Step 5: Commit**

Remove the legacy NestJS source tree only after the Python backend is fully passing the test suite and the demo flow works end to end.

---

## Review and Release Checklist
- `pytest` passes for all backend tests
- Web login works against the Python backend on port `3000`
- Demo seed creates a usable account and family data
- The `/api/v1` contract matches the current front-end expectations
- The app can be explained as a modular monolith in a competition demo

## Batch Execution Order
1. Tasks 1-2: scaffold, health check, DB foundation
2. Tasks 3-5: auth, family, medicine, upload
3. Tasks 6-8: medication, notifications, medical records, AI, pharmacy, seed, cleanup

## Final Positioning
For the competition, the story should be:
- Python backend is easier to understand and explain
- The system is still a modular monolith, so the logic is clear
- Demo data is reproducible
- AI/OCR output is structured
- Station message reminders and the elder-friendly mode are core product features
