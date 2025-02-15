import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart'; // Import the SplashScreen
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase

  runApp(const NeonatalMonitoringApp());
}

class NeonatalMonitoringApp extends StatefulWidget {
  const NeonatalMonitoringApp({super.key});

  @override
  _NeonatalMonitoringAppState createState() => _NeonatalMonitoringAppState();
}

class _NeonatalMonitoringAppState extends State<NeonatalMonitoringApp> {
  late ValueNotifier<bool> isDarkModeNotifier;

  @override
  void initState() {
    super.initState();
    isDarkModeNotifier = ValueNotifier<bool>(false);
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool savedTheme = prefs.getBool('darkMode') ?? false;
    isDarkModeNotifier.value = savedTheme;
  }

  Future<void> _toggleDarkMode(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool newThemeValue = !isDarkModeNotifier.value; // Toggle the theme manually
    print("Theme changed to: ${newThemeValue ? "Dark" : "Light"}"); // Debugging print

    await prefs.setBool('darkMode', newThemeValue); // Save new theme state
    isDarkModeNotifier.value = newThemeValue; // Update ValueNotifier
  }



  @override
  Widget build(BuildContext context) {
    print("Building MaterialApp with Theme: ${isDarkModeNotifier.value ? "Dark" : "Light"}"); // Debugging print
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Neonatal Health Monitor',
          theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
          home: SplashScreen(
            isDarkMode: isDarkMode,
            toggleDarkMode: _toggleDarkMode,
          ),
        );
      },
    );
  }


}
