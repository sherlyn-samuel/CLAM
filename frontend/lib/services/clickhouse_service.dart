import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// ClickHouseService — fire-and-forget event logger for CGCLMA research data.
///
/// ── SETUP (do these once) ────────────────────────────────────────────────────
///
/// 1. ADD http TO pubspec.yaml:
///       dependencies:
///         http: ^1.2.1
///    Then run:  flutter pub get
///
/// 2. CLICKHOUSE TABLE (run once in your ClickHouse instance):
///
///    CREATE TABLE IF NOT EXISTS cgclma.game_events (
///      event_id         UUID          DEFAULT generateUUIDv4(),
///      event_type       String,
///      child_id         String,
///      level            String,
///      question_id      String,
///      topic            String,
///      is_correct       Nullable(UInt8),
///      response_time_ms Nullable(Int32),
///      time_left_s      Nullable(Int8),
///      score            Nullable(Int16),
///      accuracy         Nullable(Float32),
///      question_index   Nullable(Int8),
///      total_questions  Nullable(Int8),
///      client_ts        String,
///      created_at       DateTime DEFAULT now()
///    ) ENGINE = MergeTree()
///    PARTITION BY toYYYYMM(created_at)
///    ORDER BY (child_id, created_at);
///
/// 3. FASTAPI ENDPOINT (add to your FastAPI backend):
///
///    from clickhouse_driver import Client
///
///    ch = Client(host='localhost')
///
///    @app.post("/events/game")
///    async def ingest_game_event(payload: dict):
///        ch.execute(
///            "INSERT INTO cgclma.game_events "
///            "(event_type, child_id, level, question_id, topic, "
///            "is_correct, response_time_ms, time_left_s, score, "
///            "accuracy, question_index, total_questions, client_ts) VALUES",
///            [{
///                'event_type':       payload.get('event_type', ''),
///                'child_id':         payload.get('child_id', ''),
///                'level':            payload.get('level', ''),
///                'question_id':      payload.get('question_id', ''),
///                'topic':            payload.get('topic', ''),
///                'is_correct':       int(payload['is_correct']) if 'is_correct' in payload else None,
///                'response_time_ms': payload.get('response_time_ms'),
///                'time_left_s':      payload.get('time_left_s'),
///                'score':            payload.get('score'),
///                'accuracy':         payload.get('accuracy'),
///                'question_index':   payload.get('question_index'),
///                'total_questions':  payload.get('total_questions'),
///                'client_ts':        payload.get('client_ts', ''),
///            }]
///        )
///        return {"status": "ok"}
///
/// 4. ANDROID EMULATOR URL: use http://10.0.2.2:8000 (maps to your localhost)
///    PHYSICAL DEVICE: use your machine's local IP, e.g. http://192.168.1.x:8000
///    PRODUCTION: use your deployed API URL
///
/// 5. ML TRAINING QUERY — pull sequences per child for DKT:
///
///    SELECT
///        child_id,
///        groupArray(topic)            AS topic_sequence,
///        groupArray(is_correct)       AS correctness_sequence,
///        groupArray(response_time_ms) AS timing_sequence
///    FROM cgclma.game_events
///    WHERE event_type = 'answer_submitted'
///    GROUP BY child_id
///    ORDER BY child_id;
///
/// ─────────────────────────────────────────────────────────────────────────────

class ClickHouseService {
  // Change this to match your environment (see setup note 4 above)
  static const String _baseUrl  = 'http://10.0.2.2:8000';
  static const String _endpoint = '/events/game';
  static const Duration _timeout = Duration(seconds: 5);

  // Local buffer — events are retried if network fails
  static final List<Map<String, dynamic>> _buffer = [];
  static bool _isFlushing = false;

  /// Call this from game_screen.dart. Never throws — safe to fire and forget.
  /// game_screen.dart calls this without await, which is intentional.
  static void logEvent(
    String eventType,
    Map<String, dynamic> data,
  ) {
    final payload = {
      'event_type': eventType,
      ...data,
      'client_ts': DateTime.now().toUtc().toIso8601String(),
    };
    _buffer.add(payload);
    if (!_isFlushing) unawaited(_flush());
  }

  static Future<void> _flush() async {
    if (_buffer.isEmpty) return;
    _isFlushing = true;

    final toSend = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();

    for (final event in toSend) {
      try {
        await http
            .post(
              Uri.parse('$_baseUrl$_endpoint'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(event),
            )
            .timeout(_timeout);
      } catch (_) {
        // Network unavailable — keep in buffer, retry on next logEvent call
        _buffer.add(event);
      }
    }

    _isFlushing = false;
  }

  /// Call on app resume to retry buffered events (add to AppLifecycleListener)
  static Future<void> retryBuffer() async => _flush();

  /// Useful for debugging — how many events are waiting to be sent?
  static int get bufferSize => _buffer.length;
}