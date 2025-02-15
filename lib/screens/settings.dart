import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Updated import for flutter_blue_plus
import 'package:permission_handler/permission_handler.dart'; // Import for permission handler
import '../services/permissions_utils.dart';  // Import the permission handler function
import '../services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) toggleDarkMode;

  const SettingsScreen({super.key, required this.isDarkMode, required this.toggleDarkMode});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isBluetoothConnected = false;
  BluetoothDevice? _connectedDevice;
  BluetoothAdapterState _bluetoothState = BluetoothAdapterState.unknown;
  StreamSubscription<BluetoothAdapterState>? _stateSubscription;

  bool isDarkModeEnabled = false; // Local state for Dark Mode switch

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isDarkModeEnabled = widget.isDarkMode; // Initialize local dark mode state

    _stateSubscription = FlutterBluePlus.state.listen((state) {
      setState(() {
        _bluetoothState = state;
      });
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _connectBluetooth() async {
    bool permissionsGranted = await requestBluetoothPermissions();
    if (!permissionsGranted) {
      Fluttertoast.showToast(msg: "Bluetooth permissions denied. Cannot proceed.");
      return;
    }

    if (isBluetoothConnected) {
      await _connectedDevice?.disconnect();
      setState(() {
        isBluetoothConnected = false;
      });
    } else {
      FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (result.device.name == "HC-05") {
            FlutterBluePlus.stopScan();
            _connectToDevice(result.device);
            break;
          }
        }
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await device.connect();
    setState(() {
      _connectedDevice = device;
      isBluetoothConnected = true;
    });
    Fluttertoast.showToast(msg: "Connected to ${device.name}");
  }

  Future<void> _exportData() async {
    bool permissionsGranted = await requestStoragePermissions();

    if (!permissionsGranted) {
      Fluttertoast.showToast(msg: "Storage permission denied. Please allow 'All Files Access' in settings.");

      // Open settings page where user can enable MANAGE_EXTERNAL_STORAGE
      openAppSettings();
      return;
    }

    try {
      await dbHelper.copyDatabaseToExternalStorage();
      Fluttertoast.showToast(msg: "Data exported successfully!");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to export data: $e");
    }
  }


  void _toggleDarkMode(bool value) {
    setState(() {
      isDarkModeEnabled = value; // Update switch UI immediately
    });
    widget.toggleDarkMode(value); // Apply the dark mode change globally
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.blue),
                    title: const Text("Profile Management"),
                    subtitle: const Text("Manage your profile details"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Edit Profile"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(labelText: 'Name'),
                                ),
                                TextField(
                                  controller: emailController,
                                  decoration: const InputDecoration(labelText: 'Email'),
                                ),
                                TextField(
                                  controller: phoneController,
                                  decoration: const InputDecoration(labelText: 'Phone'),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Fluttertoast.showToast(msg: "Profile updated");
                                  Navigator.pop(context);
                                },
                                child: const Text("Save"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.bluetooth, color: Colors.blue),
                    title: const Text("Bluetooth Connection"),
                    subtitle: Text(isBluetoothConnected ? "Connected" : "Disconnected"),
                    onTap: _connectBluetooth,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.file_download, color: Colors.green),
                    title: const Text("Export Data"),
                    subtitle: const Text("Download your health data"),
                    onTap: _exportData,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text("Dark Mode"),
                    subtitle: const Text("Enable dark theme"),
                    value: isDarkModeEnabled, // Local state used for UI update
                    onChanged: _toggleDarkMode,
                    secondary: const Icon(Icons.brightness_6, color: Colors.orange),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
