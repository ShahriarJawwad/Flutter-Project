import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../widgets/data_card.dart';
import '../services/mock_bluetooth_service.dart';
import '../services/database_helper.dart';
import '../services/firebase_helper.dart';
import 'history.dart';
import 'settings.dart';
import 'alert_utils.dart';

class DashboardScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) toggleDarkMode;

  const DashboardScreen({
    super.key,
    required this.isDarkMode,
    required this.toggleDarkMode,
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double temperature = 36.5;
  int bpm = 75;
  int spo2 = 98;
  List<SensorData> chartData = [];
  bool isConnected = false;
  final FirebaseHelper firebaseHelper = FirebaseHelper();
  StreamSubscription? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _loadChartDataFromDatabase();
    _initializeBluetoothConnection();
  }

  Future<void> _loadChartDataFromDatabase() async {
    final allData = await dbHelper.getAllData();
    DateTime cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
    List<SensorData> loadedData = [];

    for (var record in allData) {
      try {
        DateTime recordTime = DateTime.parse(record['timestamp']);
        if (recordTime.isAfter(cutoffTime)) {
          loadedData.add(
            SensorData(
              recordTime,
              (record['temperature'] as num).toDouble(),
              (record['bpm'] as num).toDouble(),
              (record['spo2'] as num).toDouble(),
            ),
          );
        }
      } catch (e) {
        print("Error parsing record: $e");
      }
    }

    loadedData.sort((a, b) => a.time.compareTo(b.time));

    setState(() {
      chartData = loadedData;
    });
  }

  Future<void> _initializeBluetoothConnection() async {
    try {
      isConnected = await mockBluetoothService.connect();
      if (isConnected) {
        _dataSubscription = mockBluetoothService.dataStream.listen((data) async {
          if (mounted) {
            await _processNewData(data);
          }
        });
      }
    } catch (e) {
      print('❌ Bluetooth Connection Error: $e');
      isConnected = false;
    }
  }

  Future<void> _processNewData(Map<String, dynamic> data) async {
    try {
      setState(() {
        temperature = data['temperature'];
        bpm = data['bpm'];
        spo2 = data['spo2'];

        final now = DateTime.now();
        chartData.add(SensorData(
          now,
          temperature,
          bpm.toDouble(),
          spo2.toDouble(),
        ));

        final cutoffTime = now.subtract(const Duration(hours: 24));
        chartData.removeWhere((data) => data.time.isBefore(cutoffTime));
      });

      await Future.wait([
        dbHelper.insertData(data),
        firebaseHelper.saveHealthData(data)
      ]);

      print("✅ Data processed and saved to databases");
      checkForAlerts(context, temperature, bpm, spo2);
    } catch (error) {
      print("❌ Error processing data: $error");
    }
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  DateTimeAxis _buildDateTimeAxis() {
    return DateTimeAxis(
      intervalType: DateTimeIntervalType.hours,
      interval: 3,
      dateFormat: DateFormat('h a'),
      labelRotation: -45,
      labelStyle: const TextStyle(fontSize: 10),
      minimum: DateTime.now().subtract(const Duration(hours: 24)),
      maximum: DateTime.now(),
    );
  }

  Widget _buildSingleChart({
    required String title,
    required double yMin,
    required double yMax,
    required double standardValue,
    required String yAxisTitle,
    required Color lineColor,
    required double Function(SensorData) valueMapper,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              margin: const EdgeInsets.all(0),
              plotAreaBorderWidth: 0,
              tooltipBehavior: TooltipBehavior(enable: true),
              primaryXAxis: _buildDateTimeAxis(),
              primaryYAxis: NumericAxis(
                title: AxisTitle(text: yAxisTitle),
                minimum: yMin,
                maximum: yMax,
                interval: (yMax - yMin) / 4,
                plotBands: <PlotBand>[
                  PlotBand(
                    start: standardValue,
                    end: standardValue,
                    borderWidth: 1,
                    color: lineColor.withOpacity(0.2),
                    dashArray: [5, 5],
                  )
                ],
              ),
              series: <CartesianSeries>[
                LineSeries<SensorData, DateTime>(
                  dataSource: chartData,
                  xValueMapper: (SensorData data, _) => data.time,
                  yValueMapper: (SensorData data, _) => valueMapper(data),
                  color: lineColor,
                  width: 2,
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    color: lineColor,
                    borderColor: Colors.white,
                    borderWidth: 2,
                    height: 8,
                    width: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Row(
            children: [
              const Text(
                'Neonatal Health Monitor',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                      color: isConnected ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 12,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottom: TabBar(
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(
                icon: const Icon(Icons.dashboard_rounded),
                child: Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Tab(
                icon: const Icon(Icons.history_rounded),
                child: Text(
                  'History',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Tab(
                icon: const Icon(Icons.settings_rounded),
                child: Text(
                  'Settings',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDataCard(
                            title: 'Body Temperature',
                            value: '${temperature.toStringAsFixed(1)}°C',
                            color: Colors.orange,
                            icon: Icons.thermostat_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDataCard(
                            title: 'Heart Rate',
                            value: '$bpm BPM',
                            color: Colors.red,
                            icon: Icons.favorite_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDataCard(
                            title: 'Oxygen Level',
                            value: '$spo2%',
                            color: Colors.blue,
                            icon: Icons.air_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Last 24 Hours Trend',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSingleChart(
                      title: 'Temperature (°C)',
                      yMin: 35.5,
                      yMax: 38.5,
                      standardValue: 36.8,
                      yAxisTitle: 'Temp (°C)',
                      lineColor: Colors.orange,
                      valueMapper: (data) => data.temp,
                    ),
                    _buildSingleChart(
                      title: 'Heart Rate (BPM)',
                      yMin: 50,
                      yMax: 110,
                      standardValue: 80,
                      yAxisTitle: 'BPM',
                      lineColor: Colors.red,
                      valueMapper: (data) => data.heartRate,
                    ),
                    _buildSingleChart(
                      title: 'SpO₂ (%)',
                      yMin: 90,
                      yMax: 100,
                      standardValue: 98,
                      yAxisTitle: 'SpO₂ (%)',
                      lineColor: Colors.blue,
                      valueMapper: (data) => data.spo2,
                    ),
                  ],
                ),
              ),
            ),
            const HistoryScreen(),
            SettingsScreen(
              isDarkMode: widget.isDarkMode,
              toggleDarkMode: widget.toggleDarkMode,
            ),
          ],
        ),
      ),
    );
  }
}

class SensorData {
  final DateTime time;
  final double temp;
  final double heartRate;
  final double spo2;

  SensorData(this.time, this.temp, this.heartRate, this.spo2);

  @override
  String toString() {
    return 'SensorData(time: $time, temp: $temp, heartRate: $heartRate, spo2:$spo2)';
  }
}