import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';

// ─── 1. DEFINE THE MISSING ENUM (Fixes Home Screen Errors!) ──────────────────
enum DifficultyLevel { easy, medium, hard }

// ─── Embedded Flame Game for Axey's Animation Loop ──────────────────────────
class AxeyAnimationGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Loads directly from assets/images/axolotl.png
    final spriteSheet = await images.load('axolotl.png');

    final axeyAnimation = SpriteAnimationComponent(
      animation: SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 3,                  // The 3 frames from your canvas
          stepTime: 0.25,             // Adjust speed of the head shake/bob
          textureSize: Vector2(512, 512), // Size of 1 square on your CSP canvas
        ),
      ),
      // Scale Axey to look pristine and beautifully sized on the screen layout
      size: Vector2(200, 200),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2),
    );

    add(axeyAnimation);
  }

  @override
  Color backgroundColor() => Colors.transparent; // Let the underlying Flutter background shine through
}

// ─── Main Game Screen Layout ──────────────────────────────────────────────────
class GameScreen extends StatefulWidget {
  // ─── 2. ACCEPT THE LEVEL PARAMETER (Fixes Parameter Error!) ────────────────
  final DifficultyLevel? level;
  const GameScreen({super.key, this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Instantiate our embedded Flame game loop instance
  final AxeyAnimationGame _axeyGame = AxeyAnimationGame();
  
  // Track selection state for the test run feedback
  String? _selectedTopic;

  @override
  void initState() {
    super.initState();
    // ─── 3. COHESIVE FLOW CONNECTIVITY ───────────────────────────────────────
    // If they clicked a specific math difficulty card, auto-highlight Mathematics!
    if (widget.level != null) {
      _selectedTopic = "Mathematics";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic text calculation based on choices and selected difficulty level
    String welcomeMessage = "Hi there! I'm Axey, your underwater guide. What do you feel like learning today?";
    if (_selectedTopic == "Languages") {
      welcomeMessage = "Awesome choice! Let's get ready to explore Languages!";
    } else if (_selectedTopic == "Mathematics") {
      if (widget.level != null) {
        // Capitalizes the level name (e.g., 'easy' -> 'Easy')
        final String levelName = widget.level!.name;
        final String capsLevel = levelName[0].toUpperCase() + levelName.substring(1);
        welcomeMessage = "Awesome choice! Let's solve the $capsLevel Mathematics challenge!";
      } else {
        welcomeMessage = "Awesome choice! Let's get ready to explore Mathematics!";
      }
    }

    return Scaffold(
      backgroundColor: Colors.white, // Pure clean white canvas background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // 1. Simple Exit/Back Top Bar Row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
              const Spacer(),

              // 2. Axey's Welcoming Speech Bubble
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9), // Light pastel slate grey bubble
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.04 * 255).toInt()),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "✨ Meet Axey! ✨",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5961ED),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      welcomeMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Small triangle pointing downward to mimic a classic speech bubble pointer
              RotationTransition(
                turns: const AlwaysStoppedAnimation(45 / 360),
                child: Container(
                  width: 16,
                  height: 16,
                  color: const Color(0xFFF1F5F9),
                ),
              ),
              
              const SizedBox(height: 16),

              // 3. The Animated Axolotl Window (Flame Canvas Engine running inside Flutter)
              SizedBox(
                height: 220,
                width: 220,
                child: GameWidget(game: _axeyGame),
              ),

              const Spacer(),

              // 4. Learning Pathway Textboxes / Buttons
              _buildChoiceBox(
                title: "📚 Learning Languages",
                subtitle: "Discover words, signs, and expressions!",
                isSelected: _selectedTopic == "Languages",
                onTap: () {
                  setState(() => _selectedTopic = "Languages");
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildChoiceBox(
                title: "🧮 Mathematics",
                subtitle: "Play with numbers, patterns, and logic mysteries!",
                isSelected: _selectedTopic == "Mathematics",
                onTap: () {
                  setState(() => _selectedTopic = "Mathematics");
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helper builder function to generate matching custom selection boxes
  Widget _buildChoiceBox({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF0FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF5961ED) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? const Color(0xFF5961ED).withAlpha((0.08 * 255).toInt())
                  : Colors.black.withAlpha((0.03 * 255).toInt()),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF5961ED) : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}