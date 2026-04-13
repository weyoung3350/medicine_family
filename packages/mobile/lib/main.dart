import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/elder_mode_provider.dart';
import 'core/providers/family_provider.dart';
import 'core/providers/medicine_provider.dart';
import 'core/providers/medication_provider.dart';
import 'core/providers/medical_record_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/pharmacy_provider.dart';
import 'core/providers/ai_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MedicineFamilyApp());
}

class MedicineFamilyApp extends StatelessWidget {
  const MedicineFamilyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ElderModeProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => MedicalRecordProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => PharmacyProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: '家庭健康管家',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            home: auth.isLoggedIn ? HomeScreen(key: homeScreenKey) : const LoginScreen(),
          );
        },
      ),
    );
  }
}
