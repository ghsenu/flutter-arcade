import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Catch the Stars',
      theme: ThemeData(useMaterial3: true),
      home: const CatchStarsGame(),
    );
  }
}

class CatchStarsGame extends StatefulWidget {
  const CatchStarsGame({super.key});

  @override
  State<CatchStarsGame> createState() => _CatchStarsGameState();
}

class _CatchStarsGameState extends State<CatchStarsGame> {
  final _rng = Random();

  // Game state
  bool isPlaying = false;
  int score = 0;
  int timeLeft = 30;
  int lives = 3;

  // Basket
  final double basketWidth = 130;
  final double basketHeight = 30;
  double basketX = 0;

  // Star
  final double starSize = 40;
  double starX = 0;
  double starY = -40;
  double starSpeed = 260; // px/second

  Timer? _tick;
  Timer? _secondTimer;
  DateTime? _lastFrame;

  void startGame(Size area) {
    _tick?.cancel();
    _secondTimer?.cancel();

    setState(() {
      isPlaying = true;
      score = 0;
      timeLeft = 30;
      lives = 3;
      starSpeed = 260;
      basketX = (area.width - basketWidth) / 2;
    });

    spawnStar(area);

    _lastFrame = DateTime.now();
    _tick = Timer.periodic(const Duration(milliseconds: 16), (_) => update(area));

    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => timeLeft--);
      if (timeLeft <= 0) endGame();
    });
  }

  void endGame() {
    _tick?.cancel();
    _secondTimer?.cancel();
    setState(() => isPlaying = false);
  }

  void spawnStar(Size area) {
    final maxX = max(0.0, area.width - starSize);
    setState(() {
      starX = _rng.nextDouble() * maxX;
      starY = -starSize;
    });
  }

  void update(Size area) {
    if (!isPlaying) return;

    final now = DateTime.now();
    final dt = _lastFrame == null
        ? 0.016
        : (now.difference(_lastFrame!).inMilliseconds / 1000.0);
    _lastFrame = now;

    // Move star
    starY += starSpeed * dt;

    // Basket position clamp
    basketX = basketX.clamp(0.0, max(0.0, area.width - basketWidth));

    // Collision
    final basketY = area.height - basketHeight - 22;
    final basketRect = Rect.fromLTWH(basketX, basketY, basketWidth, basketHeight);
    final starRect = Rect.fromLTWH(starX, starY, starSize, starSize);

    // Catch
    if (starRect.overlaps(basketRect)) {
      setState(() {
        score += 1;
        // make it harder gradually
        starSpeed = min(700, starSpeed + 18);
      });
      spawnStar(area);
      return;
    }

    // Miss
    if (starY > area.height + starSize) {
      setState(() {
        lives -= 1;
      });
      if (lives <= 0) {
        endGame();
      } else {
        spawnStar(area);
      }
      return;
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tick?.cancel();
    _secondTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catch the Falling Stars'), centerTitle: true),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final area = Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              children: [
                Positioned.fill(
                  child: Container(color: Colors.grey.shade100),
                ),

                // HUD
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _pill('Score: $score'),
                      _pill('Time: $timeLeft'),
                      _pill('Lives: ${'❤️' * lives}'),
                    ],
                  ),
                ),

                // Star
                if (isPlaying)
                  Positioned(
                    left: starX,
                    top: starY,
                    child: Icon(Icons.star, size: starSize, color: Colors.amber),
                  ),

                // Drag control
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) {
                      if (!isPlaying) return;
                      setState(() => basketX += details.delta.dx);
                    },
                    child: const SizedBox.expand(),
                  ),
                ),

                // Basket
                if (isPlaying)
                  Positioned(
                    left: basketX,
                    bottom: 18,
                    child: Container(
                      width: basketWidth,
                      height: basketHeight,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                            color: Colors.black.withOpacity(0.15),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'BASKET',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                // Start / Game Over overlay
                if (!isPlaying)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.35),
                      child: Center(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  timeLeft == 30 ? 'Ready?' : 'Game Over!',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (timeLeft != 30)
                                  Text('Final score: $score',
                                      style: const TextStyle(fontSize: 16)),
                                const SizedBox(height: 14),
                                FilledButton(
                                  onPressed: () => startGame(area),
                                  child: Text(timeLeft == 30 ? 'Start' : 'Play Again'),
                                ),
                                const SizedBox(height: 8),
                                const Text('Drag anywhere to move the basket.'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 3),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
