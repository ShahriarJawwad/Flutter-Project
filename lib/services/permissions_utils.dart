import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
/// Request Bluetooth and Location permissions at runtime
Future<bool> requestBluetoothPermissions() async {
  // Request Bluetooth and Location permissions (required for Bluetooth scanning)
  PermissionStatus bluetoothPermission = await Permission.bluetooth.request();
  PermissionStatus locationPermission = await Permission.locationWhenInUse.request();

  // Check if both permissions are granted
  if (bluetoothPermission.isGranted && locationPermission.isGranted) {
    return true;
  } else {
    // Either Bluetooth or Location permissions are denied
    return false;
  }
}

/// Request Storage permissions (required for reading and writing to external storage)
/// Request Storage permissions (required for reading and writing to external storage)
Future<bool> requestStoragePermissions() async {
  if (Platform.isAndroid) {
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true; // Permission granted
    }
  }

  // For Android 10 and below
  PermissionStatus storagePermission = await Permission.storage.request();

  return storagePermission.isGranted;
}


/// Function to check if all required permissions are granted (Bluetooth and Storage)
Future<void> checkAndRequestPermissions() async {
  bool bluetoothPermissionsGranted = await requestBluetoothPermissions();
  bool storagePermissionsGranted = await requestStoragePermissions();

  if (!bluetoothPermissionsGranted) {
    print("Bluetooth permissions are required for full functionality.");
  }
  if (!storagePermissionsGranted) {
    print("Storage permissions are required for exporting data.");
  }
}