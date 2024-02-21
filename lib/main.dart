import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'mainAnimation/animatedShape.dart';
import 'naviScreens/navi.dart';

import 'mainAnimation/shapePainter.dart';

// void main() => runApp(const MyApp());
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDefault();
  runApp(const MyApp());
}

Future<void> initializeDefault() async {
  FirebaseApp app = await Firebase.initializeApp();
  print('Initialized default app $app');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: AnimatedBackground(),
      ),
    );
  }
}

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<AnimatedShape> shapes;
  final int numberOfShapes = 30;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..addListener(() {
      setState(() {
        for (var shape in shapes) {
          shape.move();
          shape.checkBounds(MediaQuery.of(context).size);
        }
      });
    })..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    shapes = List.generate(numberOfShapes, (index) {
      final size = random.nextDouble() * 50 + 20;
      final position = Offset(random.nextDouble() * screenWidth, random.nextDouble() * screenHeight);
      final velocity = Offset(random.nextDouble() * 2 - 1, random.nextDouble() * 2 - 1); // Generate a random velocity for each shape
      final shapeType = ShapeType.values[random.nextInt(ShapeType.values.length)];
      return AnimatedShape(size: size, position: position, velocity: velocity, shapeType: shapeType);
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background_1.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: <Widget>[
          // CustomPaint(
          //   painter: ShapePainter(shapes),
          //   child: Container(),
          // ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 100.0, left: 30),
              child: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Dream Bridge',
                      style: TextStyle(
                        fontFamily: 'Roboto-Black',
                        fontSize: 50.0,
                        color: Color(0xff846DA0),
                        height: 2,
                        letterSpacing: -1.0,// Adjust the lineHeight value
                      ),
                    ),
                    TextSpan(
                      text: '\nNext Step',
                      style: TextStyle(
                        fontFamily: 'Roboto-Bold',
                        fontSize: 30.0,
                        color: Color(0xff846DA0),
                        height: 0.8, // Adjust the lineHeight value
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 200.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50.0),
                    // button blur 처리
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(170, 170, 204, 50),
                        spreadRadius: 1,
                        blurRadius: 20,
                        offset: Offset(10, 10),
                      ),
                      BoxShadow(
                        color: Color.fromRGBO(170, 170, 204, 25),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(5, 5),
                      ),
                      BoxShadow(
                        color: Color.fromRGBO(255, 255, 255, 50),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(-5, -5),
                      ),
                      BoxShadow(
                        color: Colors.white,
                        spreadRadius: 1,
                        blurRadius: 20,
                        offset: Offset(-10, -10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const NaviScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                    ),
                    child: const Text(
                      'Get started',
                      style: TextStyle(
                        fontFamily: 'Roboto-Bold',
                        fontSize: 32,
                        color: const Color(0xff846DA0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
