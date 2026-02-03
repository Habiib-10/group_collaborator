
import 'package:flutter/material.dart';
import '../models/crop_model.dart';

class CropCard extends StatelessWidget {
  final Crop crop;
  final VoidCallback onDelete;

  CropCard({required this.crop, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Icon(Icons.eco, color: Colors.green),
        title: Text(crop.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Status: ${crop.status}"),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}