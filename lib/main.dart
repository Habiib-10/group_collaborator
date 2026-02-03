import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Use package imports to avoid "file not found" errors
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_crop_screen.dart';
import 'screens/add_field_screen.dart';
import 'screens/weather_screen.dart';
import 'screens/user_list_screen.dart'; 

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isDark = prefs.getBool('isDark') ?? false;
  
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const SmartFarmingApp());
}

class SmartFarmingApp extends StatelessWidget {
  const SmartFarmingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Smart Farming System',
          debugShowCheckedModeBanner: false,
          
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.dark,
            ),
          ),

          initialRoute: '/',
          routes: {
            // REMOVED 'const' from constructors below
            '/': (context) => LoginScreen(),
            '/register': (context) => RegisterScreen(),
            '/dashboard': (context) => DashboardScreen(),
            '/add-crop': (context) => AddCropScreen(),
            '/add-field': (context) => AddFieldScreen(),
            '/weather': (context) => WeatherScreen(),
            '/user-list': (context) => UserListScreen(), 
          },
        );
      },
    );
  }
}