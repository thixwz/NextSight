import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Add this import

class UsernameSetupScreen extends StatefulWidget {
  final String email; // Receive email from signup

  const UsernameSetupScreen({super.key, required this.email});

  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  late TextEditingController _usernameController;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // Define Green Theme Colors (consistent with other screens)
  static const Color primaryGreen = Color(0xFF2E7D32); // Main accent
  // static const Color lightGreen = Color(0xFF66BB6A); // Previous background
  static const Color accentGreen = Color(0xFF4CAF50); // Secondary accent
  static const Color screenBackground = Color(0xFFF0F4F8); // New lighter background
  static const Color cardBackground = Colors.white;
  static const Color textColorDark = Colors.black87;
  static const Color textColorLight = Colors.white;
  static const Color hintColor = Colors.black54;

  @override
  void initState() {
    super.initState();
    // Extract suggested username from email
    String suggestedUsername = widget.email.split('@')[0];
    // Handle cases where email might start with '@' or be empty
    if (suggestedUsername.isEmpty && widget.email.contains('@')) {
      suggestedUsername = 'user'; // Default fallback
    }
    _usernameController = TextEditingController(text: suggestedUsername);
  }

  Future<void> _updateUsernameAndContinue() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't proceed if validation fails
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final newUsername = _usernameController.text.trim();

      if (user != null && newUsername.isNotEmpty) {
        await user.updateDisplayName(newUsername);
        // Optional: You might want to store this in Firestore too if needed elsewhere

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else {
        // Handle case where user is null or username is empty (shouldn't happen with validation)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not update username. Please try again.')),
          );
        }
      }
    } catch (e) {
      // Handle errors during update
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating username: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username cannot be empty';
    }
    // Add any other username validation rules here (e.g., length, characters)
    return null;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: screenBackground,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return true; 
      },
      child: Theme(
        data: ThemeData.light().copyWith(
          inputDecorationTheme: InputDecorationTheme(
              hintStyle: TextStyle(color: hintColor),
              labelStyle: TextStyle(color: hintColor),
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: primaryGreen,
            selectionColor: primaryGreen.withOpacity(0.3),
            selectionHandleColor: primaryGreen,
          ),
        ),
        child: Scaffold(
          backgroundColor: screenBackground,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  // Corrected Form widget usage
                  child: Form(
                    key: _formKey, // Use named parameter 'key'
                    // The child of the Form is the Column
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_circle_outlined, size: 60, color: primaryGreen),
                        const SizedBox(height: 16),
                        const Text(
                          'Create Your Profile',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColorDark),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose a username that represents you.',
                          style: TextStyle(fontSize: 16, color: textColorDark.withOpacity(0.7)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, color: primaryGreen.withOpacity(0.8), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Welcome to NextSight!',
                              style: TextStyle(fontSize: 15, color: primaryGreen, fontWeight: FontWeight.w500),
                            ),
                          ], // Closing ']' for Row's children
                        ), // Closing ')' for Row
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          decoration: BoxDecoration(
                            color: cardBackground,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _usernameController,
                                style: const TextStyle(color: textColorDark, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Enter your username',
                                  prefixIcon: Icon(Icons.person_outline, color: primaryGreen.withOpacity(0.7)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: primaryGreen, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: screenBackground,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                ),
                                validator: _validateUsername,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryGreen,
                                    foregroundColor: textColorLight,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 3,
                                  ),
                                  onPressed: _isLoading ? null : _updateUsernameAndContinue,
                                  child: _isLoading
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                      : const Text('Save & Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ], // Closing ']' for Container's Column children
                          ), // Closing ')' for Container
                        ),
                      ], // Closing ']' for Form's Column children
                    ), // Closing ')' for Form's Column (child of Form)
                  ), // Closing ')' for Form
                ), // Closing ')' for Padding
              ), // Closing ')' for SingleChildScrollView
            ), // Closing ')' for Center
          ), // Closing ')' for SafeArea
        ), // Closing ')' for Scaffold
      ), // Closing ')' for Theme
    ); // Closing ')' for WillPopScope
  }
}