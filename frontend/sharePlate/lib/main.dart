import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/network/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/donation_provider.dart';
import 'repositories/auth_repository.dart';
import 'screens/shared/splash_screen.dart';
import 'services/auth_api_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Data & Service Layer
  final storageService = await StorageService.init();
  final apiClient = ApiClient();
  final authApiService = AuthApiService(client: apiClient);

  // Initialize Repository Layer
  final authRepository = AuthRepository(
    apiService: authApiService,
    storageService: storageService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authRepository: authRepository),
        ),
        ChangeNotifierProvider<DonationProvider>(
          create: (_) => DonationProvider(),
        ),
      ],
      child: const SharePlateApp(),
    ),
  );
}

class SharePlateApp extends StatelessWidget {
  const SharePlateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SharePlate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const SplashScreen(),
    );
  }
}