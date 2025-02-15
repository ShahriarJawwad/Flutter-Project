import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart'; // Ensure this import points to your database helper file

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> dates = [];
  List<double> temperatureData = [];
  List<double> bpmData = [];
  List<double> spo2Data = [];
  String selectedDate = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHistoryData();
  }

  Future<void> loadHistoryData() async {
    final allData = await dbHelper.getAllData();
    DateTime now = DateTime.now();
    List<DateTime> last7Days = List.generate(7, (index) {
      return DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - index));
    });

    final dateFormat = DateFormat('MMM dd');

    List<String> tempDates = [];
    List<double> tempTemps = [];
    List<double> tempBpm = [];
    List<double> tempSpo2 = [];

    for (DateTime day in last7Days) {
      String formattedDay = dateFormat.format(day);
      tempDates.add(formattedDay);

      var recordsForDay = allData.where((record) {
        try {
          DateTime recordDate = DateTime.parse(record['timestamp']);
          return recordDate.year == day.year &&
              recordDate.month == day.month &&
              recordDate.day == day.day;
        } catch (e) {
          return false;
        }
      }).toList();

      if (recordsForDay.isNotEmpty) {
        double avgTemp = recordsForDay
            .map((r) => (r['temperature'] as num).toDouble())
            .reduce((a, b) => a + b) /
            recordsForDay.length;

        double avgBpm = recordsForDay
            .map((r) => (r['bpm'] as num).toDouble())
            .reduce((a, b) => a + b) /
            recordsForDay.length;

        double avgSpo2 = recordsForDay
            .map((r) => (r['spo2'] as num).toDouble())
            .reduce((a, b) => a + b) /
            recordsForDay.length;

        tempTemps.add(avgTemp);
        tempBpm.add(avgBpm);
        tempSpo2.add(avgSpo2);
      } else {
        tempTemps.add(36.5);
        tempBpm.add(60);
        tempSpo2.add(95);
      }
    }

    setState(() {
      dates = tempDates;
      temperatureData = tempTemps;
      bpmData = tempBpm;
      spo2Data = tempSpo2;
      selectedDate = dates.isNotEmpty ? dates.last : "";
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    // Dynamic gradient colors based on theme
    final gradientColors = theme.brightness == Brightness.dark
        ? [Colors.blue.shade900, Colors.blue.shade800] // Dark mode gradient
        : [Colors.blue.shade50, Colors.white]; // Light mode gradient

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Health History"),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      );
    }

    int selectedIndex = dates.indexOf(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Health History"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors, // Use dynamic gradient colors
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDropdownSelector(textColor, cardColor),
              const SizedBox(height: 20),
              _buildGraph("Body Temperature (°C)", temperatureData, Colors.orange,
                  selectedIndex, 36.0, 38.0),
              const SizedBox(height: 20),
              _buildGraph("Heart Rate (BPM)", bpmData, Colors.red, selectedIndex,
                  55, 90),
              const SizedBox(height: 20),
              _buildGraph("Oxygen Level (SpO₂)", spo2Data, Colors.blue,
                  selectedIndex, 94, 98),
              const SizedBox(height: 20),
              _buildDataTable(selectedIndex, cardColor, textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownSelector(Color textColor, Color cardColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Select Date to Highlight Data",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Center(
              child: DropdownButton<String>(
                value: selectedDate,
                dropdownColor: Theme.of(context).cardColor,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedDate = newValue!;
                  });
                },
                items: dates.map((String date) {
                  return DropdownMenuItem<String>(
                    value: date,
                    child: Text(
                      date,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildLineChart(
      List<double> data, Color color, int selectedIndex, double minY, double maxY) {
    return LineChartData(
      minX: -0.5,
      maxX: data.length - 0.5,
      minY: minY,
      maxY: maxY,
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) =>
                Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index < 0 || index >= dates.length) return Container();
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Transform.rotate(
                  angle: -0.7854,
                  child: Text(dates[index], style: const TextStyle(fontSize: 12)),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.black, width: 1),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(data.length, (index) =>
              FlSpot(index.toDouble(), data[index])),
          isCurved: true,
          color: color,
          barWidth: 3,
          belowBarData: BarAreaData(show: false),
          dotData: const FlDotData(show: true),
        ),
        LineChartBarData(
          spots: [FlSpot(selectedIndex.toDouble(), data[selectedIndex])],
          isCurved: false,
          color: Colors.black,
          barWidth: 5,
          dotData: const FlDotData(show: true),
        ),
      ],
    );
  }

  Widget _buildDataTable(int index, Color cardColor, Color textColor) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Detailed Health Data",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 10),
            DataTable(
              columnSpacing: 20,
              headingRowColor: MaterialStateColor.resolveWith((states) =>
              Theme.of(context).cardColor),
              columns: [
                DataColumn(label: Text("Date", style: TextStyle(color: textColor))),
                DataColumn(label: Text("Temp (°C)", style: TextStyle(color: textColor))),
                DataColumn(label: Text("BPM", style: TextStyle(color: textColor))),
                DataColumn(label: Text("SpO₂ (%)", style: TextStyle(color: textColor))),
              ],
              rows: [
                DataRow(cells: [
                  DataCell(Text(dates[index], style: TextStyle(color: textColor))),
                  DataCell(Text(temperatureData[index].toStringAsFixed(1), style: TextStyle(color: textColor))),
                  DataCell(Text(bpmData[index].toStringAsFixed(0), style: TextStyle(color: textColor))),
                  DataCell(Text(spo2Data[index].toStringAsFixed(0), style: TextStyle(color: textColor))),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraph(String title, List<double> data, Color color, int selectedIndex, double minY, double maxY) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              width: double.infinity,
              child: LineChart(_buildLineChart(data, color, selectedIndex, minY, maxY)),
            ),
          ],
        ),
      ),
    );
  }
}