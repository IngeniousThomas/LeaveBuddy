import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../widgets/theme_toggle.dart';


class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            drawerTheme: DrawerThemeData(
              elevation: 0,
              backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          child: Drawer(
            child: Column(
              children: [
                Container(
                  height: 200, // Standard DrawerHeader height
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/bg.png'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        themeProvider.isDarkMode
                            ? Colors.black.withOpacity(0.6)
                            : Colors.white.withOpacity(0.6),
                        BlendMode.overlay,
                      ),
                    ),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset(
                        'assets/text.png',
                        color: themeProvider.isDarkMode ? Colors.white : null,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.list_alt,
                          color: themeProvider.isDarkMode
                              ? Colors.deepPurpleAccent
                              : Colors.deepPurple,
                        ),
                        title: Text('Leaves'),
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/leave');
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.calendar_today,
                          color: themeProvider.isDarkMode
                              ? Colors.deepPurpleAccent
                              : Colors.deepPurple,
                        ),
                        title: Text('Calendar'),
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/calendar');
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.info,
                          color: themeProvider.isDarkMode
                              ? Colors.deepPurpleAccent
                              : Colors.deepPurple,
                        ),
                        title: Text('About'),
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/about');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const ThemeToggle(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'V 1.3.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
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