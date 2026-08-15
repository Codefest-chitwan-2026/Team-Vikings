import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/network/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/donation_provider.dart';
import 'providers/listing_flow_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/order_provider.dart';
import 'providers/sponsorship_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/contribution_repository.dart';
import 'repositories/donation_repository.dart';
import 'repositories/listing_flow_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/sponsorship_repository.dart';
import 'screens/shared/splash_screen.dart';
import 'services/auth_api_service.dart';
import 'services/contributions_api_service.dart';
import 'services/donations_api_service.dart';
import 'services/listing_flow_api_service.dart';
import 'services/notifications_api_service.dart';
import 'services/orders_api_service.dart';
import 'services/profile_api_service.dart';
import 'services/sponsorship_api_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Network Client & Storage Service
  final storageService = await StorageService.init();
  final apiClient = ApiClient();

  // 2. Initialize Service Layer
  final authApiService = AuthApiService(client: apiClient);
  final profileApiService = ProfileApiService(apiClient: apiClient);
  final donationsApiService = DonationsApiService(apiClient: apiClient);
  final listingFlowApiService = ListingFlowApiService(apiClient: apiClient);
  final ordersApiService = OrdersApiService(apiClient: apiClient);
  final sponsorshipApiService = SponsorshipApiService(apiClient: apiClient);
  final contributionsApiService = ContributionsApiService(apiClient: apiClient);
  final notificationsApiService = NotificationsApiService(apiClient: apiClient);

  // 3. Initialize Repository Layer
  final authRepository = AuthRepository(
    apiService: authApiService,
    storageService: storageService,
  );
  final profileRepository = ProfileRepository(apiService: profileApiService);
  final donationRepository = DonationRepository(apiService: donationsApiService);
  final listingFlowRepository = ListingFlowRepository(apiService: listingFlowApiService);
  final orderRepository = OrderRepository(apiService: ordersApiService);
  final sponsorshipRepository = SponsorshipRepository(apiService: sponsorshipApiService);
  final contributionRepository = ContributionRepository(apiService: contributionsApiService);
  final notificationRepository = NotificationRepository(apiService: notificationsApiService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            authRepository: authRepository,
            profileRepository: profileRepository,
          ),
        ),
        ChangeNotifierProvider<DonationProvider>(
          create: (_) => DonationProvider(
            donationRepository: donationRepository,
            profileRepository: profileRepository,
            contributionRepository: contributionRepository,
          ),
        ),
        ChangeNotifierProvider<OrderProvider>(
          create: (_) => OrderProvider(orderRepository: orderRepository),
        ),
        ChangeNotifierProvider<SponsorshipProvider>(
          create: (_) => SponsorshipProvider(sponsorshipRepository: sponsorshipRepository),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(notificationRepository: notificationRepository),
        ),
        ChangeNotifierProvider<ListingFlowProvider>(
          create: (_) => ListingFlowProvider(listingFlowRepository: listingFlowRepository),
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