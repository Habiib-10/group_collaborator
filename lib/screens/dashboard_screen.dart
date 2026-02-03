import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/crop_model.dart';
import '../models/field_model.dart';
import 'add_crop_screen.dart';
import 'edit_crop_screen.dart';
import 'fields_screen.dart';
import 'profile_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'add_field_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService service = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Crop> _allCrops = [];
  List<Crop> _filteredCrops = [];
  List<Field> _allFields = [];
  List<dynamic> _allUsers = []; 
  bool _isLoading = true;
  
  String userName = "User";
  String userEmail = "user@smartfarm.com";
  String _userRole = "Farmer"; 
  int _currentUserId = 0;

  double _temp = 0.0;
  String _condition = "Loading...";
  bool _isWeatherLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserData();
    _refreshData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? "User";
      userEmail = prefs.getString('email') ?? "user@smartfarm.com";
      _userRole = prefs.getString('role') ?? "Farmer";
      _currentUserId = prefs.getInt('user_id') ?? prefs.getInt('id') ?? 0;
    });
  }

  void _refreshData() {
    setState(() => _isLoading = true);
    _fetchCrops();
    _fetchFields();
    _fetchLiveWeather();
    if (_userRole == "Admin") _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await service.getAllUsers();
      setState(() => _allUsers = users);
    } catch (e) {
      debugPrint("User Fetch Error: $e");
    }
  }

  Future<void> _fetchCrops() async {
    try {
      final crops = await service.getCrops();
      setState(() {
        _allCrops = _userRole == "Admin" 
            ? crops 
            : crops.where((c) => c.userId == _currentUserId).toList();
        _filteredCrops = _allCrops;
      });
    } catch (e) {
      debugPrint("Crop Error: $e");
    }
  }

  Future<void> _fetchFields() async {
    try {
      final fields = await service.getFields();
      setState(() {
        _allFields = fields;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLiveWeather() async {
    try {
      final data = await service.getWeatherData("Mogadishu");
      if (data.isNotEmpty) {
        setState(() {
          _temp = data['main']['temp'].toDouble();
          _condition = data['weather'][0]['main'];
          _isWeatherLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isWeatherLoading = false);
    }
  }

  double calculateTotalAssets(List<Field> fields) {
    return fields.fold(0, (sum, item) => sum + (item.price ?? 0.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 900;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8FAFC),
          drawer: isDesktop ? null : _buildSidebar(context),
          body: Row(
            children: [
              if (isDesktop) _buildSidebar(context),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _refreshData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(isDesktop ? 30 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(isDesktop),
                        const SizedBox(height: 30),
                        _buildHeroStats(isDesktop), 
                        const SizedBox(height: 40),
                        _buildSectionHeader(context),
                        const SizedBox(height: 20),
                        _buildCropsGrid(isDesktop),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF15803D),
            onPressed: () async {
              final res = await Navigator.push(context, MaterialPageRoute(builder: (c) => AddCropScreen()));
              if (res == true) _refreshData();
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("New Crop", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  // --- STAT CARDS SECTION ---
  Widget _buildHeroStats(bool isDesktop) {
    final myFields = _userRole == "Admin" 
        ? _allFields 
        : _allFields.where((f) => f.userId == _currentUserId).toList();

    double totalValue = calculateTotalAssets(myFields);

    return Wrap(
      spacing: 20, runSpacing: 20,
      children: [
        _statCard(_userRole == "Admin" ? "Global Crops" : "My Crops", "${_allCrops.length}", Icons.eco, Colors.green),
        _statCard(_userRole == "Admin" ? "Total Fields" : "My Fields", "${myFields.length}", Icons.map, Colors.orange),
        if (_userRole == "Admin")
          _statCard("Total Users", "${_allUsers.length}", Icons.people, Colors.purple),
        _statCard(_userRole == "Admin" ? "System Value" : "My Assets", "\$${totalValue.toStringAsFixed(2)}", Icons.account_balance_wallet, Colors.blueAccent), 
        _weatherCard(isDesktop),
      ],
    );
  }

  Widget _statCard(String title, String val, IconData icon, Color col) {
    return Container(
      width: 220, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: col, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- TOP BAR & SEARCH ---
  Widget _buildTopBar(bool isDesktop) {
    return Row(
      children: [
        if (!isDesktop)
          IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {
                _filteredCrops = _allCrops.where((c) => c.name.toLowerCase().contains(v.toLowerCase())).toList();
              }),
              decoration: const InputDecoration(icon: Icon(Icons.search), hintText: "Search crops...", border: InputBorder.none),
            ),
          ),
        ),
      ],
    );
  }

  Widget _weatherCard(bool isDesktop) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/weather'),
      child: Container(
        width: isDesktop ? 300 : double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF334155)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(_isWeatherLoading ? "--°C" : "${_temp.toInt()}°C", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text("Mogadishu", style: TextStyle(color: Colors.white70)),
                  Text(_condition, style: const TextStyle(color: Colors.greenAccent, fontSize: 12), overflow: TextOverflow.ellipsis),
                ]
              ),
            ),
            Icon(_condition.contains("Cloud") ? Icons.cloud : Icons.wb_sunny, color: Colors.yellow, size: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            _userRole == "Admin" ? "Admin Management" : "My Farming", 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), 
          )
        ),
        if (_userRole == "Admin")
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddFieldScreen()));
              if (result == true) _refreshData(); 
            }, 
            icon: const Icon(Icons.add_location, size: 18),
            label: const Text("New Field", style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            ),
          ),
      ],
    );
  }

  // --- CROPS GRID WITH OVERFLOW FIXES ---
  Widget _buildCropsGrid(bool isDesktop) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_filteredCrops.isEmpty) return const Center(child: Text("No crops found."));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 2 : 1,
        childAspectRatio: isDesktop ? 3.5 : 3.2,
        mainAxisSpacing: 15, crossAxisSpacing: 15,
      ),
      itemCount: _filteredCrops.length,
      itemBuilder: (context, index) {
        final crop = _filteredCrops[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(16), 
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
          ),
          child: Row(
            children: [
              _buildCropImage(crop),
              const SizedBox(width: 15),
              // --- FIXED: Expanded Column to prevent horizontal overflow ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Text(
                      crop.name, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), 
                      overflow: TextOverflow.ellipsis
                    ),
                    Text(
                      crop.status, 
                      style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis
                    ),
                  ]
                ),
              ),
              _buildActionButtons(crop),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCropImage(Crop crop) {
    String? imgName = crop.image?.replaceAll('assets/', '').trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imgName != null && imgName.isNotEmpty
          ? Image.asset("assets/$imgName", width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => _errorIcon())
          : _errorIcon(),
    );
  }

  Widget _errorIcon() {
    return Container(width: 60, height: 60, color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported, color: Colors.grey));
  }

  // --- ACTION BUTTONS WITH MIN SIZE FIX ---
  Widget _buildActionButtons(Crop crop) {
    bool canManage = (_userRole == "Admin") || (crop.userId == _currentUserId);
    return Row(
      mainAxisSize: MainAxisSize.min, // Essential for Row inside Row
      children: [
        if (canManage) 
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            icon: const Icon(Icons.edit, color: Colors.blue, size: 20), 
            onPressed: () async {
              final res = await Navigator.push(context, MaterialPageRoute(builder: (c) => EditCropScreen(crop: crop)));
              if (res == true) _refreshData();
            }
          ),
        if (canManage) 
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), 
            onPressed: () => _deleteCrop(crop.id!)
          ),
      ],
    );
  }

  void _deleteCrop(int id) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Crop"),
        content: const Text("Are you sure you want to delete this crop?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      setState(() => _isLoading = true);
      final success = await service.deleteCrop(id);
      if (success) {
        _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Crop deleted successfully")));
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete crop"), backgroundColor: Colors.red));
      }
    }
  }

  void _handleLogout() async {
    await service.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  // --- SIDEBAR SECTION ---
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 270,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          _buildSidebarHeader(),
          const Divider(color: Colors.white10),
          _sidebarItem(Icons.grid_view, "Dashboard", active: true),
          _sidebarItem(Icons.map, "Fields", onTap: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (c) => FieldsScreen()));
            if (result == true) _refreshData();
          }),
          if (_userRole == "Admin")
            _sidebarItem(Icons.people, "Manage Users", color: Colors.orangeAccent, onTap: () => Navigator.pushNamed(context, '/user-list')),
          _sidebarItem(Icons.analytics, "Analytics", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => AnalyticsScreen()))),
          _sidebarItem(Icons.person, "Profile", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ProfileScreen()))),
          _sidebarItem(Icons.settings, "Settings", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => SettingsScreen()))),
          const Spacer(),
          _sidebarItem(Icons.logout, "Logout", color: Colors.redAccent, onTap: _handleLogout),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _userRole == "Admin" ? Colors.orange : Colors.green, 
            child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : "U", style: const TextStyle(color: Colors.white))
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text("$_userRole | $userEmail", style: const TextStyle(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, {bool active = false, Color color = Colors.white70, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: active ? Colors.green : color),
      title: Text(title, style: TextStyle(color: active ? Colors.white : color)),
    );
  }
}