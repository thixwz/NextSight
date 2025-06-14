import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key}); // Keep the key if you use PageStorageKey

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// Add the mixin here
class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  // Add this override
  @override
  bool get wantKeepAlive => true;

  // --- REMOVE State variables for old switches --- 
  // bool _pushNotificationsEnabled = true;
  // bool _faceIdEnabled = true;

  // --- Logout function (Keep) --- 
  Future<void> _logout() async {
    final user = FirebaseAuth.instance.currentUser;
    bool signedInWithGoogle = false;
    if (user != null) {
      for (final providerData in user.providerData) {
        if (providerData.providerId == 'google.com') {
          signedInWithGoogle = true;
          break;
        }
      }
    }
    if (signedInWithGoogle) {
      await GoogleSignIn().signOut();
    }
    await FirebaseAuth.instance.signOut();

    // ADD THIS NAVIGATION LOGIC
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    }
  }

  // --- Helper function to build list tiles (Keep) --- 
  Widget _buildSettingsTile(String title, {IconData? icon, VoidCallback? onTap, Widget? trailing, Color? color}) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.listTileTheme.iconColor ?? theme.iconTheme.color;
    final textColor = color ?? theme.listTileTheme.textColor ?? theme.textTheme.bodyLarge?.color;

    return ListTile(
      leading: icon != null ? Icon(icon, color: iconColor) : null,
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: trailing ?? (title == 'Logout' ? null : Icon(Icons.arrow_forward_ios, size: 16.0, color: (iconColor ?? Colors.grey).withOpacity(0.6))),
      onTap: onTap ?? () {
        if (trailing is! Switch) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('$title tapped - Not implemented yet')),
           );
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    );
  }

  // --- Theme selection dialog function (kept for potential future use) --- 
  Future<void> _showThemeDialog() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    // No need to await or store result now
    await showDialog<void>( // Changed return type to void
      context: context,
      builder: (BuildContext context) {
        // No need for StatefulBuilder anymore
        // Get the current theme directly from the provider
        final currentMode = themeProvider.themeMode;

        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: currentMode, // Use currentMode from provider
                onChanged: (ThemeMode? value) {
                  if (value != null && value != currentMode) {
                    themeProvider.setThemeMode(value); // Apply immediately
                    Navigator.of(context).pop(); // Close dialog
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: currentMode, // Use currentMode from provider
                onChanged: (ThemeMode? value) {
                  if (value != null && value != currentMode) {
                    themeProvider.setThemeMode(value); // Apply immediately
                    Navigator.of(context).pop(); // Close dialog
                  }
                },
              ),
              // --- REMOVE System Default RadioListTile ---
              // RadioListTile<ThemeMode>(
              //   title: const Text('System Default'),
              //   ...
              // ),
            ],
          ),
          // --- REMOVE actions (OK/Cancel buttons) ---
          // actions: <Widget>[
          //   TextButton(...),
          //   TextButton(...),
          // ],
        );
      },
    );

    // --- REMOVE logic that waited for dialog result ---
    // if (selectedThemeMode != null) {
    //   themeProvider.setThemeMode(selectedThemeMode);
    // }
  }
  // --- End of theme dialog function ---

  // Define colors for switches to match the image
  final MaterialStateProperty<Color?> trackColor = MaterialStateProperty.resolveWith<Color?>(
  (Set<MaterialState> states) {
    if (states.contains(MaterialState.selected)) {
      return const Color(0xFFADF4AD).withOpacity(0.5); // Light green track when selected
    }
    return null; // Use default grey track when not selected
  },
  );
  final MaterialStateProperty<Color?> thumbColor = MaterialStateProperty.resolveWith<Color?>(
  (Set<MaterialState> states) {
    if (states.contains(MaterialState.selected)) {
      return const Color(0xFFADF4AD); // Light green thumb when selected
    }
    return null; // Use default grey when not selected
  },
  );
  // --- *** BUILD METHOD START *** ---
  @override
  Widget build(BuildContext context) {
    // Add this call
    super.build(context);

    // --- Define variables INSIDE build method --- 
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final String username = user?.displayName ?? 'YourUsername';
    final String email = user?.email ?? 'your.email@example.com';
    final String? photoURL = user?.photoURL;
    // --- Get ThemeProvider --- 
    final themeProvider = Provider.of<ThemeProvider>(context);

    // --- Define switch colors (Keep for Dark Mode switch) --- 
    final MaterialStateProperty<Color?> trackColor = MaterialStateProperty.resolveWith<Color?>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          // Use a neutral color or theme accent for dark mode toggle track
          return theme.colorScheme.primary.withOpacity(0.5);
        }
        return null;
      },
    );
    final MaterialStateProperty<Color?> thumbColor = MaterialStateProperty.resolveWith<Color?>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          // Use a neutral color or theme accent for dark mode toggle thumb
          return theme.colorScheme.primary;
        }
        return null;
      },
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: 40.0,
            bottom: 16.0, 
            left: 16.0, 
            right: 16.0
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- Profile Title --- 
              Text(
                'Profile',
                style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24.0),

              // --- Profile Info Card (Keep) --- 
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: isDarkMode ? [] : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08), // Slightly lighter shadow color
                      spreadRadius: 0.5, // Reduced spread
                      blurRadius: 4, // Reduced blur
                      offset: const Offset(0, 2),
                    )
                  ]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: colorScheme.secondaryContainer,
                          backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                          child: photoURL == null
                              ? Text(
                                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.bold
                                  )
                                )
                              : null,
                        ),
                        const SizedBox(width: 12.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              email,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit Profile tapped - Not implemented yet')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        textStyle: theme.textTheme.labelMedium,
                      ),
                      child: const Text('Edit profile'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32.0),

              // --- Preferences Section Title --- 
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Preferences',
                  style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
                ),
              ),
              // --- Updated Preferences Card --- 
              Card(
                color: theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                // Keep elevation minimal for modern look
                elevation: isDarkMode ? 0 : 0.5, // Slightly reduced light mode elevation
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // --- Dark Mode Tile --- 
                    _buildSettingsTile(
                      'Dark Mode',
                      icon: Icons.brightness_6_outlined,
                      trailing: Switch(
                        value: isDarkMode,
                        onChanged: (value) {
                          themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                        },
                        activeTrackColor: trackColor.resolve({MaterialState.selected}),
                        activeColor: thumbColor.resolve({MaterialState.selected}),
                        inactiveThumbColor: thumbColor.resolve({}),
                        inactiveTrackColor: trackColor.resolve({}),
                      ),
                      // No onTap needed as Switch handles interaction
                      onTap: null, 
                    ),
                    // --- Divider without indent --- 
                    Divider(height: 0.5, color: theme.dividerColor.withOpacity(0.5)), // Removed indent: 56

                    // --- Logout Tile (Keep) --- 
                    _buildSettingsTile(
                      'Logout',
                      icon: Icons.logout,
                      color: Colors.red,
                      trailing: null,
                      onTap: _logout,
                    ),
                    // No divider needed after the last item
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } // --- *** BUILD METHOD END *** ---
}

 