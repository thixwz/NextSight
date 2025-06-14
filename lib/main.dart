import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'providers/player_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/user_login.dart';
import 'screens/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- ADD GlobalKey for MainScreen --- 
final GlobalKey<State<MainScreen>> mainScreenKey = GlobalKey<State<MainScreen>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'NextSight',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            // Light Theme: iOS-style light grey background, white cards, green accents
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.green, // Keep green as the base
              scaffoldBackgroundColor: const Color(0xFFF2F2F7), // iOS light grey background
              // Define ColorScheme for more control
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: Colors.green,
                brightness: Brightness.light,
                backgroundColor: const Color(0xFFF2F2F7), // Ensure background is grey
              ).copyWith(
                primary: Colors.green, // Explicitly set primary green
                secondary: Colors.greenAccent, // Optional: Define a secondary green
                surface: Colors.white, // White surface for cards, dialogs etc.
                onSurface: Colors.black, // Black text on white surfaces
              ),
              appBarTheme: const AppBarTheme(
                // Use system settings for app bar color based on scroll (or set explicitly)
                backgroundColor: Color(0xFFF2F2F7), // Match scaffold background
                foregroundColor: Colors.black, // Black title/icons
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.dark, // Dark icons on light status bar
              ),
              cardTheme: CardTheme(
                color: Colors.white, // White cards
                elevation: 0.5, // Subtle elevation
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0), // iOS style corner radius
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Black 'Edit profile' button like iOS
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0), // More rounded
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600)
                ),
              ),
              // Theme for the switches to be green when active
              switchTheme: SwitchThemeData(
                thumbColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white; // White thumb when active
                  }
                  return null; // Default otherwise
                }),
                trackColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.green; // Green track when active
                  }
                  // --- CHANGE: Make inactive track more visible --- 
                  return Colors.black26; // Use a slightly darker grey for inactive track
                }),
              ),
              listTileTheme: const ListTileThemeData(
                iconColor: Colors.black54, // Default icon color for list tiles
              ),
              dividerTheme: const DividerThemeData(
                // --- CHANGE: Make divider more visible --- 
                color: Colors.black26, // Use a more opaque grey
                space: 1,
                thickness: 0.5,
              ),
              // Ensure text is generally black
              textTheme: ThemeData.light().textTheme.apply(
                bodyColor: Colors.black,
                displayColor: Colors.black,
              ),
            ),
            // Dark Theme: AMOLED Black background, blue accents (Remains unchanged)
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue, // Use blue as the base
              scaffoldBackgroundColor: Colors.black, // Pure black background
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black, // Black app bar
                foregroundColor: Colors.white, // White text/icons on app bar
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light, // Light icons on dark status bar
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 36, 155, 0), // Blue buttons
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
              // Define colorScheme for better dark theme control
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: Colors.blue,
                brightness: Brightness.dark,
              ).copyWith(
                background: Colors.black, // Ensure background is black
                surface: Colors.grey[850], // Slightly lighter surface for cards/dialogs if needed
              ),
            ),
            // Define initial route and routes table
            initialRoute: '/', 
            routes: {
              '/': (context) => StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.connectionState == ConnectionState.active) {
                    if (snapshot.hasData) { // User is logged in
                      return MainScreen(key: mainScreenKey);
                    } 
                    // User is logged out, snapshot.hasData is false
                    return const LoginScreen(); // This should be shown
                  }
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                },
              ),
              '/home': (context) => MainScreen(key: mainScreenKey),
            },
            // home: StreamBuilder<User?> ( // Remove this if using initialRoute and routes
            //   stream: FirebaseAuth.instance.authStateChanges(),
            //   builder: (context, snapshot) {
            //     if (snapshot.connectionState == ConnectionState.waiting) {
            //       return const Scaffold(body: Center(child: CircularProgressIndicator()));
            //     }
            //     if (snapshot.connectionState == ConnectionState.active) {
            //       if (snapshot.hasData) {
            //         // --- ASSIGN the key to MainScreen --- 
            //         return MainScreen(key: mainScreenKey);
            //       } else {
            //         return const LoginScreen();
            //       }
            //     }
            //     return const Scaffold(body: Center(child: CircularProgressIndicator()));
            //   },
            // ),
          );
        },
      ),
    );
  }
}
