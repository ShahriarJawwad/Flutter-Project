import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart'; // Import the DashboardScreen

class SplashScreen extends StatefulWidget {
  final bool isDarkMode; // Receive dark mode state
  final Function(bool) toggleDarkMode; // Receive toggle function

  const SplashScreen({super.key, required this.isDarkMode, required this.toggleDarkMode});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    // Add a delay of 3 seconds before navigating to the next screen
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            isDarkMode: widget.isDarkMode, // Pass dark mode state
            toggleDarkMode: widget.toggleDarkMode, // Pass the toggle function
          ),
        ),
      );
    });
  }

  // Load saved dark mode preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // You can change the background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.health_and_safety, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Neonatal Health Monitor',
              style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}