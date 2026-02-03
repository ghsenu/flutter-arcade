import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart'; // Temporarily disabled

enum StarType { normal, fake, bomb, zigzag, speedChange }

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

  // Sound players (temporarily disabled)
  // final AudioPlayer _catchPlayer = AudioPlayer();
  // final AudioPlayer _missPlayer = AudioPlayer();
  // final AudioPlayer _gameOverPlayer = AudioPlayer();

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
  StarType starType = StarType.normal;
  double starDirectionX = 0; // For zigzag movement
  bool starAboutToDisappear = false;
  Timer? starDisappearTimer;
  int trickyStarChance = 15; // 15% chance for tricky stars initially
  Timer? gameTimer;

  void _playCatchSound() {
    // _catchPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2000/2000-preview.mp3'));
  }

  void _playMissSound() {
    // _missPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2001/2001-preview.mp3'));
  }

  void _playGameOverSound() {
    // _gameOverPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2018/2018-preview.mp3'));
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
    // _catchPlayer.dispose();
    // _missPlayer.dispose();
    // _gameOverPlayer.dispose();
    gameTimer?.cancel();
    comboMessageTimer?.cancel();
    starDisappearTimer?.cancel();
    super.dispose();
  }

  void startGame(Size size) {
    setState(() {
      isPlaying = true;
      score = 0;
      lives = 3;
      _resetCombo();
      starAboutToDisappear = false;
      starDisappearTimer?.cancel();
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
    starAboutToDisappear = false;
    starDisappearTimer?.cancel();
    starDirectionX = 0;
    
    // Increase tricky star chance as score increases
    int currentTrickyChance = (trickyStarChance + (score ~/ 5)).clamp(0, 60);
    
    // Randomly assign star type
    if (_random.nextInt(100) < currentTrickyChance) {
      List<StarType> trickyTypes = [StarType.fake, StarType.bomb, StarType.zigzag, StarType.speedChange];
      starType = trickyTypes[_random.nextInt(trickyTypes.length)];
      
      // Set up fake star disappearing
      if (starType == StarType.fake) {
        double disappearTime = 1.0 + _random.nextDouble() * 2.0; // 1-3 seconds
        starDisappearTimer = Timer(Duration(milliseconds: (disappearTime * 1000).toInt()), () {
          setState(() {
            starAboutToDisappear = true;
          });
          Timer(const Duration(milliseconds: 200), () {
            if (starType == StarType.fake) {
              spawnStar(size); // Spawn new star after fake one disappears
            }
          });
        });
      }
      
      // Set up zigzag movement
      if (starType == StarType.zigzag) {
        starDirectionX = (_random.nextBool() ? 1 : -1) * (50 + _random.nextDouble() * 50);
      }
      
      // Random speed change for speed-change stars
      if (starType == StarType.speedChange) {
        starSpeed = starSpeed * (0.5 + _random.nextDouble()); // 0.5x to 1.5x speed
      }
    } else {
      starType = StarType.normal;
    }
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
        starSpeed += 40;
      });
      spawnStar(size);
    }

    // Miss (but fake stars don't count as misses if they disappear)
    if (starY > size.height) {
      if (starType != StarType.fake || !starAboutToDisappear) {
        _playMissSound();
        _resetCombo();
        setState(() => lives--);
        if (lives <= 0) {
          endGame();
        } else {
          spawnStar(size);
        }
      } else {
        // Fake star disappeared - spawn new one without penalty
        spawnStar(size);
      }
    }

    setState(() {});
  }

  Widget _buildStar() {
    switch (starType) {
      case StarType.bomb:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withValues(alpha: 0.8),
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: const Icon(Icons.star, size: 30, color: Colors.amber),
        );
      case StarType.fake:
        return Icon(
          Icons.star_outline,
          size: 40,
          color: Colors.grey.withValues(alpha: 0.7),
        );
      case StarType.zigzag:
        return const Icon(
          Icons.star,
          size: 40,
          color: Colors.cyan,
        );
      case StarType.speedChange:
        return Icon(
          Icons.star,
          size: 40,
          color: Colors.purple.shade300,
        );
      default:
        return const Icon(Icons.star, size: 40, color: Colors.amber);
    }
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
                    color: Colors.white.withValues(alpha: opacity),
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
                    if (score > 10)
                      Text(
                        '⚠️ Watch out for tricks!',
                        style: TextStyle(
                          color: Colors.orange.shade300,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (score > 10)
                      Text(
                        '⚠️ Watch out for tricks!',
                        style: TextStyle(
                          color: Colors.orange.shade300,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
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
                      color: Colors.amber.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.5),
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
              if (isPlaying && !starAboutToDisappear)
                Positioned(
                  left: starX,
                  top: starY,
                  child: _buildStar(),
                ),
              
              // Fading fake star
              if (isPlaying && starAboutToDisappear)
                Positioned(
                  left: starX,
                  top: starY,
                  child: AnimatedOpacity(
                    opacity: 0.3,
                    duration: const Duration(milliseconds: 200),
                    child: _buildStar(),
                  ),
                ),

              // Basket - Realistic Design
              if (isPlaying)
                Positioned(
                  left: basketX,
                  bottom: 20,
                  child: CustomPaint(
                    size: Size(basketWidth, basketHeight + 20),
                    painter: BasketPainter(),
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
    ) ;
  }
}

class BasketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Basket colors
    final darkBrown = Colors.brown.shade800;
    final lightBrown = Colors.brown.shade400;
    final mediumBrown = Colors.brown.shade600;

    // Draw basket shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final shadowPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 2),
        width: size.width * 0.9,
        height: 8,
      ));
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw main basket body (curved bottom)
    paint.color = darkBrown;
    final basketPath = Path();
    
    // Start from top-left
    basketPath.moveTo(10, size.height - 30);
    
    // Top edge
    basketPath.lineTo(size.width - 10, size.height - 30);
    
    // Right side curving down
    basketPath.quadraticBezierTo(
      size.width - 5, size.height - 15, // control point
      size.width - 15, size.height - 5 // end point
    );
    
    // Bottom curve
    basketPath.quadraticBezierTo(
      size.width / 2, size.height + 5, // control point (dip down)
      15, size.height - 5 // end point
    );
    
    // Left side curving up
    basketPath.quadraticBezierTo(
      5, size.height - 15, // control point
      10, size.height - 30 // back to start
    );
    
    basketPath.close();
    canvas.drawPath(basketPath, paint);

    // Draw basket rim (top edge)
    paint.color = lightBrown;
    final rimRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(8, size.height - 35, size.width - 16, 8),
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(4),
      bottomLeft: const Radius.circular(2),
      bottomRight: const Radius.circular(2),
    );
    canvas.drawRRect(rimRect, paint);

    // Draw woven pattern - vertical strips
    paint.color = mediumBrown;
    paint.strokeWidth = 3;
    paint.style = PaintingStyle.stroke;
    
    for (double x = 20; x < size.width - 10; x += 12) {
      canvas.drawLine(
        Offset(x, size.height - 30),
        Offset(x - 2, size.height - 8),
        paint,
      );
    }

    // Draw woven pattern - horizontal strips
    paint.color = lightBrown.withValues(alpha: 0.8);
    paint.strokeWidth = 2;
    
    for (double y = size.height - 25; y < size.height - 5; y += 6) {
      final path = Path();
      path.moveTo(15, y);
      path.quadraticBezierTo(
        size.width / 2, y + 1,
        size.width - 15, y
      );
      canvas.drawPath(path, paint);
    }

    // Add basket handles
    paint.color = darkBrown;
    paint.style = PaintingStyle.fill;
    paint.strokeWidth = 4;

    // Left handle
    final leftHandle = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(5, size.height - 20),
        width: 6,
        height: 12,
      ));
    canvas.drawPath(leftHandle, paint);

    // Right handle
    final rightHandle = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(size.width - 5, size.height - 20),
        width: 6,
        height: 12,
      ));
    canvas.drawPath(rightHandle, paint);

    // Add some texture dots for more realism
    paint.color = Colors.brown.shade900.withValues(alpha: 0.3);
    for (int i = 0; i < 20; i++) {
      final x = 15 + (i % 8) * 12.0;
      final y = size.height - 25 + (i ~/ 8) * 4.0;
      canvas.drawCircle(Offset(x, y), 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
