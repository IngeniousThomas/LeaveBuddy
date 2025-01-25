import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.white.withOpacity(0.3),
              ),
              child: Text(
                'Made with ❤️ by Arun Thomas',
                style: TextStyle(
                  fontSize: 10,
                  color: themeProvider.isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}