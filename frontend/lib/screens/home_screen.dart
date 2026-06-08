import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'game_screen.dart'; 

// ─── Embedded Flame Game for Axey's Animation Loop ──────────────────────────
class AxeyAnimationGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    super.onLoad();

    final spriteSheet = await images.load('axolotl.png');

    final axeyAnimation = SpriteAnimationComponent(
      animation: SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 3,                  
          stepTime: 0.25,             
          textureSize: Vector2(512, 512), 
        ),
      ),
      size: Vector2(180, 180),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2),
    );

    add(axeyAnimation);
  }

  @override
  Color backgroundColor() => Colors.transparent;
}

// ─── Main Home Screen Hub ────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AxeyAnimationGame _axeyGame = AxeyAnimationGame();
  final TextEditingController _nameController = TextEditingController();
  
  // Flow State tracking
  // 0 = Asking Name, 1 = Greeting with Name, 2 = Topic Selection
  int _conversationStep = 0; 
  String _userName = "";
  String? _selectedTopic;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Dialogue Message Generation based on state
    String dialogueMessage = "";
    bool canTapBubbleToAdvance = false;

    if (_conversationStep == 0) {
      dialogueMessage = "Hello! I am Axey, your underwater guide. What is your name?";
      canTapBubbleToAdvance = false;
    } else if (_conversationStep == 1) {
      dialogueMessage = "Nice to meet you, $_userName! Click here to see what we can explore today.";
      canTapBubbleToAdvance = true;
    } else if (_conversationStep == 2) {
      canTapBubbleToAdvance = false;
      if (_selectedTopic == null) {
        dialogueMessage = "What do you feel like learning today? Choose an option below.";
      } else if (_selectedTopic == "Languages") {
        dialogueMessage = "Great choice! Let's get ready to explore Indian Sign Language expressions.";
      } else if (_selectedTopic == "Mathematics") {
        dialogueMessage = "Math adventure! Choose a challenge level below to start playing.";
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4FF), 
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  
                  // Top Title Bar
                  const Text(
                    'CGCLMA',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5961ED),
                      letterSpacing: 3,
                    ),
                  ),
                  
                  const Spacer(),

                  // Axey's Interactive Speech Bubble
                  GestureDetector(
                    onTap: () {
                      if (canTapBubbleToAdvance) {
                        setState(() {
                          _conversationStep = 2;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: canTapBubbleToAdvance ? const Color(0xFF5961ED) : Colors.transparent,
                          width: canTapBubbleToAdvance ? 2 : 0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Meet Axey",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF5961ED),
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dialogueMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E293B),
                              height: 1.4,
                            ),
                          ),
                          if (canTapBubbleToAdvance) ...[
                            const SizedBox(height: 8),
                            const Text(
                              "Click text bubble to continue",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5961ED),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Speech Bubble Pointer Triangle
                  RotationTransition(
                    turns: const AlwaysStoppedAnimation(45 / 360),
                    child: Container(
                      width: 14,
                      height: 14,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  // The Animated Flame Engine Window
                  SizedBox(
                    height: 180,
                    width: 180,
                    child: GameWidget(game: _axeyGame),
                  ),

                  const Spacer(),

                  // STEP 0 UI: Name input mode
                  if (_conversationStep == 0) ...[
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: "Enter your name here",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF5961ED), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5961ED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          if (_nameController.text.trim().isNotEmpty) {
                            setState(() {
                              _userName = _nameController.text.trim();
                              _conversationStep = 1;
                            });
                          }
                        },
                        child: const Text(
                          "Next",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],

                  // STEP 2 UI: Show menu choices once story moves forward
                  if (_conversationStep == 2) ...[
                    _buildTopicBox(
                      title: "Learning Languages",
                      subtitle: "Discover words, signs, and expressions",
                      isSelected: _selectedTopic == "Languages",
                      onTap: () {
                        setState(() => _selectedTopic = "Languages");
                      },
                    ),
                    
                    const SizedBox(height: 14),
                    
                    _buildTopicBox(
                      title: "Mathematics",
                      subtitle: "Play with numbers, patterns, and logic mysteries",
                      isSelected: _selectedTopic == "Mathematics",
                      onTap: () {
                        setState(() => _selectedTopic = "Mathematics");
                      },
                    ),

                    AnimatedCrossFade(
                      firstChild: const SizedBox(height: 0),
                      secondChild: Padding(
                        padding: const EdgeInsets.top(16.0),
                        child: Row(
                          children: [
                            _buildDifficultyButton(context, 'Easy', const Color(0xFF4CAF50), DifficultyLevel.easy),
                            const SizedBox(width: 10),
                            _buildDifficultyButton(context, 'Medium', const Color(0xFFFFC107), DifficultyLevel.medium),
                            const SizedBox(width: 10),
                            _buildDifficultyButton(context, 'Hard', const Color(0xFFF44336), DifficultyLevel.hard),
                          ],
                        ),
                      ),
                      crossFadeState: _selectedTopic == "Mathematics" 
                          ? CrossFadeState.showSecond 
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicBox({
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
        padding: const EdgeInsets.all(16),
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
                  ? const Color(0xFF5961ED).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF5961ED) : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(BuildContext context, String label, Color color, DifficultyLevel level) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GameScreen(level: level)),
          );
        },
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}