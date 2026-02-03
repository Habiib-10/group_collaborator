import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/field_model.dart';
import '../services/api_service.dart';

class EditFieldScreen extends StatefulWidget {
  final Field field;

  const EditFieldScreen({Key? key, required this.field}) : super(key: key);

  @override
  _EditFieldScreenState createState() => _EditFieldScreenState();
}

class _EditFieldScreenState extends State<EditFieldScreen> {
  final ApiService service = ApiService();
  late TextEditingController _nameController;
  late TextEditingController _sizeController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late String _selectedStatus;
  
  int? _currentUserId;
  bool _isLoading = false;

  final List<String> _statusOptions = ["Active", "Preparing", "Harvested"];

  @override
  void initState() {
    super.initState();
    _loadUserSession();
    _nameController = TextEditingController(text: widget.field.name);
    _sizeController = TextEditingController(text: widget.field.size);
    _locationController = TextEditingController(text: widget.field.location);
    _priceController = TextEditingController(text: widget.field.price.toString());
    _selectedStatus = widget.field.status;
  }

  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('user_id') ?? prefs.getInt('id');
    });
  }

  // --- 1. Habka Tirtirista (Delete Logic) ---
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ma hubtaa?"),
        content: const Text("Beertan iyo dhammaan dalagyada ku jira waa la tirtiri doonaa."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Maya")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              bool success = await service.deleteField(widget.field.id!);
              if (success && mounted) Navigator.pop(context, true);
            },
            child: const Text("Haa, Tirtir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- 2. Habka Cusboonaysiinta (Update Logic) ---
  void _updateField() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      _showSnackBar("Fadlan buuxi meelaha bannaan", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final updatedField = Field(
      id: widget.field.id,
      name: _nameController.text.trim(),
      location: _locationController.text.trim(),
      size: _sizeController.text.trim(),
      status: _selectedStatus,
      price: double.tryParse(_priceController.text) ?? 0.0,
      userId: _currentUserId!,
    );

    bool success = await service.updateField(widget.field.id!, updatedField);
    setState(() => _isLoading = false);

    if (success && mounted) {
      _showSnackBar("Beerta waa la cusboonaysiiyey!", Colors.green);
      Navigator.pop(context, true);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wax ka beddel Beerta"),
        backgroundColor: const Color(0xFF15803D),
        actions: [
          IconButton(icon: const Icon(Icons.delete_forever), onPressed: _confirmDelete),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInput("Magaca Beerta", _nameController, Icons.landscape),
                  _buildInput("Goobta (Location)", _locationController, Icons.map),
                  _buildInput("Baaxadda (Size)", _sizeController, Icons.straighten),
                  _buildInput("Qiimaha (\$)", _priceController, Icons.attach_money, isNumber: true),
                  const SizedBox(height: 15),
                  const Text("Xaaladda", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _selectedStatus = val!),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D)),
                      onPressed: _updateField,
                      child: const Text("Cusboonaysii", style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}