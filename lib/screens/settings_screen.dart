import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/cupertino.dart'; // Import Cupertino widgets

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// Add TabController mixin
class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // bool _friendRadarEnabled = false; // State for the switch <-- REMOVE THIS LINE

  @override
  void initState() {
    super.initState();
    // Initialize TabController
    _tabController = TabController(length: 3, vsync: this); 
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose controller
    super.dispose();
  }

  // Updated Logout function with CupertinoAlertDialog
  // Temporarily replace showCupertinoDialog for testing
  // SUPER SIMPLE TEST FUNCTION
  Future<void> _showLogoutConfirmationDialog() async {
    print("LOGOUT BUTTON PRESSED - FUNCTION CALLED");
    // Temporarily comment out all dialog and logout logic
    /*
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Log Out (Material)'),
        content: const Text('Are you sure you want to log out?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Go Back'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: const Text('Confirm'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );

    if (confirmLogout == true) {
      // User confirmed, proceed with logout
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

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
      }
    }
    */
  }

  // bool _friendRadarEnabled = false; // <-- REMOVE this state variable

  // Helper function to build list tiles for settings
  Widget _buildSettingsTile(String title, {VoidCallback? onTap, Widget? trailing}) {
    return ListTile(
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.grey),
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title tapped - Not implemented yet')),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), // Adjust padding
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Use email part before '@' as a fallback username if displayName is null
    final String username = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    final String? photoURL = user?.photoURL;
    // Define pink color from image
    const Color profilePink = Color(0xFFF06292); // Example pink, adjust as needed

    return Scaffold(
      // No AppBar here, header is part of the body
      backgroundColor: Colors.white, // White background like the image
      body: NestedScrollView( // Allows AppBar-like behavior with scrolling content
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              // pinned: true, // Keeps the title visible when scrolling up
              // floating: true, // Makes AppBar reappear immediately when scrolling down
              automaticallyImplyLeading: false, // No back button
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0, // No shadow
              centerTitle: true,
              title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w600)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.ios_share_outlined), // Share icon
                  onPressed: () {
                     print('Share tapped');
                     // TODO: Implement share functionality
                  },
                ),
              ],
              expandedHeight: 200.0, // Reduced height slightly after removing bio
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.only(top: 70.0), // Adjust top padding
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: profilePink.withOpacity(0.2),
                        backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                        // Placeholder if no image - consider adding initials or icon
                        child: photoURL == null 
                          ? Text(username.isNotEmpty ? username[0].toUpperCase() : '?', style: const TextStyle(fontSize: 40, color: Colors.white))
                          : null, 
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '@$username', // Display username with '@'
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.pinkAccent, size: 18), // Verification badge
                        ],
                      ),
                      // const SizedBox(height: 4), // Remove space for bio
                      // const Text( // <-- REMOVE Bio Text
                      //   'love. eat. design',
                      //   style: TextStyle(fontSize: 14, color: Colors.grey),
                      // ),
                    ],
                  ),
                ),
              ),
              // TabBar below the profile info
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.black, // Black indicator line
                indicatorWeight: 3.0,
                tabs: const [
                  Tab(text: 'Account'),
                  Tab(text: 'Activity'),
                  Tab(text: 'Integrations'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // --- Account Tab Content ---
            ListView(
              padding: EdgeInsets.zero, // Remove padding handled by ListTile
              children: [
                _buildSettingsTile('Manage theme'), // No icon needed based on image
                _buildSettingsTile('Profile settings'),
                // _buildSettingsTile('Privacy'), // <-- REMOVE Privacy
                // _buildSettingsTile('Devices'), // <-- REMOVE Devices
                // SwitchListTile( // <-- REMOVE Friend Radar
                //   title: const Text('Friend radar'),
                //   value: _friendRadarEnabled,
                //   onChanged: (bool value) {
                //     setState(() {
                //       _friendRadarEnabled = value;
                //     });
                //   },
                //   activeColor: profilePink,
                //   contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                // ),
                const SizedBox(height: 30), // Space before logout
                // Logout Button
                Center(
                  child: TextButton(
                    onPressed: _showLogoutConfirmationDialog, // Ensure this is still correct
                    child: const Text(
                      'Log out',
                      style: TextStyle(color: profilePink, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Space at the bottom
              ],
            ),
            // --- Activity Tab Placeholder ---
            const Center(child: Text('Activity - Not Implemented')),
            // --- Integrations Tab Placeholder ---
            const Center(child: Text('Integrations - Not Implemented')),
          ],
        ),
      ),
    );
  }
}