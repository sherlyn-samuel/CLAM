import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'splash_screen.dart';

const _kPrimary   = Color(0xFF5961ED);
const _kBg        = Color(0xFFF4F4FF);
const _kSurface   = Colors.white;
const _kTextMuted = Color(0xFF64748B);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/CLAM-LOGIN.jpg',
                    height: 80,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.calculate_rounded,
                      size: 80,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CGCLMA',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose your challenge',
                    style: TextStyle(fontSize: 16, color: _kTextMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _DifficultyCard(
                    title: 'Easy',
                    subtitle: 'Addition & Subtraction',
                    description: 'Perfect for beginners.\nNumbers up to 20.',
                    icon: '🌱',
                    color: const Color(0xFF4CAF50),
                    onTap: () => _goToGame(context, DifficultyLevel.easy),
                  ),
                  const SizedBox(height: 16),
                  _DifficultyCard(
                    title: 'Medium',
                    subtitle: 'Multiplication & Division',
                    description: 'For growing math stars.\nNumbers up to 100.',
                    icon: '⚡',
                    color: const Color(0xFFFFC107),
                    onTap: () => _goToGame(context, DifficultyLevel.medium),
                  ),
                  const SizedBox(height: 16),
                  _DifficultyCard(
                    title: 'Hard',
                    subtitle: 'Mixed Operations & Fractions',
                    description: 'For math champions.\nComplex problems.',
                    icon: '🔥',
                    color: const Color(0xFFF44336),
                    onTap: () => _goToGame(context, DifficultyLevel.hard),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToGame(BuildContext context, DifficultyLevel level) {
    // Push splash; when it finishes it replaces itself with GameScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SplashScreen(
          onComplete: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => GameScreen(level: level),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String icon;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _kSurface,
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text(subtitle,
                            style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 13,
                          color: _kTextMuted,
                          height: 1.4)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: _kPrimary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}