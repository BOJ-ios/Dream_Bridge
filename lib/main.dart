import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'naviScreens/navi.dart';

import 'mainAnimation/shape.dart';
import 'mainAnimation/shapePainter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dream Bridge',
      home: Scaffold(
        body: const AnimatedBackground(),
      ),
    );
  }
}
 
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({Key? key});

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<AnimatedShape> shapes = [];
  final int numberOfShapes = 0;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    // Use a post-frame callback to wait for the build phase to complete
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      setState(() {
        shapes = List.generate(numberOfShapes, (index) {
          final size = random.nextDouble() * 50 + 20;
          final position = Offset(random.nextDouble() * screenWidth,
              random.nextDouble() * screenHeight);
          final targetPosition = Offset(random.nextDouble() * screenWidth,
              random.nextDouble() * screenHeight);
          final shapeType =
              ShapeType.values[random.nextInt(ShapeType.values.length)];
          return AnimatedShape(
              size: size,
              position: position,
              targetPosition: targetPosition,
              shapeType: shapeType);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background_1.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: <Widget>[
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: ShapePainter(shapes, _controller.value),
                child: Container(),
              );
            },
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 100.0, left: 30),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Dream Bridge',
                      style: TextStyle(
                        fontFamily: 'Roboto-Black',
                        fontSize: 50.0,
                        color: const Color(0xff846DA0),
                        height: 2,
                        letterSpacing: -1.0,// Adjust the lineHeight value
                      ),
                    ),
                    TextSpan(
                      text: '\nNext Step',
                      style: TextStyle(
                        fontFamily: 'Roboto-Bold',
                        fontSize: 30.0,
                        color: const Color(0xff846DA0),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
