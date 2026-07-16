CREATE DATABASE IF NOT EXISTS clam_db;

CREATE TABLE IF NOT EXISTS clam_db.game_events (
    event_id         UUID     DEFAULT generateUUIDv4(),
    session_id       UUID,
    child_id         String,
    game_type        String,
    topic            String,
    question_id      String,
    level             UInt8,
    is_correct        UInt8,
    response_time_ms  Int32,
    time_left_s       Nullable(Int8),
    score             Nullable(Int16),
    accuracy          Nullable(Float32),
    question_index    Nullable(Int8),
    total_questions   Nullable(Int8),
    client_ts         String,
    created_at        DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(created_at)
ORDER BY (child_id, created_at);