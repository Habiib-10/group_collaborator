import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/crop_model.dart';
import '../models/field_model.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ApiService service = ApiService();
  int? _userId;
  String? _userRole;
  
  late Future<List<Crop>> _cropsFuture;
  late Future<List<Field>> _fieldsFuture;

  @override
  void initState() {
    super.initState();
    _loadUser();
    // Waxaan bilaabaynaa soo kicinta xogta isla bilowga
    _cropsFuture = service.getCrops();
    _fieldsFuture = service.getFields();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id');
      _userRole = prefs.getString('role') ?? "Farmer";
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F1),
      appBar: AppBar(
        title: const Text("Farm Analytics", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: FutureBuilder(
        future: Future.wait([_cropsFuture, _fieldsFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          if (!snapshot.hasData || snapshot.hasError) {
            return const Center(child: Text("Cilad ayaa dhacday ama xog lama helin."));
          }

          List<Crop> allCrops = snapshot.data![0] as List<Crop>;
          List<Field> allFields = snapshot.data![1] as List<Field>;

          // Filter xogta: Haddii uu Admin yahay dhammaan, haddii kale isaga kaliya
          List<Crop> userCrops = _userRole == "Admin" 
              ? allCrops 
              : allCrops.where((c) => c.userId == _userId).toList();
          
          List<Field> userFields = _userRole == "Admin" 
              ? allFields 
              : allFields.where((f) => f.userId == _userId).toList();

          if (userCrops.isEmpty && userFields.isEmpty) {
            return const Center(child: Text("Ma jirto xog analytics ah oo kuu diidwaangashan."));
          }

          // Xisaabinta Qiimaha (Asset Value)
          double totalFieldVal = userFields.fold(0.0, (sum, item) => sum + (item.price ?? 0.0));
          
          // Xisaabinta Caafimaadka Dalagga
          int healthy = userCrops.where((c) => c.status.toLowerCase() == "healthy").length;
          int dry = userCrops.where((c) => c.status.toLowerCase() == "dry").length;
          int alert = userCrops.length - (healthy + dry);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFinancialHeader(totalFieldVal, userFields.length),
                const SizedBox(height: 25),
                const Text("Asset Value Growth", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildLineChart(userFields, isDark),
                const SizedBox(height: 30),
                const Text("Crop Health Distribution", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildLegend(),
                const SizedBox(height: 15),
                _buildFancyPieChart(healthy, dry, alert, isDark),
                const SizedBox(height: 30),
                _buildFancyBarChart(healthy, dry, alert, isDark),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinancialHeader(double totalVal, int fieldCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF166534)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Text("Total Asset Value", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text("\$${totalVal.toStringAsFixed(2)}", 
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("$fieldCount Fields Owned", style: const TextStyle(color: Colors.white60, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<Field> fields, bool isDark) {
    // Iska ilaali inuu chart-ku crash-gareeyo haddii fields ay eber yihiin
    if (fields.isEmpty) return const SizedBox(height: 100, child: Center(child: Text("No fields to chart")));

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: fields.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.price.toDouble())).toList(),
              isCurved: true,
              color: Colors.greenAccent,
              barWidth: 4,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.greenAccent.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _indicator(Colors.green, "Healthy"),
        const SizedBox(width: 15),
        _indicator(Colors.orange, "Dry"),
        const SizedBox(width: 15),
        _indicator(Colors.redAccent, "Alert"),
      ],
    );
  }

  Widget _indicator(Color color, String text) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildFancyPieChart(int healthy, int dry, int alert, bool isDark) {
    if ((healthy + dry + alert) == 0) return const Center(child: Text("No crop data"));

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 5,
          centerSpaceRadius: 40,
          sections: [
            if (healthy > 0) PieChartSectionData(value: healthy.toDouble(), color: Colors.green, title: '$healthy', radius: 50, titleStyle: _chartStyle()),
            if (dry > 0) PieChartSectionData(value: dry.toDouble(), color: Colors.orange, title: '$dry', radius: 50, titleStyle: _chartStyle()),
            if (alert > 0) PieChartSectionData(value: alert.toDouble(), color: Colors.redAccent, title: '$alert', radius: 50, titleStyle: _chartStyle()),
          ],
        ),
      ),
    );
  }

  Widget _buildFancyBarChart(int h, int d, int a, bool isDark) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            _makeGroup(0, h.toDouble(), Colors.green),
            _makeGroup(1, d.toDouble(), Colors.orange),
            _makeGroup(2, a.toDouble(), Colors.redAccent),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeGroup(int x, double y, Color color) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: y, color: color, width: 25, borderRadius: BorderRadius.circular(4))
    ]);
  }

  TextStyle _chartStyle() => const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14);
}