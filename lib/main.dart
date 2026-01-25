import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CatchStarsGame(),
    );
  }
}

class CatchStarsGame extends StatefulWidget {
  const CatchStarsGame({super.key});

  @override
  State<CatchStarsGame> createState() => _CatchStarsGameState();
}

class _CatchStarsGameState extends State<CatchStarsGame> {
  final Random _random = Random();

  bool isPlaying = false;
  int score = 0;
  int lives = 3;

  // Basket
  double basketX = 120;
  final double basketWidth = 120;
  final double basketHeight = 30;

  // Star
  double starX = 100;
  double starY = -40;
  double starSpeed = 100; // Start slow, increases over time

  Timer? gameTimer;

  void startGame(Size size) {
    setState(() {
      isPlaying = true;
      score = 0;
      lives = 3;
      basketX = (size.width - basketWidth) / 2;
      spawnStar(size);
    });

    gameTimer?.cancel();
    gameTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => updateGame(size),
    );
  }

  void endGame() {
    gameTimer?.cancel();
    setState(() => isPlaying = false);
  }

  void spawnStar(Size size) {
    starX = _random.nextDouble() * (size.width - 40);
    starY = -40;
  }

  void updateGame(Size size) {
    if (!isPlaying) return;

    starY += starSpeed * 0.016;

    // Keep basket inside screen
    basketX = basketX.clamp(0.0, size.width - basketWidth);

    double basketY = size.height - 60;

    // Collision
    if (starY + 40 >= basketY &&
        starX + 40 >= basketX &&
        starX <= basketX + basketWidth) {
      setState(() {
        score++;
        starSpeed += 20;
      });
      spawnStar(size);
    }

    // Miss
    if (starY > size.height) {
      setState(() => lives--);
      if (lives <= 0) {
        endGame();
      } else {
        spawnStar(size);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catch the Falling Stars')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;

          return Stack(
            children: [
              // Background
              Container(color: Colors.grey.shade200),

              // Score & lives
              Positioned(top: 10, left: 10, child: Text('Score: $score')),
              Positioned(top: 10, right: 10, child: Text('Lives: ❤️' * lives)),

              // Star
              if (isPlaying)
                Positioned(
                  left: starX,
                  top: starY,
                  child: const Icon(Icons.star, size: 40, color: Colors.amber),
                ),

              // Basket
              if (isPlaying)
                Positioned(
                  left: basketX,
                  bottom: 20,
                  child: Container(
                    width: basketWidth,
                    height: basketHeight,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'BASKET',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

              // Start / Game Over
              if (!isPlaying)
                Center(
                  child: ElevatedButton(
                    onPressed: () => startGame(size),
                    child: Text(score == 0 ? 'Start Game' : 'Play Again'),
                  ),
                ),

              // 👇 FULL SCREEN DRAG - Must be LAST to capture all touches
              if (isPlaying)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        basketX += details.delta.dx;
                      });
                    },
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
