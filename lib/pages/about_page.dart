import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/navigation_drawer.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/icon/abouticon.png'),
              ),
              const SizedBox(height: 16),

              //"What is Leave Buddy?"
              const Text(
                'What is Leave Buddy?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // description of Leave Buddy
              const Text(
                'Leave Buddy helps you track and manage leaves. '
                'Web and iOS support coming soon :) ',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Contact Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
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
                        leading: const Icon(Icons.email, color: Colors.deepPurple),
                        title: const Text('Email'),
                        subtitle: const Text('arunthomas04042001@gmail.com'),
                        onTap: () =>
                            _launchURL('mailto:arunthomas04042001@gmail.com'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.telegram, color: Colors.deepPurple),
                        title: const Text('Telegram'),
                        subtitle: const Text('@requaza'),
                        onTap: () => _launchURL('https://t.me/requaza'),
                      ),
                      ListTile(
                        leading: const FaIcon(FontAwesomeIcons.linkedin, color: Colors.deepPurple),
                        title: const Text('LinkedIn'),
                        subtitle: const Text('linkedin.com/in/arunthomas-hyd'),
                        onTap: () => _launchURL(
                            'https://www.linkedin.com/in/arunthomas-hyd/'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Footer
              const Text(
                'Made with ❤️ by Arun Thomas',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Nissaram allae ellam ;)',
                style: TextStyle(fontSize: 12, color: Colors.deepPurple),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
