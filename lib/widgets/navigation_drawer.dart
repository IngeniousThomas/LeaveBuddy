import 'package:flutter/material.dart';

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg.png'), // Custom background image
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Image.asset(
                  'assets/text.png', // Custom text/icon logo
                ),
              ),
            ),
          ),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.list_alt),
                  title: const Text('Leaves'),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/leave');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Calendar'),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/calendar');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About'),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/about');
                  },
                ),
              ],
            ),
          ),

          // Version Info at the Bottom
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'V 1.1.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
