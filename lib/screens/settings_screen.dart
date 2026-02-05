//halkaan soo dhig koodhkaaga Dart ee faylka lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Ensure themeNotifier is accessible from main.dart

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notifications = true;
  String _selectedLang = "English";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load saved preferences from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDark') ?? false;
      _selectedLang = prefs.getString('lang') ?? "English";
    });
  }

  // Handle Dark Mode toggle
  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = value;
    });
    await prefs.setBool('isDark', value);

    // Update the global theme notifier to refresh the UI immediately
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
  }

  // Show Language Selection menu
  void _changeLanguage() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Select Language",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Text("🇺🇸", style: TextStyle(fontSize: 22)),
              title: const Text("English"),
              trailing: _selectedLang == "English"
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => _updateLang("English"),
            ),
            ListTile(
              leading: const Text("🇸🇴", style: TextStyle(fontSize: 22)),
              title: const Text("Somali"),
              trailing: _selectedLang == "Somali"
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => _updateLang("Somali"),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Update and save language choice
  Future<void> _updateLang(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLang = lang;
    });
    await prefs.setString('lang', lang);
    if (mounted) Navigator.pop(context);
  }

  // Logout logic
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear user session
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          // Appearance Section
          const _SectionHeader(title: "Appearance"),
          ListTile(
            leading: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
            title: const Text("Dark Mode"),
            subtitle: Text(_isDarkMode ? "Enabled" : "Disabled"),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
              activeColor: Colors.green,
            ),
          ),

          const Divider(),

          // Preferences Section
          const _SectionHeader(title: "General"),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Language"),
            subtitle: Text(_selectedLang),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _changeLanguage,
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text("Push Notifications"),
            trailing: Switch(
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
              activeColor: Colors.green,
            ),
          ),

          const Divider(),

          // Account Section
          const _SectionHeader(title: "Account"),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}

// Reusable Widget for Section Headers
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
