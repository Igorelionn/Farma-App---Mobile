import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _darkMode = false;
  bool _prefsLoaded = false;

  static const _kNotifications = 'pref_notifications';
  static const _kEmailNotifications = 'pref_email_notifications';
  static const _kPushNotifications = 'pref_push_notifications';
  static const _kDarkMode = 'pref_dark_mode';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_kNotifications) ?? true;
      _emailNotifications = prefs.getBool(_kEmailNotifications) ?? true;
      _pushNotifications = prefs.getBool(_kPushNotifications) ?? true;
      _darkMode = prefs.getBool(_kDarkMode) ?? false;
      _prefsLoaded = true;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Configurações',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Notificações',
            children: [
              _buildSwitchTile(
                title: 'Ativar notificações',
                subtitle: 'Receba notificações sobre pedidos e ofertas',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  _savePref(_kNotifications, value);
                },
              ),
              if (_notificationsEnabled) ...[
                _buildSwitchTile(
                  title: 'Notificações por e-mail',
                  subtitle: 'Receba atualizações por e-mail',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() => _emailNotifications = value);
                    _savePref(_kEmailNotifications, value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Notificações push',
                  subtitle: 'Receba notificações no celular',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() => _pushNotifications = value);
                    _savePref(_kPushNotifications, value);
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Aparência',
            children: [
              _buildSwitchTile(
                title: 'Modo escuro',
                subtitle: 'Usar tema escuro no aplicativo',
                value: _darkMode,
                onChanged: (value) {
                  setState(() => _darkMode = value);
                  _savePref(_kDarkMode, value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Modo escuro será implementado em breve'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Conta',
            children: [
              _buildOptionTile(
                icon: Icons.lock_outline,
                title: 'Alterar senha',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alteração de senha em desenvolvimento'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.language_outlined,
                title: 'Idioma',
                subtitle: 'Português (Brasil)',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seleção de idioma em desenvolvimento'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A1A1A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF757575),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A1A1A),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF757575),
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
      onTap: onTap,
    );
  }
}
