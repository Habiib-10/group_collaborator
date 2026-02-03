import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission(); 
  }

  // Layer 1: Kick out non-admins
  Future<void> _checkPermission() async {
    final prefs = await SharedPreferences.getInstance();
    String role = prefs.getString('role') ?? 'Farmer';

    if (role != 'Admin') {
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Access Denied: Only Admins can manage users."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      _fetchUsers();
    }
  }

  // FIXED: Added Debug Printing as requested
  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _apiService.getAllUsers();
      
      // DEBUG: Look at your console to see what the server is sending
      print("API Response: $users"); 

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print("Error: $e"); // Debug error if it fails
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching users: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("User Management", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("${_users.length} Total Users", 
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text("No users found.", style: TextStyle(color: Colors.grey)),
                      ElevatedButton(
                        onPressed: _fetchUsers, 
                        child: const Text("Retry Fetch")
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchUsers,
                  child: ListView.builder(
                    itemCount: _users.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      bool isAdmin = user['role'] == 'Admin';
                      
                      String initial = (user['name'] != null && user['name'].isNotEmpty) 
                          ? user['name'][0].toUpperCase() 
                          : "?";

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: isAdmin ? Colors.orange.shade100 : Colors.green.shade100,
                            child: Text(
                              initial,
                              style: TextStyle(
                                color: isAdmin ? Colors.orange.shade900 : Colors.green.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            user['name'] ?? "Unknown User",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['email'] ?? "No Email", style: TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isAdmin ? Colors.orange.shade50 : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isAdmin ? Colors.orange.shade200 : Colors.green.shade200,
                                  ),
                                ),
                                child: Text(
                                  (user['role'] ?? "User").toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isAdmin ? Colors.orange.shade800 : Colors.green.shade800,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          onTap: () {
                            // Detail logic here if needed
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}