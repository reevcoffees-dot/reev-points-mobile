import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_button.dart';
import 'branches_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _qrCodeData;
  bool _isGeneratingQR = false;
  List<Map<String, dynamic>> _purchaseHistory = [];
  bool _isLoadingPurchaseHistory = false;
  List<Map<String, dynamic>> _activeSurveys = [];
  bool _isLoadingSurveys = false;

  @override
  void initState() {
    super.initState();
    // Defer the data loading to after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Check if user is authenticated and has user data
      print('Dashboard - isAuthenticated: ${authService.isAuthenticated}');
      print('Dashboard - user: ${authService.user}');

      if (!authService.isAuthenticated || authService.user == null) {
        print('Dashboard - User not authenticated, redirecting to login');
        if (mounted) {
          Future.delayed(Duration.zero, () {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          });
        }
        return;
      }

      final userId = authService.user!['id'];
      print('Dashboard - userId: $userId');

      if (userId == null) {
        print('Dashboard - User ID is null, redirecting to login');
        if (mounted) {
          Future.delayed(Duration.zero, () {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          });
        }
        return;
      }

      final response = await apiService.get(
        '${AppConstants.dashboardEndpoint}?user_id=$userId',
        headers: authService.getAuthHeaders(),
      );

      print('Dashboard API response: $response');

      if (mounted) {
        setState(() {
          _dashboardData = response;
          _isLoading = false;
        });

        // Debug: Log most favorite product data
        print('Most favorite product: ${response['most_favorite_product']}');
        print(
            'Most favorite product is null: ${response['most_favorite_product'] == null}');
        print('Dashboard data keys: ${response.keys.toList()}');

        // Update user data in AuthService if dashboard API returned user info
        if (response['success'] == true && response['user'] != null) {
          authService.updateUser(response['user']);
        }

        // Load purchase history for rating
        _loadPurchaseHistory();
        
        // Load active surveys
        _loadActiveSurveys();
      }
    } catch (e) {
      print('Dashboard error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        // Use Future.delayed to avoid context issues
        Future.delayed(Duration.zero, () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Veri yüklenirken hata: $e')),
            );
          }
        });
      }
    }
  }

  Future<void> _loadPurchaseHistory() async {
    if (_isLoadingPurchaseHistory) return;
    
    setState(() => _isLoadingPurchaseHistory = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      if (!authService.isAuthenticated || authService.user == null) {
        return;
      }

      final userId = authService.user!['id'];
      if (userId == null) return;

      final response = await apiService.getPurchaseHistory(
        userId: userId.toString(),
        headers: authService.getAuthHeaders(),
      );

      if (mounted && response['success'] == true) {
        setState(() {
          _purchaseHistory = List<Map<String, dynamic>>.from(
            response['purchases'] ?? []
          );
        });
      }
    } catch (e) {
      print('Purchase history error: $e');
      // Don't show error to user for purchase history as it's not critical
    } finally {
      if (mounted) {
        setState(() => _isLoadingPurchaseHistory = false);
      }
    }
  }

  Future<void> _loadActiveSurveys() async {
    if (_isLoadingSurveys) return;
    
    setState(() => _isLoadingSurveys = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      if (!authService.isAuthenticated || authService.user == null) {
        return;
      }

      final response = await apiService.get(
        AppConstants.activeSurveysEndpoint,
        headers: authService.getAuthHeaders(),
      );

      if (mounted && response['success'] == true) {
        setState(() {
          _activeSurveys = List<Map<String, dynamic>>.from(
            response['surveys'] ?? []
          );
        });
      }
    } catch (e) {
      print('Active surveys error: $e');
      if (mounted && e.toString().contains('Token süresi dolmuş')) {
        // Token expired, user needs to log in again
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Giriş Yap',
              textColor: Colors.white,
              onPressed: () {
                final authService = Provider.of<AuthService>(context, listen: false);
                authService.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSurveys = false);
      }
    }
  }

  Future<void> _generateQRCode() async {
    setState(() => _isGeneratingQR = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Check if user is authenticated
      if (!authService.isAuthenticated || authService.user == null) {
        throw Exception('Kullanıcı girişi gerekli');
      }

      final userId = authService.user!['id'];
      if (userId == null) {
        throw Exception('Kullanıcı bilgisi eksik');
      }

      final response = await apiService.post(
        AppConstants.generateQrEndpoint,
        data: {
          'user_id': userId,
        },
        headers: authService.getAuthHeaders(),
      );

      if (response['success'] == true && mounted) {
        setState(() {
          _qrCodeData = response['qr_data'];
        });

        // Save QR code to customerQR table
        await _saveQrToDatabase(response['qr_data'], 'dashboard');

        _showQRDialog();
      } else if (mounted) {
        // Show error message from API response
        final errorMessage = response['error'] ?? 'QR kod oluşturulamadı';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('QR Code generation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR kod oluşturulurken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingQR = false);
      }
    }
  }

  Future<void> _saveQrToDatabase(String qrCode, String qrType,
      {String? campaignId, String? productId}) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      if (!authService.isAuthenticated || authService.user == null) {
        return;
      }

      final userId = authService.user!['id'];
      if (userId == null) {
        return;
      }

      await apiService.saveCustomerQr(
        userId: userId.toString(),
        qrCode: qrCode,
        qrType: qrType,
        campaignId: campaignId,
        productId: productId,
        headers: authService.getAuthHeaders(),
      );

      print('QR kod customerQR tablosuna kaydedildi: $qrCode');
    } catch (e) {
      print('QR kod kaydetme hatası: $e');
      // Hata durumunda kullanıcıya bilgi vermek istemiyoruz, sadece log'luyoruz
    }
  }

  void _showQRDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cardDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QR Kodunuz',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              if (_qrCodeData != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: QrImageView(
                    data: _qrCodeData!,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Bu QR kodu şubede okutarak puan kazanabilirsiniz.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Kapat',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Modern Header with Avatar
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color.fromARGB(255, 173, 152, 137),
                                      const Color.fromARGB(255, 153, 97, 57)
                                          .withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(
                                              255, 163, 142, 128)
                                          .withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // User Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hoş Geldiniz',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            fontWeight: FontWeight.w400,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _dashboardData?['user']?['name'] ??
                                          authService.user?['name'] ??
                                          'Kullanıcı',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              // Notification Bell
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(22.5),
                                ),
                                child: IconButton(
                                  onPressed: () => Navigator.of(context)
                                      .pushNamed('/profile'),
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Modern Points Card
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color.fromARGB(255, 173, 216, 176),
                                const Color.fromARGB(255, 182, 128, 90)
                                    .withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Toplam Puanınız',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${_dashboardData?['user']?['points'] ?? authService.user?['points'] ?? 0}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 36,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Text(
                                            'PUAN',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 1.2,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(35),
                                ),
                                child: const Icon(
                                  Icons.stars_rounded,
                                  color: Colors.white,
                                  size: 35,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Quick Actions Section
                        Text(
                          'Hızlı İşlemler',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),

                        const SizedBox(height: 16),

                        // Quick Actions Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1, // Oranı biraz düşürdüm
                          children: [
                            _buildModernActionCard(
                              icon: Icons.qr_code_scanner_rounded,
                              title: 'QR Kod\nOluştur',
                              subtitle: 'Puan kazan',
                              colors: [Colors.orange, Colors.deepOrange],
                              onTap: _isGeneratingQR ? null : _generateQRCode,
                              isLoading: _isGeneratingQR,
                            ),
                            _buildModernActionCard(
                              icon: Icons.campaign_rounded,
                              title: 'Kampanyalar',
                              subtitle: 'Fırsatları gör',
                              colors: [Colors.purple, Colors.deepPurple],
                              onTap: () => Navigator.of(context)
                                  .pushReplacementNamed('/campaigns'),
                            ),
                            _buildModernActionCard(
                              icon: Icons.redeem_rounded,
                              title: 'Puan Kullan',
                              subtitle: 'Ödül kazan',
                              colors: [Colors.green, Colors.teal],
                              onTap: () => Navigator.of(context)
                                  .pushReplacementNamed('/redeem'),
                            ),
                            _buildModernActionCard(
                              icon: Icons.store_rounded,
                              title: 'Şubelerimiz',
                              subtitle: 'Konumları gör',
                              colors: [Colors.blue, Colors.indigo],
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const BranchesScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Modern Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatsCard(
                                'Bu Ay Kazanılan',
                                '${_dashboardData?['monthly_points'] ?? 0}',
                                'Puan',
                                Icons.trending_up_rounded,
                                [Colors.green.shade400, Colors.green.shade600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatsCard(
                                'Toplam İşlem',
                                '${_dashboardData?['total_transactions'] ?? 0}',
                                'Adet',
                                Icons.receipt_long_rounded,
                                [Colors.blue.shade400, Colors.blue.shade600],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // En Çok Tercih Edilen Şube ve En Sevilen Ürün Kartları (Yan Yana)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // En Çok Ziyaret Edilen Şube Kartı
                              if (_dashboardData?['most_visited_branch'] != null)
                                Expanded(
                                  child: _buildCompactMostVisitedBranchCard(
                                      _dashboardData!['most_visited_branch']),
                                ),

                              if (_dashboardData?['most_visited_branch'] != null &&
                                  _dashboardData?['most_favorite_product'] != null)
                                const SizedBox(width: 12),

                              // En Sevilen Ürün Kartı
                              if (_dashboardData?['most_favorite_product'] != null)
                                Expanded(
                                  child: _buildCompactMostFavoriteProductCard(
                                      _dashboardData!['most_favorite_product']),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Survey and Rate Drinks Cards (Side by Side)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildSurveyCard(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildRateYourDrinksCard(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildModernActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 140, // Sabit yükseklik ekledim
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isLoading ? null : onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(
                      icon,
                      size: 28,
                      color: Colors.white,
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    String title,
    String value,
    String unit,
    IconData icon,
    List<Color> colors,
  ) {
    return Container(
      height: 110, // Sabit yükseklik ekledim
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          currentIndex: 0,
          onTap: (index) {
            switch (index) {
              case 0:
                // Already on dashboard
                break;
              case 1:
                Navigator.of(context).pushReplacementNamed('/campaigns');
                break;
              case 2:
                _generateQRCode();
                break;
              case 3:
                Navigator.of(context).pushReplacementNamed('/redeem');
                break;
              case 4:
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BranchesScreen(),
                  ),
                );
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Ana Sayfa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_rounded),
              label: 'Kampanyalar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded),
              label: 'QR Oluştur',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.redeem_rounded),
              label: 'Puan Kullan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store_rounded),
              label: 'Şubelerimiz',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMostVisitedBranchCard(Map<String, dynamic> branch) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade400,
            Colors.orange.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'En Çok Ziyaret Edilen Şube',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${branch['visit_count']} ziyaret',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branch['name'] ?? 'Bilinmeyen Şube',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (branch['address'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          branch['address'],
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (branch['phone'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        branch['phone'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ),
                ],
                if (branch['working_hours'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        branch['working_hours'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMostVisitedBranchCard(Map<String, dynamic> branch) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade400,
            Colors.orange.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Üst kısım - ikon ve başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'En Çok Ziyaret',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${branch['visit_count']} ziyaret',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 10,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Alt kısım - şube bilgileri
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Şube adı
                Text(
                  branch['name'] ?? 'Bilinmeyen Şube',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Adres bilgisi
                if (branch['address'] != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white70,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          branch['address'],
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 10,
                                  ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMostFavoriteProductCard(Map<String, dynamic> product) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade400,
            Colors.deepPurple.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Üst kısım - ikon ve başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['is_suggested'] == true
                          ? 'Önerilen'
                          : 'En Sevilen Ürün',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product['is_suggested'] == true
                          ? 'Size özel'
                          : '${product['redemption_count']} kez',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 10,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Alt kısım - ürün bilgileri
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ürün adı
                Text(
                  product['name'] ?? 'Bilinmeyen Ürün',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Puan ve kategori bilgisi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Puan bilgisi
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${product['points_required'] ?? product['points'] ?? 0}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                          ),
                        ],
                      ),
                    ),

                    // Kategori bilgisi (varsa)
                    if (product['category_name'] != null)
                      Expanded(
                        child: Text(
                          product['category_name'],
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 10,
                                  ),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateYourDrinksCard() {
    return GestureDetector(
      onTap: () {
        if (_purchaseHistory.isEmpty && !_isLoadingPurchaseHistory) {
          _loadPurchaseHistory();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade400,
              Colors.red.shade500,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.rate_review_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 120), // Maksimum genişlik ekliyorum
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'İçeceğini Puanla',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14, // Yazı boyutunu küçülttüm
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _purchaseHistory.isEmpty && !_isLoadingPurchaseHistory
                                  ? 'Ürünler için tıklayın'
                                  : 'Alışverişlerinizi değerlendirin',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 11, // Yazı boyutunu küçülttüm
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingPurchaseHistory)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else if (_purchaseHistory.isNotEmpty)
                  IconButton(
                    onPressed: _loadPurchaseHistory,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 16,
                  ),
              ],
            ),
            if (_purchaseHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _purchaseHistory.length,
                  itemBuilder: (context, index) {
                    final product = _purchaseHistory[index];
                    return _buildRatingProductCard(product);
                  },
                ),
              ),
            ] else if (_purchaseHistory.isEmpty && !_isLoadingPurchaseHistory) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Ürünleri değerlendirin',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyCard() {
    return GestureDetector(
      onTap: () {
        if (_activeSurveys.isEmpty && !_isLoadingSurveys) {
          _loadActiveSurveys();
        } else if (_activeSurveys.isNotEmpty) {
          _showSurveyDialog(_activeSurveys.first);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade400,
              Colors.purple.shade500,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.poll_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 120), // Maksimum genişlik ekliyorum
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deneyimini Değerlendir',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14, // Yazı boyutunu küçülttüm
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _activeSurveys.isEmpty && !_isLoadingSurveys
                                  ? 'Anketler için tıklayın'
                                  : _activeSurveys.isNotEmpty
                                      ? '${_activeSurveys.length} anket var'
                                      : 'Yükleniyor...',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 11, // Yazı boyutunu küçülttüm
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingSurveys)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else if (_activeSurveys.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_activeSurveys.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 16,
                  ),
              ],
            ),
            if (_activeSurveys.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Görüşleriniz önemli',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSurveyDialog(Map<String, dynamic> survey) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cardDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.poll_rounded,
                  color: Colors.indigo,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                survey['title'] ?? 'Anket',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                survey['description'] ?? 'Görüşlerinizi paylaşın',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Başla',
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/survey', arguments: survey);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingProductCard(Map<String, dynamic> product) {
    final bool hasRating = product['user_rating'] != null;
    final int userRating = product['user_rating'] ?? 0;
    
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image or icon
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: product['image_url'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.local_drink_rounded,
                          color: Colors.white,
                          size: 20,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.local_drink_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
          const SizedBox(height: 8),
          // Product name
          Text(
            product['name'] ?? 'Ürün',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Purchase date
          if (product['purchase_date'] != null)
            Text(
              _formatDate(product['purchase_date']),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                  ),
            ),
          const Spacer(),
          // Rating section
          if (hasRating)
            Row(
              children: [
                ...List.generate(5, (starIndex) {
                  return Icon(
                    starIndex < userRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 14,
                  );
                }),
              ],
            )
          else
            GestureDetector(
              onTap: () => _showRatingDialog(product),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_outline_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Puanla',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showRatingDialog(Map<String, dynamic> product) {
    int selectedRating = 0;
    String comment = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.cardDecoration,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ürünü Puanla',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  product['name'] ?? 'Ürün',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Star rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedRating = index + 1;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < selectedRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                // Comment field
                TextField(
                  onChanged: (value) => comment = value,
                  decoration: InputDecoration(
                    hintText: 'Yorumunuz (isteğe bağlı)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'İptal',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Puanla',
                        onPressed: selectedRating > 0
                            ? () => _submitRating(product, selectedRating, comment)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitRating(Map<String, dynamic> product, int rating, String comment) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      if (!authService.isAuthenticated || authService.user == null) {
        throw Exception('Kullanıcı girişi gerekli');
      }

      final userId = authService.user!['id'];
      if (userId == null) {
        throw Exception('Kullanıcı bilgisi eksik');
      }

      final response = await apiService.rateProduct(
        userId: userId.toString(),
        productId: product['id'].toString(),
        rating: rating,
        comment: comment.isNotEmpty ? comment : null,
        headers: authService.getAuthHeaders(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Puanınız başarıyla kaydedildi!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Update the product rating in local list
          setState(() {
            final index = _purchaseHistory.indexWhere((p) => p['id'] == product['id']);
            if (index != -1) {
              _purchaseHistory[index]['user_rating'] = rating;
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['error'] ?? 'Puanlama başarısız'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Puanlama hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMostFavoriteProductCard(Map<String, dynamic> product) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade400,
            Colors.deepPurple.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['is_suggested'] == true
                          ? 'Önerilen Ürün'
                          : 'En Sevilen Ürün',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['is_suggested'] == true
                          ? 'Size özel öneri'
                          : '${product['redemption_count']} kez alındı',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Ürün resmi
                if (product['image_url'] != null)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(product['image_url']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                const SizedBox(width: 16),

                // Ürün bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? 'Bilinmeyen Ürün',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (product['category_name'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          product['category_name'],
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${product['points']} puan',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (product['description'] != null &&
                          product['description'].isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          product['description'],
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
