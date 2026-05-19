import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/clickhouse_service.dart';

// ── Brand colours ─────────────────────────────────────────────────────────────
const _kPrimary  = Color(0xFF5961ED);
const _kBg       = Color(0xFFF4F4FF);
const _kSurface  = Colors.white;
const _kTextMuted = Color(0xFF64748B);

// ─── Difficulty enum ──────────────────────────────────────────────────────────
enum DifficultyLevel { easy, medium, hard }

// ─── Question model ───────────────────────────────────────────────────────────
class MathQuestion {
  final String id;
  final String questionText;
  final int correctAnswer;
  final List<int> choices;
  final String topic;

  MathQuestion({
    required this.id,
    required this.questionText,
    required this.correctAnswer,
    required this.choices,
    required this.topic,
  });
}

// ─── Question generator ───────────────────────────────────────────────────────
class QuestionGenerator {
  static final _rng = Random();

  static MathQuestion generate(DifficultyLevel level) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    switch (level) {
      case DifficultyLevel.easy:   return _generateEasy(id);
      case DifficultyLevel.medium: return _generateMedium(id);
      case DifficultyLevel.hard:   return _generateHard(id);
    }
  }

  static MathQuestion _generateEasy(String id) {
    final op = ['+', '-'][_rng.nextInt(2)];
    if (op == '+') {
      final a = _rng.nextInt(10) + 1;
      final b = _rng.nextInt(10) + 1;
      return MathQuestion(
        id: id, questionText: '$a + $b = ?',
        correctAnswer: a + b, choices: _makeChoices(a + b, 1, 20),
        topic: 'addition',
      );
    } else {
      final a = _rng.nextInt(10) + 5;
      final b = _rng.nextInt(a);
      return MathQuestion(
        id: id, questionText: '$a − $b = ?',
        correctAnswer: a - b, choices: _makeChoices(a - b, 0, 20),
        topic: 'subtraction',
      );
    }
  }

  static MathQuestion _generateMedium(String id) {
    final op = ['×', '÷'][_rng.nextInt(2)];
    if (op == '×') {
      final a = _rng.nextInt(9) + 2;
      final b = _rng.nextInt(9) + 2;
      return MathQuestion(
        id: id, questionText: '$a × $b = ?',
        correctAnswer: a * b, choices: _makeChoices(a * b, 2, 100),
        topic: 'multiplication',
      );
    } else {
      final b = _rng.nextInt(9) + 2;
      final answer = _rng.nextInt(9) + 2;
      return MathQuestion(
        id: id, questionText: '${b * answer} ÷ $b = ?',
        correctAnswer: answer, choices: _makeChoices(answer, 1, 20),
        topic: 'division',
      );
    }
  }

  static MathQuestion _generateHard(String id) {
    switch (_rng.nextInt(3)) {
      case 0:
        final a = _rng.nextInt(8) + 2;
        final b = _rng.nextInt(8) + 2;
        final c = _rng.nextInt(5) + 2;
        return MathQuestion(
          id: id, questionText: '($a + $b) × $c = ?',
          correctAnswer: (a + b) * c,
          choices: _makeChoices((a + b) * c, 5, 200),
          topic: 'mixed_operations',
        );
      case 1:
        final percents = [10, 20, 25, 50];
        final pct = percents[_rng.nextInt(percents.length)];
        final y = (_rng.nextInt(9) + 1) * 20;
        final answer = (pct * y) ~/ 100;
        return MathQuestion(
          id: id, questionText: '$pct% of $y = ?',
          correctAnswer: answer, choices: _makeChoices(answer, 2, 100),
          topic: 'percentages',
        );
      default:
        final denom = _rng.nextInt(6) + 2;
        final a = _rng.nextInt(denom - 1) + 1;
        final c = _rng.nextInt(denom - 1) + 1;
        return MathQuestion(
          id: id, questionText: '$a/$denom + $c/$denom = ?/$denom',
          correctAnswer: a + c,
          choices: _makeChoices(a + c, 1, denom * 2),
          topic: 'fractions',
        );
    }
  }

  static List<int> _makeChoices(int correct, int min, int max) {
    final choices = <int>{correct};
    while (choices.length < 4) {
      final wrong = correct + (_rng.nextInt(9) - 4);
      if (wrong != correct && wrong >= min && wrong <= max) choices.add(wrong);
    }
    return choices.toList()..shuffle(_rng);
  }
}

// ─── Game Screen ──────────────────────────────────────────────────────────────
class GameScreen extends StatefulWidget {
  final DifficultyLevel level;
  final String childId;

  const GameScreen({
    super.key,
    required this.level,
    this.childId = 'demo_child_001',
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  static const _totalQuestions   = 10;
  static const _timePerQuestion  = 20;

  late MathQuestion _current;
  int _questionIndex = 0;
  int _score        = 0;
  int _timeLeft     = _timePerQuestion;
  Timer?    _timer;
  DateTime? _questionServedAt;
  int?  _selectedChoice;
  bool  _answered     = false;
  bool  _sessionEnded = false;

  late AnimationController _shakeController;
  late Animation<double>   _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _loadNextQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  // ── ClickHouse events ──────────────────────────────────────────────────────
  void _logQuestionServed() {
    _questionServedAt = DateTime.now();
    ClickHouseService.logEvent('question_served', {
      'child_id':       widget.childId,
      'level':          widget.level.name,
      'question_id':    _current.id,
      'topic':          _current.topic,
      'question_index': _questionIndex,
    });
  }

  void _logAnswerSubmitted(bool isCorrect, int responseTimeMs) {
    ClickHouseService.logEvent('answer_submitted', {
      'child_id':        widget.childId,
      'level':           widget.level.name,
      'question_id':     _current.id,
      'topic':           _current.topic,
      'is_correct':      isCorrect,
      'response_time_ms': responseTimeMs,
      'time_left_s':     _timeLeft,
      'question_index':  _questionIndex,
    });
  }

  void _logSessionEnd() {
    ClickHouseService.logEvent('session_end', {
      'child_id':        widget.childId,
      'level':           widget.level.name,
      'score':           _score,
      'total_questions': _totalQuestions,
      'accuracy':        _score / _totalQuestions,
    });
  }

  // ── Game logic ─────────────────────────────────────────────────────────────
  void _loadNextQuestion() {
    setState(() {
      _current      = QuestionGenerator.generate(widget.level);
      _timeLeft     = _timePerQuestion;
      _selectedChoice = null;
      _answered     = false;
    });
    _logQuestionServed();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        _onTimeUp();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _onTimeUp() {
    final ms = _questionServedAt != null
        ? DateTime.now().difference(_questionServedAt!).inMilliseconds
        : _timePerQuestion * 1000;
    _logAnswerSubmitted(false, ms);
    setState(() => _answered = true);
    _shakeController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1200), _advance);
  }

  void _onChoiceTapped(int choice) {
    if (_answered) return;
    _timer?.cancel();
    final ms = _questionServedAt != null
        ? DateTime.now().difference(_questionServedAt!).inMilliseconds
        : 0;
    final correct = choice == _current.correctAnswer;
    if (correct) _score++;
    _logAnswerSubmitted(correct, ms);
    setState(() {
      _selectedChoice = choice;
      _answered       = true;
    });
    if (!correct) _shakeController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 900), _advance);
  }

  void _advance() {
    if (_questionIndex + 1 >= _totalQuestions) {
      _logSessionEnd();
      setState(() => _sessionEnded = true);
    } else {
      setState(() => _questionIndex++);
      _loadNextQuestion();
    }
  }

  // ── Colour helpers ─────────────────────────────────────────────────────────
  Color get _levelColor {
    switch (widget.level) {
      case DifficultyLevel.easy:   return const Color(0xFF4CAF50);
      case DifficultyLevel.medium: return const Color(0xFFFFC107);
      case DifficultyLevel.hard:   return const Color(0xFFF44336);
    }
  }

  String get _levelLabel {
    switch (widget.level) {
      case DifficultyLevel.easy:   return '🌱 Easy';
      case DifficultyLevel.medium: return '⚡ Medium';
      case DifficultyLevel.hard:   return '🔥 Hard';
    }
  }

  Color _choiceColor(int choice) {
    if (!_answered) return _kSurface;
    if (choice == _current.correctAnswer) return const Color(0xFFE8F5E9);
    if (choice == _selectedChoice)        return const Color(0xFFFFEBEE);
    return _kSurface.withValues(alpha: 0.6);
  }

  Color _choiceBorderColor(int choice) {
    if (!_answered) return _kPrimary.withValues(alpha: 0.2);
    if (choice == _current.correctAnswer) return const Color(0xFF4CAF50);
    if (choice == _selectedChoice)        return const Color(0xFFF44336);
    return Colors.grey.withValues(alpha: 0.2);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_sessionEnded) return _buildResultScreen();
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 16),
            _buildTimerBar(),
            const SizedBox(height: 28),
            _buildQuestionCard(),
            const Spacer(),
            _buildChoicesGrid(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back_ios_rounded,
                  color: _kPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _levelColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _levelColor.withValues(alpha: 0.4)),
            ),
            child: Text(_levelLabel,
                style: TextStyle(
                    color: _levelColor, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$_score / $_totalQuestions',
                  style: const TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Text('score',
                  style: TextStyle(
                      color: _kTextMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    final progress  = _timeLeft / _timePerQuestion;
    final barColor  = _timeLeft > 10
        ? const Color(0xFF4CAF50)
        : _timeLeft > 5
            ? const Color(0xFFFFC107)
            : const Color(0xFFF44336);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${_questionIndex + 1} of $_totalQuestions',
                  style: TextStyle(color: _kTextMuted, fontSize: 13)),
              Row(
                children: [
                  Icon(Icons.timer_outlined, color: barColor, size: 16),
                  const SizedBox(width: 4),
                  Text('$_timeLeft s',
                      style: TextStyle(
                          color: barColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _kPrimary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(
            _shakeAnimation.value * sin(_shakeController.value * 3 * pi), 0),
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _kSurface,
          border: Border.all(
              color: _kPrimary.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: _kPrimary.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: 2),
          ],
        ),
        child: Column(
          children: [
            Text(
              _current.topic.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  color: _kPrimary.withValues(alpha: 0.7),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              _current.questionText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 42,
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoicesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        physics: const NeverScrollableScrollPhysics(),
        children: _current.choices.map((choice) {
          final isCorrect = _answered && choice == _current.correctAnswer;
          final isWrong   = _answered &&
              choice == _selectedChoice &&
              choice != _current.correctAnswer;

          return GestureDetector(
            onTap: () => _onChoiceTapped(choice),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _choiceColor(choice),
                border: Border.all(
                  color: _choiceBorderColor(choice),
                  width: isCorrect || isWrong ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCorrect) ...[
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF4CAF50), size: 18),
                    const SizedBox(width: 6),
                  ] else if (isWrong) ...[
                    const Icon(Icons.cancel_outlined,
                        color: Color(0xFFF44336), size: 18),
                    const SizedBox(width: 6),
                  ],
                  Text('$choice',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isCorrect
                              ? const Color(0xFF4CAF50)
                              : isWrong
                                  ? const Color(0xFFF44336)
                                  : const Color(0xFF1E293B))),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Result screen ──────────────────────────────────────────────────────────
  Widget _buildResultScreen() {
    final accuracy = (_score / _totalQuestions * 100).round();
    final emoji = accuracy >= 90
        ? '🏆'
        : accuracy >= 70
            ? '⭐'
            : accuracy >= 50
                ? '💪'
                : '🌱';
    final message = accuracy >= 90
        ? 'Math Champion!'
        : accuracy >= 70
            ? 'Great job!'
            : accuracy >= 50
                ? 'Keep practicing!'
                : 'You can do it!';

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 72)),
                const SizedBox(height: 16),
                Text(message,
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 32),
                // Score circle — purple themed
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _kPrimary, width: 3),
                    color: _kPrimary.withValues(alpha: 0.08),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$accuracy%',
                          style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: _kPrimary)),
                      Text('$_score / $_totalQuestions correct',
                          style: TextStyle(
                              color: _kTextMuted, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _questionIndex = 0;
                        _score        = 0;
                        _sessionEnded = false;
                      });
                      _loadNextQuestion();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Play Again',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimary,
                      side: BorderSide(
                          color: _kPrimary.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Change difficulty',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}