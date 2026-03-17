import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/hercycle_palette.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? quizData;

  const ProfileScreen({
    super.key,
    this.quizData,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _loadingProfile = true;
  bool _savingProfile = false;
  bool _editingAccount = false;
  bool _weeklyInsights = true;
  bool _cycleReminders = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    await ApiService.getUserProfile();
    if (!mounted) return;
    setState(() {
      _loadingProfile = false;
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await ApiService.loadPreferences();
    if (!mounted) return;
    setState(() {
      _weeklyInsights = prefs['weeklyInsights'] ?? _weeklyInsights;
      _cycleReminders = prefs['cycleReminders'] ?? _cycleReminders;
    });
  }

  void _toggleAccountEditing(bool enable) {
    if (!enable) {
      _formKey.currentState?.reset();
    }
    setState(() {
      _editingAccount = enable;
      if (enable) {
        _usernameController.clear();
        _emailController.clear();
      }
      _passwordController.clear();
      _confirmPasswordController.clear();
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

  String? _validateUsername(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'Please enter a username';
    }
    if (trimmed.length < 3) {
      return 'Username needs at least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'Please enter an email';
    }
    final emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailPattern.hasMatch(trimmed)) {
      return 'Enter a valid email';
    }
    return null;
  }

  Future<void> _submitProfile() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _savingProfile = true;
    });

    final usernameExists = await ApiService.usernameExists(username);
    if (!mounted) return;
    if (!usernameExists) {
      setState(() {
        _savingProfile = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username not found in the system')),
      );
      return;
    }

    final response = await ApiService.updateUserProfile(
      username: username,
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() {
      _savingProfile = false;
    });

    if (response.statusCode == 200) {
      await ApiService.cacheUserInfo(
        username: username.isNotEmpty ? username : null,
        email: email.isNotEmpty ? email : null,
      );
      _toggleAccountEditing(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account saved successfully')),
      );
    } else {
      final errorMessage = _extractErrorMessage(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _handleWeeklyInsightsChange(bool value) {
    setState(() {
      _weeklyInsights = value;
    });
    ApiService.cachePreferences(weeklyInsights: value);
  }

  void _handleCycleRemindersChange(bool value) {
    setState(() {
      _cycleReminders = value;
    });
    ApiService.cachePreferences(cycleReminders: value);
  }

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded.isNotEmpty) {
        final firstValue = decoded.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        if (firstValue is String) {
          return firstValue;
        }
      }
    } catch (_) {
      // fall through to default
    }
    return 'Unable to save changes right now. Please try again later.';
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
            _buildAccountSection(context),
            const SizedBox(height: 24),
            Text('Experience preferences', style: _sectionTitleStyle(context)),
            const SizedBox(height: 8),
            _buildPreferencesCard(context),
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
              value:
                  'We refresh predictions and cycle data every time you open the app.',
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
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _handleLogout,
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'You\'ll need to log in again to access your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      // Clear stored credentials
      await ApiService.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  Widget _buildAccountSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_loadingProfile)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: HerCyclePalette.deep,
                    color: HerCyclePalette.magenta,
                  ),
                ),
              if (!_editingAccount) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    alignment: Alignment.center,
                    backgroundColor: HerCyclePalette.deep,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _toggleAccountEditing(true),
                  child: const Text('Reset your password or email'),
                ),
              ] else ...[
                _buildTextField(
                  label: 'Username',
                  hint: 'e.g. aradia@hercycle',
                  controller: _usernameController,
                  validator: _validateUsername,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: 'Email',
                  hint: 'name@youremail.com',
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: HerCyclePalette.deep),
                  decoration: InputDecoration(
                    labelText: 'New password',
                    hintText: 'At least 8 characters',
                    labelStyle: const TextStyle(color: HerCyclePalette.deep),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    final pwd = value ?? '';
                    if (pwd.isEmpty) return 'Please enter a password';
                    if (pwd.length < 8) {
                      return 'Password needs at least 8 characters';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: HerCyclePalette.deep),
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    labelStyle: const TextStyle(color: HerCyclePalette.deep),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    final confirm = value ?? '';
                    if (confirm.isEmpty) return 'Please confirm your password';
                    if (confirm != _passwordController.text) {
                      return 'Passwords must match';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _savingProfile ? null : _submitProfile,
                        style: ElevatedButton.styleFrom(
                          alignment: Alignment.center,
                          backgroundColor: HerCyclePalette.deep,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _savingProfile
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save account changes'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _savingProfile ? null : () => _toggleAccountEditing(false),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: HerCyclePalette.deep),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required TextInputType keyboardType,
    required TextInputAction textInputAction,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: const TextStyle(color: HerCyclePalette.deep),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: HerCyclePalette.deep),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPreferencesCard(BuildContext context) {
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: HerCyclePalette.deep.withOpacity(0.75),
        );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text('Weekly insights', style: _detailLabelStyle()),
            subtitle: Text(
              'Receive a quick digest after each logged cycle to recap patterns.',
              style: subtitleStyle,
            ),
            value: _weeklyInsights,
            onChanged: _handleWeeklyInsightsChange,
            activeColor: HerCyclePalette.magenta,
          ),
          const Divider(height: 1),
          SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text('Reminders & nudges', style: _detailLabelStyle()),
            subtitle: Text(
              'Prompt reminders help you log data consistently and stay on track.',
              style: subtitleStyle,
            ),
            value: _cycleReminders,
            onChanged: _handleCycleRemindersChange,
            activeColor: HerCyclePalette.magenta,
          ),
        ],
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
