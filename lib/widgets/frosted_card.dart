import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class FrostedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;

  const FrostedCard({
    Key? key,
    required this.child,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          margin: margin,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: themeProvider.isDarkMode
                        ? Colors.deepPurpleAccent.withOpacity(0.2)
                        : Colors.deepPurple.withOpacity(0.2),
                  ),
                ),
                child: this.child,
              ),
            ),
          ),
        );
      },
    );
  }
}