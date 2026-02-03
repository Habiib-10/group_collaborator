import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for input formatters
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
  List<dynamic> _farmers = []; 
  int? _selectedFarmerId;

  @override
  void initState() {
    super.initState();
    _fetchFarmers();
  }

  Future<void> _fetchFarmers() async {
    try {
      final data = await service.getFarmers();
      setState(() {
        _farmers = data;
      });
    } catch (e) {
      debugPrint("Error fetching farmers: $e");
    }
  }

  // --- FIXED SAVE FUNCTION ---
  void _saveField() async {
    // 1. Clean the price input (Replace comma with dot for calculation)
    String cleanPrice = _priceController.text.trim().replaceAll(',', '.');
    double? parsedPrice = double.tryParse(cleanPrice);

    // 2. Validation
    if (_nameController.text.trim().isEmpty || 
        _sizeController.text.trim().isEmpty || 
        _selectedFarmerId == null ||
        parsedPrice == null || parsedPrice <= 0) {
      _showSnackBar("Please enter name, size, and a valid price (> 0)!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final newField = Field(
      name: _nameController.text.trim(),
      location: _locationController.text.trim().isEmpty ? "N/A" : _locationController.text.trim(),
      size: _sizeController.text.trim(), 
      status: "Active",
      price: parsedPrice, // Fixed price value
      userId: _selectedFarmerId!, 
    );

    bool success = await service.addField(newField);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _showSnackBar("Field successfully assigned and Assets updated!", Colors.green);
        // Important: Return 'true' to trigger refresh on Dashboard
        Future.delayed(const Duration(milliseconds: 600), () => Navigator.pop(context, true));
      } else {
        _showSnackBar("Server Error: Check your backend connection.", Colors.red);
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
                  _buildLabel("Price (USD \$)"),
                  _buildTextField(_priceController, "0.00", Icons.attach_money, isNumber: true),
                  
                  const SizedBox(height: 35),
                  _buildSubmitButton(),
                ],
              ),
            ),
    );
  }

  // --- UI COMPONENTS ---

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
              child: Text(farmer['name'] ?? "Unknown"),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedFarmerId = val),
        ),
      ),
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
        // Shows the numeric keyboard with decimal point
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        // Prevents entering letters in the price field
        inputFormatters: isNumber ? [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ] : [],
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
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
}