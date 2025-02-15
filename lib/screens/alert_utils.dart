import 'package:flutter/material.dart';

void checkForAlerts(BuildContext context, double temperature, int bpm, int spo2) {
  if (temperature > 37.5) {
    // Show high temperature alert
    showAlert(context, 'Child\'s temperature is high! They might have a fever.');
  }

  if (bpm > 150) {
    // Show high BPM alert
    showAlert(context, 'Child\'s BPM is high!');
  }
  if (bpm < 70) {
    // Show low BPM alert
    showAlert(context, 'Child\'s BPM is low!');
  }
  if (spo2 < 95) {
    // Show low SpO2 alert
    showAlert(context, 'Child\'s SpO2 is low! Please check the oxygen levels.');
  }
}

void showAlert(BuildContext context, String message) {
  // Show a Snackbar with the alert message
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: Colors.red,
    duration: const Duration(seconds: 3),
  ));
}