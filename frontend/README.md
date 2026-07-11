# CLAM (CCGLMA)

Competitive Gaming for Children's Learning through Mathematical Application.

A Flutter frontend + FastAPI/ClickHouse/Redis backend for a gamified math
learning app, aimed eventually at supporting learner-interaction research
(misconception detection, knowledge tracing).

**Status: early stage.** This README describes what's actually implemented,
not the target research vision — see "Planned / not yet built" below for that.

## What's actually built

- **Flutter frontend** (`frontend/`): login, signup, splash, and home
  screens, plus a `game_screen.dart` that currently only handles topic
  selection (Languages vs. Mathematics, with an animated Axey-the-axolotl
  mascot via Flame). There is no quiz loop yet — no questions are shown,
  answered, or scored.
- **FastAPI backend** (`backend/app/main.py`): one working endpoint,
  `POST /api/v1/telemetry`, which logs a gameplay event to ClickHouse,
  updates a Redis counter of consecutive failures, and runs two simple
  rule-based anomaly checks (rapid guessing, cognitive-fatigue pattern).
- **ClickHouse schema** (`backend/schema.sql`): a single canonical table,
  `clam_db.game_events`. This replaces two earlier schemas that disagreed
  with each other (one existed only as a comment in
  `clickhouse_service.dart`, describing a different table name and column
  set than what `main.py` actually inserted into — and neither was ever
  created via a real migration). Run `schema.sql` once against your
  ClickHouse instance before starting the backend.
- **`ml/train_dkt.py`**: a basic LSTM-based Deep Knowledge Tracing starter
  script that reads per-student sequences from `clam_db.game_events` and
  trains a model to predict next-answer correctness per skill/topic. This
  has not been run against real data — there is no real gameplay data yet,
  since the quiz loop doesn't exist. Treat it as a pipeline skeleton to
  build on, not a validated model.

## What's planned but not yet built

- The actual quiz loop in `game_screen.dart` (questions, answer capture,
  scoring, timing)
- A structured question bank with skill/misconception tagging
- NLP-based misconception detection (would require real learner text/response
  data to be collected first)
- Any trained/validated DKT model (the script above is untested against
  real data)

## Local setup

1. `docker compose -f backend/docker-compose.yml up -d` — starts Redis and
   ClickHouse
2. Run `backend/schema.sql` against the ClickHouse instance
3. `cd backend && pip install -r requirements.txt && uvicorn app.main:app --reload`
4. `cd frontend && flutter pub get && flutter run`

Android emulator note: the Flutter app expects the backend at
`http://10.0.2.2:8000` (this maps to your machine's localhost from inside
the emulator). Update `_baseUrl` in `clickhouse_service.dart` for a physical
device or deployed backend.

## ML training

```
pip install torch clickhouse-connect --break-system-packages
python ml/train_dkt.py
```

Or, to test the pipeline without a live ClickHouse instance, export events
to a CSV with columns `child_id, topic, is_correct, response_time_ms,
created_at` and run `python ml/train_dkt.py --csv your_export.csv`.

