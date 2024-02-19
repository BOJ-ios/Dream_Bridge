import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/home.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(top: 126, left: 29),
              child: Text('Welcome',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'Roboto-Black',
                  fontSize: 50.0,
                  color: const Color(0xff846DA0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
