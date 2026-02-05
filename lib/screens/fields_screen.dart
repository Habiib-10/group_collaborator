/import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/field_model.dart';

class FieldsScreen extends StatefulWidget {
  @override
  _FieldsScreenState createState() => _FieldsScreenState();
}

class _FieldsScreenState extends State<FieldsScreen> {
  final ApiService service = ApiService();
  int? _userId;
  String? _userRole;
  bool _isProcessing = false;
  
  // Track if any purchase happened to notify Dashboard on exit
  bool _anyPurchaseMade = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id');
      _userRole = prefs.getString('role') ?? "Farmer";
    });
  }

  // --- Logic to handle purchase with confirmation ---
  Future<void> _handlePurchase(Field field) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Purchase"),
        content: Text("Are you sure you want to buy ${field.name} for \$${field.price.toStringAsFixed(2)}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Buy", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    bool success = await service.purchaseField(field.id!, _userId!);
    
    if (success) {
      _anyPurchaseMade = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Success! You now own ${field.name}"), backgroundColor: Colors.green),
      );
      
      // Markay iibsi dhacdo, halkan ayaan setState ku sameynaynaa si liiska loo refresh gareeyo
      setState(() {
        _isProcessing = false;
      }); 
    } else {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Purchase failed. Try again."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _anyPurchaseMade) {
          // Haddii uu qofku iibsi sameeyey, Dashboard-ka u sheeg inuu refresh gareeyo
          // Tani waxay saxaysaa in 'My Assets Value' uu isla markiiba isbeddelo
          Navigator.pop(context, true); 
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text("Farm Marketplace", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Markii uu qofku riixo badanka dib u laabashada ee AppBar-ka
              Navigator.pop(context, _anyPurchaseMade);
            },
          ),
        ),
        body: _isProcessing 
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: FutureBuilder<List<Field>>(
                future: service.getFields(), 
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.green));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error loading fields: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No fields available in the system."));
                  }

                  List<Field> displayFields = snapshot.data!;
                  if (_userRole != "Admin") {
                    displayFields = snapshot.data!.where((f) => 
                      f.userId == _userId || f.userId == 0 || f.userId == null
                    ).toList();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: displayFields.length,
                    itemBuilder: (context, index) {
                      final field = displayFields[index];
                      return _fieldCard(field);
                    },
                  );
                },
              ),
            ),
      ),
    );
  }

  Widget _fieldCard(Field field) {
    bool isOwnedByMe = field.userId == _userId;
    bool isAvailable = field.userId == 0 || field.userId == null;
    Color statusColor = isAvailable ? Colors.blue : _getStatusColor(field.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.terrain, color: statusColor, size: 28),
              ),
              title: Text(
                field.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              subtitle: Text("${field.location} • ${field.size}"),
              trailing: Text(
                "\$${field.price.toStringAsFixed(2)}",
                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAvailable ? "AVAILABLE" : field.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                
                if (isAvailable && _userRole == "Farmer")
                  ElevatedButton(
                    onPressed: () => _handlePurchase(field),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Buy Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                else if (isOwnedByMe)
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 6),
                      Text("Purchased", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  )
                else if (!isAvailable && !isOwnedByMe && _userRole == "Admin")
                  Text("Owner ID: ${field.userId}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "active": return Colors.green;
      case "preparing": return Colors.orange;
      case "dry": return Colors.red;
      default: return Colors.blue;
    }
  }
}/ halkaan soo dhig koodhkaaga Dart ee faylka lib/screens/fields_screen.dart