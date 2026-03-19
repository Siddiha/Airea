import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'patient_homescreen.dart';
import 'patient_create_account.dart';
import 'forgot_password_screen.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';

class PatientLoginPage extends StatefulWidget {
  const PatientLoginPage({super.key});

  @override
  State<PatientLoginPage> createState() => _PatientLoginPageState();
}

class _PatientLoginPageState extends State<PatientLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    bool hasError = false;

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      hasError = true;
    } else if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    final result = await _authService.login(email, password);

    setState(() => _isLoading = false);

    if (result['success']) {
      await _fetchAndSavePatientCode(email, password);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PatientHomeScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  Future<void> _fetchAndSavePatientCode(String email, String password) async {
    try {
      // Step 1: Ensure patient record exists in backend DB by calling register
      // If already registered, backend returns error which we ignore
      final prefs = await SharedPreferences.getInstance();
      final savedFullName = prefs.getString('user_full_name') ?? '';
      try {
        final registerUrl = Uri.parse('${ApiConfig.baseUrl}/auth/register');
        await http.post(
          registerUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'fullName': savedFullName,
          }),
        ).timeout(const Duration(seconds: 10));
      } catch (_) {
        // Ignore - patient may already exist or backend unavailable
      }

      // Sync full_name directly to Supabase in case the Spring Boot register
      // call above was rejected (email already registered)
      if (savedFullName.isNotEmpty) {
        try {
          await Supabase.instance.client
              .from('patients')
              .upsert(
                {'email': email, 'full_name': savedFullName},
                onConflict: 'email',
              );
        } catch (_) {
          // Non-fatal — name sync will retry on next login
        }
      }

      // Step 2: Fetch patient code from backend API
      final codeUrl = Uri.parse(
          '${ApiConfig.baseUrl}/auth/patient/code?email=${Uri.encodeComponent(email)}');
      final resp = await http.get(codeUrl).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['code'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('patient_code', data['code']);
        }
      }

      // Fetch and save the patient's full name
      final supabase = Supabase.instance.client;
      final nameResp = await supabase
          .from('patients')
          .select('patient_code, full_name')
          .eq('email', email)
          .maybeSingle();
      if (nameResp != null) {
        final prefs = await SharedPreferences.getInstance();
        if (nameResp['patient_code'] != null && (prefs.getString('patient_code') == null || prefs.getString('patient_code')!.isEmpty)) {
          await prefs.setString('patient_code', nameResp['patient_code']);
        }
        if (nameResp['full_name'] != null && (nameResp['full_name'] as String).isNotEmpty) {
          await prefs.setString('user_full_name', nameResp['full_name']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching patient code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                const Text(
                  'Welcome, Back !',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 60),

                // Email Field
                TextField(
                  controller: _emailController,
                  onChanged: (_) => setState(() => _emailError = null),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: const TextStyle(
                      color: Colors.black54,
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFD8E3E7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    errorText: _emailError,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  onChanged: (_) => setState(() => _passwordError = null),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(
                      color: Colors.black54,
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFD8E3E7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    errorText: _passwordError,
                  ),
                ),

                const SizedBox(height: 12),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(userType: 'PATIENT'),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Color(0xFF1B3A5F),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 100),

                // Login Button
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: AppTheme.primaryButton(),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),

                const SizedBox(height: 30),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account ? ",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PatientCreateAccount()),
                        );
                      },
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}