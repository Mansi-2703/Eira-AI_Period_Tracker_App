import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/hercycle_palette.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? quizData;
  final String? cachedUsername;
  final String? cachedEmail;

  const ProfileScreen({
    super.key,
    this.quizData,
    this.cachedUsername,
    this.cachedEmail,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _username;
  String? _email;

  @override
  void initState() {
    super.initState();
    _username = widget.cachedUsername;
    _email = widget.cachedEmail;
    _loadCachedInfo();
  }

  Future<void> _loadCachedInfo() async {
    final info = await ApiService.loadUserInfo();
    if (!mounted) return;
    setState(() {
      _username = info['username'] ?? _username;
      _email = info['email'] ?? _email;
    });
  }

  bool get _alertsEnabled => widget.quizData?['wants_health_alerts'] == true;

  TextStyle _sectionTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w600,
          color: HerCyclePalette.deep,
        );
  }

  TextStyle _detailLabelStyle() {
    return const TextStyle(
      fontSize: 12,
      color: HerCyclePalette.deep,
      fontWeight: FontWeight.w500,
    );
  }

  TextStyle _detailValueStyle() {
    return TextStyle(
      fontSize: 16,
      color: HerCyclePalette.deep.withOpacity(0.85),
      fontWeight: FontWeight.w600,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: HerCyclePalette.deep.withOpacity(0.8),
        );

    return Scaffold(
      backgroundColor: HerCyclePalette.light,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: HerCyclePalette.deep,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Account', style: _sectionTitleStyle(context)),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.person,
              label: 'Username',
              value: _username ?? 'Not set yet',
            ),
            _buildDetailRow(
              icon: Icons.email,
              label: 'Email',
              value: _email ?? 'Not set yet',
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text('Settings', style: _sectionTitleStyle(context)),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.notifications,
              label: 'Health alerts',
              value: _alertsEnabled
                  ? 'Enabled via quiz preferences'
                  : 'Disabled - opt into alerts in the quiz',
              onTap: () => _showInfoDialog(
                'Health alerts',
                'Health alerts keep you in the loop about upcoming phases and reminders. You can edit this preference by retaking the menstrual health quiz.',
              ),
            ),
            _buildDetailRow(
              icon: Icons.sync_alt,
              label: 'Prediction refresh',
              value: 'We refresh predictions and cycle data every time you open the app.',
              onTap: () => _showInfoDialog(
                'Prediction refresh',
                'New cycle logs and quiz responses are pulled in on every visit so the calendar stays aligned with your latest inputs.',
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text('Privacy & policy', style: _sectionTitleStyle(context)),
            const SizedBox(height: 8),
            Text(
              'We collect only the cycle and quiz information you approve so predictions stay personal and private.',
              style: bodyStyle,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _showPrivacyPolicyDialog,
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                foregroundColor: HerCyclePalette.deep,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
                padding: EdgeInsets.zero,
              ),
              child: const Text('Read full privacy policy'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: HerCyclePalette.magenta,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to calendar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      horizontalTitleGap: 12,
      minLeadingWidth: 0,
      leading: Icon(icon, color: HerCyclePalette.magenta),
      title: Text(label, style: _detailLabelStyle()),
      subtitle: Text(value, style: _detailValueStyle()),
      onTap: onTap,
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Privacy policy overview'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Eira stores only the data you share explicitly: cycle logs, prediction requests, and quiz responses.',
                ),
                SizedBox(height: 8),
                Text(
                  'We keep this information on secure servers to continuously improve your personalized tracking experience.',
                ),
                SizedBox(height: 8),
                Text(
                  'We never sell your data. You can request removal of any stored details by contacting support through the app.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
