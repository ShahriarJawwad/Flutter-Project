// mock_bluetooth_service.dart
import 'dart:async';
import 'dart:math';

class MockBluetoothService {
  final _random = Random();
  Timer? _timer;
  bool _isConnected = false;
  final StreamController<Map<String, dynamic>> _controller =
  StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get dataStream => _controller.stream;
  bool get isConnected => _isConnected;

  MockBluetoothService() {
    _isConnected = false;
  }

  Future<bool> connect() async {
    if (_isConnected) return true;

    await Future.delayed(Duration(seconds: 1));
    _isConnected = true;

    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!_controller.isClosed) {
        var data = {
          "temperature": 36.0 + _random.nextDouble() * 2,
          "bpm": 60 + _random.nextInt(40),
          "spo2": 95 + _random.nextInt(5),
          "timestamp": DateTime.now().toIso8601String(),
        };

        _controller.add(data);
        print("📊 Generated new sensor data");
      }
    });

    return true;
  }

  Future<void> disconnect() async {
    _isConnected = false;
    _timer?.cancel();
    await Future.delayed(Duration(milliseconds: 500));
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
    _isConnected = false;
  }
}

// Create a singleton instance
final mockBluetoothService = MockBluetoothService();