import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mtv_app/l10n/app_localizations.dart';
import 'package:mtv_app/src/core/auth/auth_notifier.dart';
import '../widgets/login_dialog.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onSettingsSaved;

  const SettingsPage({Key? key, required this.onSettingsSaved}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentAddress();
  }

  Future<void> _loadCurrentAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('api_server_address');
    if (address != null) {
      _controller.text = address;
    }
  }

  Future<void> _saveAddress() async {
    final address = _controller.text.trim();
    if (address.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 1. Validate the server address
    bool isValid = false;
    try {
      final dio = Dio();
      final validationUrl = '$address/api/server-config';
      final response = await dio.get(validationUrl, options: Options(sendTimeout: const Duration(milliseconds: 5000), receiveTimeout: const Duration(milliseconds: 5000)));
      if (response.statusCode == 200) {
        isValid = true;
      }
    } catch (e) {
      isValid = false;
    }

    if (!mounted) return;

    if (!isValid) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Validation failed. Check the address or server status.')),
      );
      return;
    }

    setState(() {
      _isLoading = false;
    });

    // 2. 显示登录对话框
    if (!mounted) return;
    await _showLoginDialog(address);
  }

  /// 显示登录对话框
  Future<void> _showLoginDialog(String serverAddress) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoginDialog(
        serverAddress: serverAddress,
        onLoginSuccess: () => _onLoginSuccess(serverAddress),
      ),
    );
  }

  /// 登录成功后的处理
  Future<void> _onLoginSuccess(String address) async {
    // 登录成功后保存API地址
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString('api_server_address', address);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.loginSuccessful ?? 'Login successful! Settings saved.'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onSettingsSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save address. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.settings ?? 'Settings'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.apiServerAddress ?? 'API Server Address',
                  labelStyle: Theme.of(context).textTheme.bodyMedium,
                  hintText: 'e.g., http://192.168.1.100:8080',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveAddress,
                      child: Text(AppLocalizations.of(context)?.save ?? 'Validate and Save'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
