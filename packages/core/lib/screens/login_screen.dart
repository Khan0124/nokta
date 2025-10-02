import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nokta_pos/providers/session.dart';
import 'package:nokta_pos/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tenantController = TextEditingController(); // معرف المستأجر
  bool isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _tenantController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final tenantId = _tenantController.text.trim();

    try {
      final result = await AuthService.login(username, password, tenantId);

      if (result['success']) {
        final session = Provider.of<Session>(context, listen: false);
        await session.login(
          result['user'],
          result['token'],
          tenantId,
        );

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الاتصال: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _tenantController,
                decoration: const InputDecoration(labelText: 'معرف المستأجر'),
                validator: (value) => value!.isEmpty ? 'أدخل معرف المستأجر' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'اسم المستخدم'),
                validator: (value) => value!.isEmpty ? 'أدخل اسم المستخدم' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'أدخل كلمة المرور' : null,
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _login,
                child: const Text('دخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}