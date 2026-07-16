import 'package:flutter/material.dart';
import 'package:netdrop/config/netdrop_theme_ext.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const effectiveDate = 'July 16, 2026';
  static const companyName = 'Qayham';
  static const contactEmail = 'privacy@qayham.com';

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.55,
          color: context.nd.textSecondary,
        );
    final headingStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Text(
            'NetDrop',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Developer: $companyName\nEffective date: $effectiveDate',
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          Text(
            '$companyName operates NetDrop for local, device-to-device file sharing on your '
            'Wi‑Fi network. We do not operate cloud accounts or central file servers for your transfers.',
            style: bodyStyle,
          ),
          _Section(
            title: 'Summary',
            style: headingStyle,
            body: bodyStyle,
            bullets: const [
              'No account required.',
              'We do not sell your personal data.',
              'No advertising or analytics SDKs.',
              'Files transfer directly between devices on your local network.',
            ],
          ),
          _Section(
            title: 'Information we use',
            style: headingStyle,
            body: bodyStyle,
            bullets: const [
              'Device name you choose, device model, and local IP address.',
              'A random on-device fingerprint to identify your device on the network.',
              'Files you select to send, and files you accept to receive.',
              'Transfer history, settings, and optional TLS certificates stored locally.',
            ],
          ),
          _Section(
            title: 'How we use it',
            style: headingStyle,
            body: bodyStyle,
            bullets: const [
              'Discover nearby NetDrop devices.',
              'Send and receive files after you approve a transfer.',
              'Show progress and history in the app.',
              'Save received files to your device storage.',
            ],
          ),
          _Section(
            title: 'Local network',
            style: headingStyle,
            body: bodyStyle,
            text:
                'NetDrop uses UDP multicast and direct HTTP/HTTPS between devices on your network. '
                'Transfer data is not sent to Qayham servers. Use NetDrop only on networks you trust.',
          ),
          _Section(
            title: 'Storage & retention',
            style: headingStyle,
            body: bodyStyle,
            bullets: const [
              'Settings and history stay on your device.',
              'Received files are saved to NetDrop folders on your device.',
              'You can clear history or reset the app from Settings.',
              'Uninstalling removes locally stored app data.',
            ],
          ),
          _Section(
            title: 'Permissions',
            style: headingStyle,
            body: bodyStyle,
            text:
                'NetDrop may request network, Wi‑Fi/multicast, and storage/media access so you can '
                'discover devices, pick files, and save received files. We only access content you select.',
          ),
          _Section(
            title: 'Third-party services',
            style: headingStyle,
            body: bodyStyle,
            text:
                'The app may download fonts from Google Fonts when online. That request goes to Google '
                'and is covered by Google’s privacy policy. Your files are not sent to Google Fonts. '
                'NetDrop does not use ad or analytics SDKs.',
          ),
          _Section(
            title: 'Your choices',
            style: headingStyle,
            body: bodyStyle,
            bullets: const [
              'Change your device name and settings anytime.',
              'Decline transfers you do not want.',
              'Clear history or reset the app from Settings.',
            ],
          ),
          _Section(
            title: 'Contact',
            style: headingStyle,
            body: bodyStyle,
            text: 'Questions about this policy? Email $companyName at $contactEmail.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.style,
    required this.body,
    this.text,
    this.bullets,
  });

  final String title;
  final TextStyle? style;
  final TextStyle? body;
  final String? text;
  final List<String>? bullets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: style),
          const SizedBox(height: 8),
          if (text != null) Text(text!, style: body),
          if (bullets != null)
            ...bullets!.map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: body),
                    Expanded(child: Text(item, style: body)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
