import 'package:flutter/material.dart';
import 'pages/about_page.dart';
import 'pages/calendar_page.dart';
import 'pages/leave_page.dart';
import 'dart:async';

void main() {
  runApp(const LeaveBuddyApp());
}

class LeaveBuddyApp extends StatelessWidget {
  const LeaveBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leave Buddy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      initialRoute: '/splash', // Start with the splash screen at app launch
      routes: {
        '/splash': (context) => const SplashScreen(), // Splash screen route
        '/calendar': (context) => const CalendarPage(),
        '/about': (context) => const AboutPage(),
        '/leave': (context) => const LeavePage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to LeavePage after 1 seconds
    Timer(const Duration(seconds: 1), () {
      Navigator.pushReplacementNamed(context, '/leave');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/splashbg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Logo and text centered
          Center(
            child: Image.asset(
              'assets/splashtext.png',
              width: MediaQuery.of(context).size.width * 0.7, // Scale based on screen width
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
