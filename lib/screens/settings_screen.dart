import 'package:flutter/material.dart';
import '../utils/text_styles.dart';
import 'package:provider/provider.dart';
import '../models/gateway_config.dart';
import '../providers/gateway_provider.dart';
import '../providers/language_provider.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'language_selection_screen.dart';
import 'theme_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverController = TextEditingController();
  final _portController = TextEditingController();
  
  bool _autoStart = false;
  bool _replaceDialer = false;
  bool _enablePermissions = false;
  bool _rememberCredentials = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final provider = Provider.of<GatewayProvider>(context, listen: false);
    final config = provider.config;
    final storage = StorageService();
    final autoLogin = await storage.getAutoLogin();

    setState(() {
      if (config != null) {
        _usernameController.text = config.sipUsername;
        _passwordController.text = config.sipPassword;
        _serverController.text = config.sipServer;
        _portController.text = config.sipPort.toString();
        _autoStart = config.autoStart;
        _replaceDialer = config.replaceDialer;
        _enablePermissions = config.enablePermissions;
      }
      _rememberCredentials = autoLogin;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final config = GatewayConfig(
        sipUsername: _usernameController.text.trim(),
        sipPassword: _passwordController.text,
        sipServer: _serverController.text.trim(),
        sipPort: int.tryParse(_portController.text) ?? 5060,
        autoStart: _autoStart,
        replaceDialer: _replaceDialer,
        enablePermissions: _enablePermissions,
      );

      final provider = Provider.of<GatewayProvider>(context, listen: false);
      await provider.updateConfig(config);

      final storage = StorageService();
      await storage.saveAutoLogin(_rememberCredentials);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)?.settings ?? 'Settings',
          style: AppTextStyles.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SIP Configuration Section
              _buildSection(
                title: 'SIP Configuration',
                icon: Icons.settings,
                children: [
                  _buildTextField(
                    controller: _usernameController,
                    label: 'SIP Username',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter SIP username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'SIP Password',
                    icon: Icons.lock,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter SIP password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _serverController,
                    label: 'SIP Server',
                    icon: Icons.dns,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter SIP server';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _portController,
                    label: 'SIP Port',
                    icon: Icons.settings_ethernet,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter SIP port';
                      }
                      final port = int.tryParse(value);
                      if (port == null || port < 1 || port > 65535) {
                        return 'Please enter a valid port number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Gateway Options Section
              _buildSection(
                title: 'Gateway Options',
                icon: Icons.tune,
                children: [
                  _buildSwitchTile(
                    title: 'Auto Start Gateway',
                    subtitle: 'Automatically start gateway when app launches',
                    value: _autoStart,
                    onChanged: (value) {
                      setState(() {
                        _autoStart = value;
                      });
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Replace Default Dialer',
                    subtitle: 'Replace system dialer with gateway dialer',
                    value: _replaceDialer,
                    onChanged: (value) {
                      setState(() {
                        _replaceDialer = value;
                      });
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Enable Permissions',
                    subtitle: 'Request elevated permissions for telephony',
                    value: _enablePermissions,
                    onChanged: (value) {
                      setState(() {
                        _enablePermissions = value;
                      });
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Remember Credentials',
                    subtitle: 'Save credentials and auto-login',
                    value: _rememberCredentials,
                    onChanged: (value) {
                      setState(() {
                        _rememberCredentials = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Language Section
              _buildSection(
                title: 'Language',
                icon: Icons.language,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.language,
                      color: Colors.blue[400],
                    ),
                    title: Text(
                      'Change Language',
                      style: AppTextStyles.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      'Select your preferred language',
                      style: AppTextStyles.poppins(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LanguageSelectionScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Theme Section
              _buildSection(
                title: 'Theme',
                icon: Icons.palette,
                children: [
                  Consumer<ThemeService>(
                    builder: (context, themeService, child) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          themeService.getThemeIcon(),
                          color: Colors.blue[400],
                        ),
                        title: Text(
                          'Theme Settings',
                          style: AppTextStyles.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          'Current: ${themeService.getThemeName()}',
                          style: AppTextStyles.poppins(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey,
                          size: 16,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ThemeSettingsScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Save Settings',
                        style: AppTextStyles.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[600]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.blue[400],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.poppins(
        fontSize: 16,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.poppins(
          color: Colors.grey[400],
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.grey[400],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[400]!),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!),
        ),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.poppins(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue[400],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    _portController.dispose();
    super.dispose();
  }
} 