/import 'package:flutter/material.dart';
import '../models/field_model.dart';
import '../services/api_service.dart';

class AddFieldScreen extends StatefulWidget {
  @override
  _AddFieldScreenState createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends State<AddFieldScreen> {
  final ApiService service = ApiService();
  
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _sizeController = TextEditingController();
  final _priceController = TextEditingController();
  
  bool _isLoading = false;
  List<dynamic> _farmers = []; // List to store farmers from DB
  int? _selectedFarmerId; // The ID of the farmer chosen by Admin

  @override
  void initState() {
    super.initState();
    _fetchFarmers(); // Fetch the list of farmers when screen opens
  }

  // Fetch only users with the role 'Farmer'
  Future<void> _fetchFarmers() async {
    try {
      final data = await service.getFarmers(); // You need to add this to ApiService
      setState(() {
        _farmers = data;
      });
    } catch (e) {
      print("Error fetching farmers: $e");
    }
  }

  void _saveField() async {
    if (_nameController.text.trim().isEmpty || 
        _sizeController.text.trim().isEmpty || 
        _selectedFarmerId == null) {
      _showSnackBar("Please fill name, size, and select a farmer!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final newField = Field(
      name: _nameController.text.trim(),
      location: _locationController.text.trim().isEmpty ? "N/A" : _locationController.text.trim(),
      size: _sizeController.text.trim(), 
      status: "Active",
      price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      userId: _selectedFarmerId!, // Assigned to the selected Farmer
    );

    bool success = await service.addField(newField);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _showSnackBar("Field successfully assigned to farmer", Colors.green);
        Future.delayed(Duration(milliseconds: 500), () => Navigator.pop(context, true));
      } else {
        _showSnackBar("Server rejected the request.", Colors.red);
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Assign New Field", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF629749),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF629749)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderIcon(),
                  const SizedBox(height: 20),
                  
                  _buildLabel("Select Farmer"),
                  _buildFarmerDropdown(),
                  
                  const SizedBox(height: 15),
                  _buildLabel("Field Name"),
                  _buildTextField(_nameController, "e.g. Shabelle Farm", Icons.landscape),
                  
                  const SizedBox(height: 15),
                  _buildLabel("Location"),
                  _buildTextField(_locationController, "e.g. Afgooye", Icons.location_on),
                  
                  const SizedBox(height: 15),
                  _buildLabel("Size"),
                  _buildTextField(_sizeController, "e.g. 10 Hectares", Icons.straighten),
                  
                  const SizedBox(height: 15),
                  _buildLabel("Price (\$)"),
                  _buildTextField(_priceController, "Price for the farmer", Icons.attach_money, isNumber: true),
                  
                  const SizedBox(height: 35),
                  _buildSubmitButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildFarmerDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedFarmerId,
          hint: const Text("Choose a Farmer"),
          isExpanded: true,
          items: _farmers.map((farmer) {
            return DropdownMenuItem<int>(
              value: farmer['id'],
              child: Text(farmer['name']),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedFarmerId = val),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Center(
      child: CircleAvatar(
        radius: 40,
        backgroundColor: const Color(0xFF629749).withOpacity(0.1),
        child: const Icon(Icons.add_business, size: 40, color: Color(0xFF629749)),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF629749),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 0,
        ),
        onPressed: _saveField,
        child: const Text("CREATE & ASSIGN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}/ halkaan soo dhig koodhkaaga Dart ee faylka lib/screens/add_field_screen.dart