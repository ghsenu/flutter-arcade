import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

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

  // Sound players
  final AudioPlayer _catchPlayer = AudioPlayer();
  final AudioPlayer _missPlayer = AudioPlayer();
  final AudioPlayer _gameOverPlayer = AudioPlayer();

  // Background stars
  List<Offset> backgroundStars = [];

  bool isPlaying = false;
  int score = 0;
  int lives = 3;
  int combo = 0;
  int comboMultiplier = 1;
  String comboMessage = '';
  Timer? comboMessageTimer;

  // Basket
  double basketX = 120;
  final double basketWidth = 120;
  final double basketHeight = 30;

  // Star
  double starX = 100;
  double starY = -40;
  double starSpeed = 100; // Start slow, increases over time

  Timer? gameTimer;

  void _playCatchSound() {
    _catchPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2000/2000-preview.mp3'));
  }

  void _playMissSound() {
    _missPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2001/2001-preview.mp3'));
  }

  void _playGameOverSound() {
    _gameOverPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2018/2018-preview.mp3'));
  }

  void _updateCombo() {
    combo++;
    
    // Calculate multiplier based on combo
    if (combo >= 20) {
      comboMultiplier = 5;
    } else if (combo >= 15) {
      comboMultiplier = 4;
    } else if (combo >= 10) {
      comboMultiplier = 3;
    } else if (combo >= 5) {
      comboMultiplier = 2;
    } else {
      comboMultiplier = 1;
    }
    
    // Show combo message for special milestones
    if (combo == 5) {
      _showComboMessage('COMBO x2!');
    } else if (combo == 10) {
      _showComboMessage('GREAT COMBO x3!');
    } else if (combo == 15) {
      _showComboMessage('AMAZING COMBO x4!');
    } else if (combo == 20) {
      _showComboMessage('LEGENDARY COMBO x5!');
    } else if (combo % 10 == 0 && combo > 20) {
      _showComboMessage('UNSTOPPABLE x5!');
    }
  }
  
  void _resetCombo() {
    combo = 0;
    comboMultiplier = 1;
    comboMessage = '';
    comboMessageTimer?.cancel();
  }
  
  void _showComboMessage(String message) {
    setState(() {
      comboMessage = message;
    });
    
    comboMessageTimer?.cancel();
    comboMessageTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        comboMessage = '';
      });
    });
  }

  @override
  void dispose() {
    _catchPlayer.dispose();
    _missPlayer.dispose();
    _gameOverPlayer.dispose();
    gameTimer?.cancel();
    comboMessageTimer?.cancel();
    super.dispose();
  }

  void startGame(Size size) {
    setState(() {
      isPlaying = true;
      score = 0;
      lives = 3;
      _resetCombo();
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
    _playGameOverSound();
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
      _playCatchSound();
      _updateCombo();
      setState(() {
        score += comboMultiplier; // Apply combo multiplier to score
        starSpeed += 20;
      });
      spawnStar(size);
    }

    // Miss
    if (starY > size.height) {
      _playMissSound();
      _resetCombo();
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
      appBar: AppBar(
        title: const Text('Catch the Falling Stars'),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;

          return Stack(
            children: [
              // Night sky background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0D1B2A), // Dark blue
                      Color(0xFF1B263B), // Midnight blue
                      Color(0xFF415A77), // Lighter blue at horizon
                    ],
                  ),
                ),
              ),

              // Background twinkling stars
              ...List.generate(50, (index) {
                final x = (index * 37 + 13) % size.width.toInt();
                final y = (index * 53 + 7) % size.height.toInt();
                final starSize = (index % 3 + 1) * 1.0;
                final opacity = 0.3 + (index % 7) * 0.1;
                return Positioned(
                  left: x.toDouble(),
                  top: y.toDouble(),
                  child: Icon(
                    Icons.star,
                    size: starSize + 2,
                    color: Colors.white.withOpacity(opacity),
                  ),
                );
              }),

              // Score & lives
              Positioned(
                top: 10,
                left: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: $score',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (combo > 0)
                      Text(
                        'Combo: ${combo}x (${comboMultiplier}x points)',
                        style: TextStyle(
                          color: combo >= 10 ? Colors.amber : Colors.cyan,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Text(
                  'Lives: ❤️' * lives,
                  style: const TextStyle(fontSize: 18),
                ),
              ),

              // Combo message
              if (comboMessage.isNotEmpty)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 100),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Text(
                      comboMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

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
