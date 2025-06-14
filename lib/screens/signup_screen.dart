import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb
import 'username_setup_screen.dart'; // <-- Import the new screen

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Add GlobalKey for Form
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error; // Variable is named _error
  bool _isPasswordVisible = false;

  // Animation state
  int _currentImageIndex = 0;
  final List<String> _headerImages = [
    'assets/image1.png', // Replace with your image assets
    'assets/image2.png',
    'assets/image3.png',
  ];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startImageAnimation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose(); // Dispose controllers
    _passwordController.dispose();
    super.dispose();
  }

  void _startImageAnimation() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _headerImages.length;
      });
    });
  }

  // Helper for email validation (same as login)
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Helper for password validation (same as login)
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    // Optional: Add password complexity rules here if needed
    // e.g., if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null; // <-- CORRECTED: Use _error, not _errorMessage
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted && credential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UsernameSetupScreen(email: credential.user!.email!),
          ),
        );
      }

    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? "An unknown error occurred."; 
      });
    } catch (e) {
      setState(() {
        _error = "An unexpected error occurred. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2E7D32);
    const Color lightGreen = Color(0xFF66BB6A);
    const Color accentGreen = Color(0xFF4CAF50); // <-- Make sure this is defined

    // Define the main content widget
    Widget signupContent = Form( // Wrap content in a Form
      key: _formKey, // Assign the key
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Header Image
          SizedBox(
            height: 180,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Image.asset(
                _headerImages[_currentImageIndex],
                key: ValueKey<int>(_currentImageIndex),
                height: 120,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.eco, size: 100, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your details to get started.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Your email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    errorStyle: const TextStyle(color: Colors.redAccent),
                  ),
                  validator: _validateEmail,
                  // autovalidateMode: AutovalidateMode.onUserInteraction, // <-- REMOVE THIS LINE
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    errorStyle: const TextStyle(color: Colors.redAccent),
                    // --- Add suffixIcon --- 
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined // <-- Use outlined icon
                            : Icons.visibility_off_outlined, // <-- Use outlined icon
                        color: accentGreen, // <-- Set color to accentGreen
                        // size: 20, // <-- Optional: Uncomment and adjust if needed
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    // --- End suffixIcon --- 
                  ),
                  validator: _validatePassword,
                  // autovalidateMode: AutovalidateMode.onUserInteraction, // <-- REMOVE THIS LINE
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                // Remove the SizedBox(height: 8) that was here
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    // Disable button while loading
                    onPressed: _isLoading ? null : _signup, 
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Sign Up', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // Go back to login
                  child: Text(
                    'Already have an account? Log in',
                    style: TextStyle(color: accentGreen, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: lightGreen,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              // Conditionally apply max width for web
              child: kIsWeb
                  ? Container(
                      constraints: const BoxConstraints(maxWidth: 600), // Max width for web
                      child: signupContent,
                    )
                  : signupContent, // No constraint for mobile
            ),
          ),
        ),
      ),
    );
  }
}