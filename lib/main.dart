import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// TODO: Re-enable Firebase after fixing web compatibility
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/campaigns_screen.dart';
import 'screens/redeem_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/product_approval_screen.dart';
import 'screens/branches_screen.dart';
import 'screens/survey_screen.dart';
import 'utils/app_theme.dart';
import 'utils/app_constants.dart';

// TODO: Re-enable Firebase background message handler
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   print('Background message received: ${message.messageId}');
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Re-enable Firebase initialization after fixing web compatibility
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  
  // TODO: Re-enable Firebase background message handler
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // TODO: Re-enable notification service after fixing Firebase
  // await NotificationService.initialize();
  
  runApp(const ReevPointsApp());
}

class ReevPointsApp extends StatelessWidget {
  const ReevPointsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => ApiService()),
        Provider(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'REEV POINTS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/campaigns': (context) => const CampaignsScreen(),
          '/redeem': (context) => const RedeemScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/product-approval': (context) => const ProductApprovalScreen(),
          '/branches': (context) => const BranchesScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/reset-password') {
            final email = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(email: email),
            );
          } else if (settings.name == '/survey') {
            final survey = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => SurveyScreen(survey: survey),
            );
          }
          return null;
        },
        locale: const Locale('tr', 'TR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr', 'TR'),
          Locale('en', 'US'),
          Locale('ru', 'RU'),
          Locale('de', 'DE'),
        ],
      ),
    );
  }
}

