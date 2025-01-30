import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/navigation_drawer.dart';
import '../widgets/frosted_card.dart';
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppNavigationDrawer(),
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: Container(
        decoration: BoxDecoration(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 100,
                  backgroundImage: AssetImage('assets/icon/abouticon.png'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'What is Leave Buddy?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your Personal Leave Management Tool',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FrostedCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Contact',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: const Icon(Icons.cloud_circle_sharp, color: Colors.deepPurpleAccent),
                          title: const Text('Website'),
                          subtitle: const Text('leavebuddy.vercel.app'),
                          onTap: () => _launchURL('https://leavebuddy.vercel.app/'),
                        ),
                        ListTile(
                          leading: const FaIcon(FontAwesomeIcons.linkedin, color: Colors.deepPurpleAccent),
                          title: const Text('LinkedIn'),
                          subtitle: const Text('linkedin.com/in/arunthomas-hyd'),
                          onTap: () => _launchURL('https://www.linkedin.com/in/arunthomas-hyd/'),
                        ),
                        ListTile(
                          leading: const FaIcon(FontAwesomeIcons.github, color: Colors.deepPurpleAccent),
                          title: const Text('Github'),
                          subtitle: const Text('github.com/IngeniousThomas/LeaveBuddy - For Updates'),
                          onTap: () => _launchURL('https://github.com/IngeniousThomas/LeaveBuddy.git'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Made with ❤️ by Arun Thomas',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Nissaram allae ellam ;)',
                  style: TextStyle(fontSize: 12, color: Colors.deepPurpleAccent),
                  textAlign: TextAlign.center,
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}