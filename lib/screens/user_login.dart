import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// google_sign_in: ^5.4.0
import 'signup_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb

class LoginScreen extends StatefulWidget { // <-- The class is named LoginScreen
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Add GlobalKey for Form
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false; // <-- Add this state variable

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
    super.dispose();
  }

  void _startImageAnimation() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _headerImages.length;
      });
    });
  }

  Future<void> _login() async {
    // Validate the form first
    if (!_formKey.currentState!.validate()) {
      return; // If validation fails, do nothing
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      // Set a generic error message instead of e.message
      setState(() {
        _errorMessage = "Wrong credentials. Please try again."; 
      });
      // Optional: Log the specific Firebase error for debugging
      // print('Firebase Auth Error: ${e.code} - ${e.message}'); 
    } catch (e) {
      // Catch any other unexpected errors
      setState(() {
        _errorMessage = "An unexpected error occurred. Please try again.";
      });
      // Optional: Log the unexpected error for debugging
      // print('Unexpected Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper for email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    // Basic email format check
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null; // Return null if valid
  }

  // Helper for password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null; // Return null if valid
  }

  // --- NEW: Google Sign-in Logic ---
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Trigger the Google Authentication flow.
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // If the user cancels the flow, googleUser will be null.
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; 
      }

      // Obtain the auth details from the request.
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential.
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Navigate to home screen on success
      // Inside _signInWithGoogle method, before navigation
      await Future.delayed(const Duration(milliseconds: 100)); // Small delay
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }

    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = "Google Sign-in failed. Please try again."; 
      });
      // print('Google Sign-in Firebase Auth Error: ${e.code} - ${e.message}');
    } catch (e) {
      setState(() {
        _errorMessage = "An unexpected error occurred during Google Sign-in.";
      });
      // print('Google Sign-in Unexpected Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // --- END NEW ---

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2E7D32);
    const Color lightGreen = Color(0xFF66BB6A);
    const Color accentGreen = Color(0xFF4CAF50); // <-- Make sure this is defined

    // Define the main content widget
    Widget loginContent = Form(
      key: _formKey,
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
            'Log in',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'By logging in, you agree to our Terms of Use.',
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
                    errorStyle: const TextStyle(color: Colors.redAccent), // Style for error text
                  ),
                  validator: _validateEmail, // Assign email validator
                  // autovalidateMode: AutovalidateMode.onUserInteraction, // <-- REMOVE THIS LINE
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible, // <-- Use state variable
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
                  validator: _validatePassword, // Assign password validator
                  // autovalidateMode: AutovalidateMode.onUserInteraction, // <-- REMOVE THIS LINE
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0), // Add padding
                    child: Text(
                      _errorMessage!,
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
                    onPressed: _isLoading ? null : _login, // Disable button while loading
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Log in', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Or'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 8),
                // --- Google Sign-in Button --- 
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Image.asset('assets/google_icon.png', height: 20), 
                    label: const Text('Sign in with Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isLoading ? null : _signInWithGoogle, 
                  ),
                ),
                // --- END Google Sign-in Button ---
                
                const SizedBox(height: 16), 
                // --- Sign Up Link --- 
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                    );
                  },
                  child: Text(
                    'Don\'t have an account? Sign up',
                    style: TextStyle(color: accentGreen, fontWeight: FontWeight.w600),
                  ),
                ),
                // --- END Sign Up Link ---
              ],
            ),
          ),
          const SizedBox(height: 20), // Optional: Add some bottom padding
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
                      child: loginContent,
                    )
                  : loginContent, // No constraint for mobile
            ),
          ),
        ),
      ), // This is the closing parenthesis for Scaffold
    ); // Add this closing parenthesis and semicolon for the Theme widget
  }
}