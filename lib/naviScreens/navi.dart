import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
 
import 'home.dart';
import 'info.dart';
import 'mapScreen/mapScreen.dart';

class NaviScreen extends StatefulWidget {
  const NaviScreen({super.key});

  @override
  State<NaviScreen> createState() => _NaviScreenState();
}

class _NaviScreenState extends State<NaviScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  DateTime? currentBackPressTime;

  Future<bool> onWillPop() async {
    DateTime currentTime = DateTime.now();
    bool backButton = currentBackPressTime == null ||
        currentTime.difference(currentBackPressTime!) >
            const Duration(seconds: 2);

    if (backButton) {
      currentBackPressTime = currentTime;
      Fluttertoast.showToast(
        msg: "'뒤로' 버튼을 한번 더 누르시면 종료됩니다.",
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xff6E6E6E),
        fontSize: 20,
        toastLength: Toast.LENGTH_SHORT,
      );
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: onWillPop,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Add this line
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: const [
            HomeScreen(),
            MapScreen(),
            InformationScreen(),
          ],
        ),
      ),
      // BottomnavigationBar 수정
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15),
        child: GNav(
          backgroundColor: Colors.white,
          color: const Color(0xFF757575),
          activeColor: const Color(0xff9433AC),
          tabBackgroundColor: const Color(0xffE9D4F0).withOpacity(0.8),
          gap: 8,
          iconSize: 24,
          onTabChange: (index) {
            print(index);
            _pageController
                .jumpToPage(index);
            setState(() {
              _currentIndex = index;
            });
          },
          padding: EdgeInsets.all(15),
          tabs: const [
            // [디자인] Home button
            GButton(
              icon: Icons.home,
              text: 'Home',
              textStyle: TextStyle(
                fontFamily: 'Roboto-Medium',
                fontSize: 16.0,
                color: const Color(0xFF9433AC),
              ),
            ),
            // [디자인] Map button
            GButton(
              icon: Icons.map,
              text: 'Map',
              textStyle: TextStyle(
                fontFamily: 'Roboto-Medium',
                fontSize: 16.0,
                color: const Color(0xFF9433AC),
              ),
            ),
            // [디자인] Information button
            GButton(
              icon: Icons.favorite,
              text: 'Wonder',
              textStyle: TextStyle(
                fontFamily: 'Roboto-Medium',
                fontSize: 16.0,
                color: const Color(0xFF9433AC),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
