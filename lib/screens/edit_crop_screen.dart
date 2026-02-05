/import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/crop_model.dart';

class EditCropScreen extends StatefulWidget {
  final Crop crop;
  EditCropScreen({required this.crop});

  @override
  _EditCropScreenState createState() => _EditCropScreenState();
}

class _EditCropScreenState extends State<EditCropScreen> {
  final ApiService service = ApiService();
  late TextEditingController _nameController;
  late TextEditingController _statusController;
  
  String? _selectedImage; 
  int? _currentUserId;
  bool _isLoading = false;

  final List<String> _availableImages = [
    'bisbas.jpg', 'cambo.jpg', 'digir_cagaar.jpg', 'digir_gaduud.jpg',
    'galey.jpg', 'moos.jpg', 'qamadi.jpg', 'rice.jpg', 'sisin.jpg'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.crop.name);
    _statusController = TextEditingController(text: widget.crop.status);
    _selectedImage = widget.crop.image?.replaceAll("assets/", "").trim();
    _loadUser(); 
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('user_id') ?? prefs.getInt('id');
    });
  }

  // --- UPDATE LOGIC (FIXED) ---
  void _updateData() async {
    if (_nameController.text.trim().isEmpty) {
      _showMessage("Fadlan magaca dalagga geli!", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // Halkan waxaan ku daray fieldId si loo xaliyo Error-ka Model-ka
    final updatedCrop = Crop(
      id: widget.crop.id,
      name: _nameController.text.trim(),
      status: _statusController.text.trim(),
      image: _selectedImage ?? widget.crop.image,
      userId: widget.crop.userId ?? _currentUserId ?? 0,
      fieldId: widget.crop.fieldId, // <--- CUSBOONAYSIIN MUHIIM AH
    );

    bool success = await service.updateCrop(widget.crop.id!, updatedCrop);
    
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        _showMessage("Si guul leh ayaa loo beddelay", isError: false);
        Navigator.pop(context, true); 
      }
    } else {
      _showMessage("Cilad ayaa dhacday markii la kaydinayay!", isError: true);
    }
  }

  void _showMessage(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Edit Crop Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF15803D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF15803D)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 180, width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: _selectedImage != null 
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(21),
                          child: Image.asset("assets/$_selectedImage", fit: BoxFit.cover),
                        )
                      : const Icon(Icons.image_search, size: 50, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 40),
                
                _buildLabel("Crop Name"),
                TextField(
                  controller: _nameController, 
                  decoration: _inputDecoration("Enter crop name", Icons.eco_outlined)
                ),
                
                const SizedBox(height: 20),
                
                _buildLabel("Growth Status"),
                TextField(
                  controller: _statusController, 
                  decoration: _inputDecoration("e.g. Ready for harvest", Icons.info_outline)
                ),
                
                const SizedBox(height: 20),
                
                _buildLabel("Update Image"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300), 
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedImage,
                      isExpanded: true,
                      items: _availableImages.map((img) {
                        return DropdownMenuItem(
                          value: img,
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Image.asset("assets/$img", width: 30, height: 30, fit: BoxFit.cover)
                              ),
                              const SizedBox(width: 15),
                              Text(img, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedImage = val),
                    ),
                  ),
                ),
                
                const SizedBox(height: 50),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _updateData, 
                    child: const Text("Update Crop", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.green),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green, width: 2)),
    );
  }
}/halkaan soo dhig koodhkaaga Dart ee faylka lib/screens/edit_crop_screen.dart