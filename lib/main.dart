import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/theme_provider.dart';
import 'pages/about_page.dart';
import 'pages/calendar_page.dart';
import 'pages/leave_page.dart';
import 'dart:async';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const LeaveBuddyApp(),
    ),
  );
}

class LeaveBuddyApp extends StatelessWidget {
  const LeaveBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Leave Buddy',
          theme: themeProvider.theme,
          initialRoute: kIsWeb ? '/leave' : '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/calendar': (context) => const CalendarPage(),
            '/about': (context) => const AboutPage(),
            '/leave': (context) => const LeavePage(),
          },
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 1), () {
      Navigator.pushReplacementNamed(context, '/leave');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/splashbg.png'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      themeProvider.isDarkMode
                          ? Colors.black.withOpacity(0.6)
                          : Colors.white.withOpacity(0.6),
                      BlendMode.overlay,
                    ),
                  ),
                ),
              ),
              Center(
                child: Image.asset(
                  'assets/splashtext.png',
                  width: MediaQuery.of(context).size.width * 0.7,
                  fit: BoxFit.contain,
                  color: themeProvider.isDarkMode ? Colors.white : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}