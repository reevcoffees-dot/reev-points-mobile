import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  String? _splashImageUrl;
  bool _hasSplashImage = false;
  String? _loginLogoUrl;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadLoginLogo();
    _loadSplashImage();
    _checkAuthStatus();
    _animationController = AnimationController(
      duration: AppConstants.longAnimation,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
    _loadSplashImage();
    _checkAuthStatus();
  }

  Future<void> _loadLoginLogo() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/login-logo'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _loginLogoUrl = data['login_logo_url'];
          });
        }
      }
    } catch (e) {
      print('Login logo yüklenirken hata: $e');
    }
  }

  Future<void> _loadSplashImage() async {
    try {
      final response = await _apiService.getSplashImage();
      if (response['success'] == true && mounted) {
        setState(() {
          _hasSplashImage = response['has_splash'] ?? false;
          _splashImageUrl = response['splash_url'];
        });
      }
    } catch (e) {
      // Splash resmi yüklenemezse varsayılan logo kullanılır
      print('Splash resmi yüklenemedi: $e');
    }
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Wait for auth service to load saved data
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (authService.isAuthenticated && authService.user != null) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _hasSplashImage && _splashImageUrl != null
                  ? _buildFullScreenSplash()
                  : _buildDefaultSplash(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullScreenSplash() {
    return Stack(
      children: [
        // Tam ekran splash resmi
        Positioned.fill(
          child: Image.network(
            _splashImageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildDefaultSplash();
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultSplash();
            },
          ),
        ),
        
        // Üstte app name (opsiyonel)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.1,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Sadakat Programı',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.9),
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Altta loading indicator
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 0,
          right: 0,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultSplash() {
    return Container(
      decoration: AppTheme.backgroundDecoration,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: _loginLogoUrl != null
                    ? Image.network(
                        _loginLogoUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/icons/app_icon.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.coffee,
                                size: 60,
                                color: AppTheme.primaryColor,
                              );
                            },
                          );
                        },
                      )
                    : Image.asset(
                        'assets/icons/app_icon.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.coffee,
                            size: 60,
                            color: AppTheme.primaryColor,
                          );
                        },
                      ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // App Name
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Subtitle
            Text(
              'Sadakat Programı',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
