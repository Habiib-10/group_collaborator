import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  void _fetchWeather() async {
    final data = await _apiService.getWeatherData("Mogadishu");
    setState(() {
      _weatherData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Extracting data from JSON
    double temp = _weatherData?['main']?['temp']?.toDouble() ?? 0.0;
    int humidity = _weatherData?['main']?['humidity'] ?? 0;
    String condition = _weatherData?['weather']?[0]?['main']?.toUpperCase() ?? "UNKNOWN";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Live Farm Weather", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade900, Colors.blue.shade900],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 100),
            Text(_weatherData?['name'] ?? "Location", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const Text("Live Updates", style: TextStyle(color: Colors.white70)),
            
            const SizedBox(height: 30),
            Icon(_getWeatherIcon(condition), color: Colors.yellow, size: 80),
            Text("${temp.toInt()}°C", style: TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.w200)),
            Text(condition, style: TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2)),

            const SizedBox(height: 30),
            _buildWeatherDetails(humidity, _weatherData?['wind']?['speed']?.toString() ?? "0"),

            // The Advice logic now uses REAL data
            _buildFarmingInsight(temp, humidity),

            const Spacer(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    if (condition.contains("CLOUD")) return Icons.cloud;
    if (condition.contains("RAIN")) return Icons.umbrella;
    return Icons.wb_sunny;
  }

  // Reuse your previous _buildFarmingInsight and _buildWeatherDetails widgets here...
  Widget _buildFarmingInsight(double temp, int hum) {
    String advice;
    IconData adviceIcon;

    if (temp > 30) {
      advice = "Warning: High evaporation. Water crops deeply today.";
      adviceIcon = Icons.warning_amber_rounded;
    } else if (hum > 80) {
      advice = "High moisture: Watch for leaf mold and pests.";
      adviceIcon = Icons.bug_report;
    } else {
      advice = "Optimal conditions for planting and fertilization.";
      adviceIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Icon(adviceIcon, color: Colors.greenAccent),
        title: Text("Farmer's Advice", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(advice, style: TextStyle(color: Colors.white70)),
      ),
    );
  }

  Widget _buildWeatherDetails(int hum, String wind) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _detailTile(Icons.water_drop, "Humidity", "$hum%"),
        _detailTile(Icons.air, "Wind", "$wind km/h"),
      ],
    );
  }

  Widget _detailTile(IconData icon, String label, String val) {
    return Column(children: [Icon(icon, color: Colors.white70), Text(val, style: TextStyle(color: Colors.white)), Text(label, style: TextStyle(color: Colors.white54, fontSize: 12))]);
  }
}