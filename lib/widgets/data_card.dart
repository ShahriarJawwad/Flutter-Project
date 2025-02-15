import 'package:flutter/material.dart';

class DataCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const DataCard({super.key, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(Icons.health_and_safety, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
