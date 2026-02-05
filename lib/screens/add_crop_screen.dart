/import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/crop_model.dart';
import '../models/field_model.dart'; 
import '../services/api_service.dart';

class AddCropScreen extends StatefulWidget {
  @override
  _AddCropScreenState createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final ApiService service = ApiService();
  final _nameController = TextEditingController();
  final _statusController = TextEditingController();
  
  String? _selectedImage; 
  int? _userId;

  // Variables for Fields
  List<Field> _fields = [];
  int? _selectedFieldId;
  bool _isFetchingFields = true;

  final List<String> _cropImages = [
    'bisbas.jpg', 'cambo.jpg', 'digir_cagaar.jpg', 'digir_gaduud.jpg',
    'galey.jpg', 'moos.jpg', 'qamadi.jpg', 'rice.jpg', 'sisin.jpg'
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id') ?? prefs.getInt('id');
    });
    _loadFarmerFields();
  }

  Future<void> _loadFarmerFields() async {
    try {
      // Tani waxay soo celisaa beerihii u gaarka ahaa Farmer-ka (user_id: 36)
      final data = await service.getFields(); 
      setState(() {
        _fields = data;
        if (_fields.isNotEmpty) {
          _selectedFieldId = _fields.first.id;
        }
        _isFetchingFields = false;
      });
    } catch (e) {
      setState(() => _isFetchingFields = false);
      _showSnackBar("Khalad ayaa ka dhacay soo kicinta beeraha", Colors.red);
    }
  }

  void _saveCrop() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar("Fadlan geli magaca dalagga", Colors.orange);
      return;
    }
    
    if (_selectedFieldId == null) {
      _showSnackBar("Fadlan marka hore sameey beer (Field)", Colors.red);
      return;
    }

    if (_selectedImage == null) {
      _showSnackBar("Fadlan dooro mid ka mid ah sawirrada hoose", Colors.red);
      return;
    }

    final newCrop = Crop(
      name: _nameController.text.trim(),
      status: _statusController.text.trim().isEmpty ? "Healthy" : _statusController.text.trim(),
      image: _selectedImage!,
      userId: _userId ?? 0,
      fieldId: _selectedFieldId!, 
    );

    bool success = await service.addCrop(newCrop);
    if (success) {
      if (mounted) Navigator.pop(context, true);
    } else {
      _showSnackBar("Waan ka xunnahay, xogta lama kaydin.", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Add New Crop", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF15803D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isFetchingFields 
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _fields.isEmpty 
              ? _buildEmptyFieldsView() 
              : _buildAddCropForm(),
    );
  }

  // Haddii aanay beer jirin, kan ayaa u soo baxaya
  Widget _buildEmptyFieldsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              "Fadlan marka hore sameey beer (Field)", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text("Si aad dalag u darto, waa inaad haysataa beer u diiwaangashan."),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add-field'),
              icon: const Icon(Icons.add_location, color: Colors.white),
              label: const Text("Abuur Beer Cusub", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
            )
          ],
        ),
      ),
    );
  }

  // Foomka lagu darayo dalagga
  Widget _buildAddCropForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Magaca Dalagga"),
          _buildTextField(_nameController, "Tusaale: Galey"),
          const SizedBox(height: 20),
          
          _buildLabel("Dooro Beerta:"),
          _buildFieldDropdown(),
          const SizedBox(height: 20),
          
          _buildLabel("Xaaladda (Status)"),
          _buildTextField(_statusController, "Tusaale: Healthy"),
          const SizedBox(height: 25),
          
          Text(
            "Dooro Sawirka Dalagga:", 
            style: TextStyle(fontWeight: FontWeight.bold, color: _selectedImage == null ? Colors.red : Colors.green)
          ),
          const SizedBox(height: 15),
          _buildImageGrid(),
          const SizedBox(height: 40),
          
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  Widget _buildTextField(TextEditingController controller, String hint) => TextField(
    controller: controller,
    decoration: InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true, fillColor: Colors.white,
    ),
  );

  Widget _buildFieldDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedFieldId,
          isExpanded: true,
          items: _fields.map((field) => DropdownMenuItem(
            value: field.id,
            child: Text(field.name),
          )).toList(),
          onChanged: (val) => setState(() => _selectedFieldId = val),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
      ),
      itemCount: _cropImages.length,
      itemBuilder: (context, index) {
        String img = _cropImages[index];
        bool isSelected = _selectedImage == img;
        return GestureDetector(
          onTap: () => setState(() => _selectedImage = img),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300, width: isSelected ? 4 : 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset("assets/$img", fit: BoxFit.cover),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF15803D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: _saveCrop,
        child: const Text("Save Crop", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}/ halkaan soo dhig koodhkaaga Dart ee faylka lib/screens/add_crop_screen.dart