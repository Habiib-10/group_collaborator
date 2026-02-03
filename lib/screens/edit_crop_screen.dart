import 'package:flutter/material.dart';
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
    
    // Hubi in sawirka hore looga saaro 'assets/' si uu ugu dhigmo liiska _availableImages
    String cleanImg = widget.crop.image?.replaceAll("assets/", "").trim() ?? "";
    _selectedImage = _availableImages.contains(cleanImg) ? cleanImg : _availableImages[0];
    
    _loadUser(); 
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('user_id') ?? prefs.getInt('id');
    });
  }

  void _updateData() async {
    if (_isLoading) return; // Jooji haddii uu hore u socday
    FocusManager.instance.primaryFocus?.unfocus();

    if (_nameController.text.trim().isEmpty) {
      _showMessage("Fadlan geli magaca dalagga!", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final updatedCrop = Crop(
      id: widget.crop.id,
      name: _nameController.text.trim(),
      status: _statusController.text.trim(),
      image: "assets/$_selectedImage", // Halkan ku dar assets/ marka aad kaydinayso
      userId: widget.crop.userId ?? _currentUserId ?? 0,
      fieldId: widget.crop.fieldId, 
    );

    bool success = await service.updateCrop(widget.crop.id!, updatedCrop);
    
    if (mounted) setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        _showMessage("Si guul leh ayaa loo cusboonaysiiyay", isError: false);
        Navigator.pop(context, true); 
      }
    } else {
      _showMessage("Cillad: Ma suurtagelin in la badbaadiyo!", isError: true);
    }
  }

  void _deleteCrop() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xaqiijin"),
        content: const Text("Ma hubtaa inaad tirtirto dalaggan?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Maya")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Haa, Tirtir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => _isLoading = true);
      bool success = await service.deleteCrop(widget.crop.id!);
      
      if (mounted) setState(() => _isLoading = false);

      if (success) {
        if (mounted) {
          _showMessage("Si guul leh ayaa loo tirtiray", isError: false);
          Navigator.pop(context, true);
        }
      } else {
        _showMessage("Wuu diiday inuu tirtirmo!", isError: true);
      }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            onPressed: _isLoading ? null : _deleteCrop,
          )
        ],
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
                    height: 160, width: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
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
                const SizedBox(height: 30),
                
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                                child: Image.asset("assets/$img", width: 35, height: 35, fit: BoxFit.cover)
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(img, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedImage = val),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _updateData, 
                    child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
}