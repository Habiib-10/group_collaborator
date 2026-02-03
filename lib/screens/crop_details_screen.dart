import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../services/api_service.dart';

class CropDetailsScreen extends StatefulWidget {
  final Crop crop;

  CropDetailsScreen({required this.crop});

  @override
  _CropDetailsScreenState createState() => _CropDetailsScreenState();
}

class _CropDetailsScreenState extends State<CropDetailsScreen> {
  final ApiService _apiService = ApiService();
  late String _currentStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.crop.status; // Get status from the model
  }

  // Function to update status in the database
  void _updateStatus(String? newStatus) async {
    if (newStatus == null) return;

    setState(() => _isUpdating = true);

    // Create updated crop object
    Crop updatedCrop = Crop(
      id: widget.crop.id,
      name: widget.crop.name,
      status: newStatus,
      userId: widget.crop.userId,
      fieldId: widget.crop.fieldId,
      image: widget.crop.image,
    );

    bool success = await _apiService.updateCrop(widget.crop.id!, updatedCrop);

    if (mounted) {
      setState(() => _isUpdating = false);
      if (success) {
        setState(() => _currentStatus = newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Status updated to $newStatus"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed!"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color matchaGreen = Color(0xFF629749);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.crop.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: matchaGreen,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Image/Icon
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 140,
                    width: 140,
                    decoration: BoxDecoration(
                      color: matchaGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(Icons.eco_rounded, size: 80, color: matchaGreen),
                  if (_isUpdating) CircularProgressIndicator(color: matchaGreen),
                ],
              ),
            ),
            SizedBox(height: 40),
            
            _buildSectionTitle("General Information"),
            _buildDetailTile("Crop Name", widget.crop.name, Icons.label_important_outline, matchaGreen),
            
            // Editable Status Dropdown
            _buildStatusPicker(matchaGreen),

            SizedBox(height: 20),
            _buildSectionTitle("Field & Growth"),
            _buildDetailTile("Field ID", "Field #${widget.crop.fieldId}", Icons.map_outlined, matchaGreen),
            
            SizedBox(height: 30),
            _buildSectionTitle("Maturity Progress"),
            SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 0.75, // Static example: 75%
                backgroundColor: Colors.grey[200],
                color: matchaGreen,
                minHeight: 12,
              ),
            ),
            SizedBox(height: 8),
            Text("75% - Ready to harvest soon", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            
            SizedBox(height: 40),
            // Delete Button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                   // Add delete logic here if needed
                },
                icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                label: Text("Remove Crop Record", style: TextStyle(color: Colors.redAccent)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800], letterSpacing: 1)),
    );
  }

  Widget _buildStatusPicker(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.health_and_safety_outlined, color: themeColor),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Health Status (Tap to change)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                DropdownButton<String>(
                  value: _currentStatus,
                  isExpanded: true,
                  underline: SizedBox(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  items: ["Healthy", "Needs Water", "Pest Issue", "Harvested"]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: _updateStatus,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, IconData icon, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: themeColor),
          SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}