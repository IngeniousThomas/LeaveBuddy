import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme_provider.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: () => themeProvider.toggleTheme(),
          child: Container(
            width: 80,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: themeProvider.isDarkMode ? Colors.deepPurpleAccent : Colors.deepPurple,
              boxShadow: [
                BoxShadow(
                  color: themeProvider.isDarkMode 
                    ? Colors.deepPurpleAccent.withOpacity(0.3)
                    : Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Sun icon
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  left: themeProvider.isDarkMode ? -30 : 12,
                  top: 10,
                  child: Icon(
                    Icons.light_mode,
                    color: Colors.white.withOpacity(0.9),
                    size: 20,
                  ).animate(
                    onPlay: (controller) => controller.repeat(),
                  ).shimmer(
                    duration: 2.seconds,
                    color: Colors.yellow.withOpacity(0.9),
                  ),
                ),
                // Moon icon
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  left: themeProvider.isDarkMode ? 47 : -30,
                  top: 10,
                  child: Icon(
                    Icons.dark_mode,
                    color: Colors.white.withOpacity(0.9),
                    size: 20,
                  ).animate(
                    onPlay: (controller) => controller.repeat(),
                  ).shimmer(
                    duration: 2.seconds,
                    color: const Color.fromARGB(255, 0, 40, 171).withOpacity(0.9),
                  ),
                ),
                // Animated thumb
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  left: themeProvider.isDarkMode ? 5 : 45,
                  top: 5,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ).animate(
                    onPlay: (controller) => controller.repeat(),
                  ).shimmer(
                    duration: 2.seconds,
                    color: themeProvider.isDarkMode 
                      ? Colors.deepPurpleAccent.withOpacity(0.3)
                      : Colors.deepPurple.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}