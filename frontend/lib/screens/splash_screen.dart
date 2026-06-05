import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  /// Called when the animation finishes. The caller decides what to do next.
  final VoidCallback? onComplete;

  const SplashScreen({super.key, this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fillAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _fillAnimation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                ClipPath(
                  clipper: _FillClipper(_fillAnimation.value),
                  child: Image.asset(
                    'assets/images/loadingscreenfull.png',
                    width: 500,
                    height: 500,
                    fit: BoxFit.contain,
                  ),
                ),
                Image.asset(
                  'assets/images/loadingscreenskin.png',
                  width: 500,
                  height: 500,
                  fit: BoxFit.contain,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FillClipper extends CustomClipper<Path> {
  final double progress;
  _FillClipper(this.progress);

  @override
  Path getClip(Size size) {
    final revealHeight = size.height * progress;
    final top = size.height - revealHeight;
    return Path()..addRect(Rect.fromLTWH(0, top, size.width, revealHeight));
  }

  @override
  bool shouldReclip(_FillClipper old) => old.progress != progress;
}