import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ClickHouseService {
  static const String _baseUrl  = 'http://10.0.2.2:8000';
  static const String _endpoint = '/api/v1/telemetry';
  static const Duration _timeout = Duration(seconds: 5);

  static final List<Map<String, dynamic>> _buffer = [];
  static bool _isFlushing = false;

  static void logEvent(Map<String, dynamic> data) {
    final payload = {
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
        _buffer.add(event);
      }
    }

    _isFlushing = false;
  }

  static Future<void> retryBuffer() async => _flush();

  static int get bufferSize => _buffer.length;
}