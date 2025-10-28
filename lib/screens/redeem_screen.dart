import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_button.dart';
import 'branches_screen.dart';

class RedeemScreen extends StatefulWidget {
  const RedeemScreen({super.key});

  @override
  State<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends State<RedeemScreen> {
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String? _selectedCategory;
  int _userPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadRedeemData();
  }

  Future<void> _loadRedeemData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Check if user is authenticated
      if (!authService.isAuthenticated || authService.user == null) {
        return;
      }
      
      final userId = authService.user!['id'];
      final response = await apiService.get(
        '${AppConstants.redeemEndpoint}?user_id=$userId',
        headers: authService.getAuthHeaders(),
      );
      
      if (mounted) {
        setState(() {
          _products = response['products'] ?? [];
          _categories = response['categories'] ?? [];
          _userPoints = (response['user_points'] as num?)?.toInt() ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürünler yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _redeemProduct(Map<String, dynamic> product) async {
    final int productPoints = (product['points'] as num?)?.toInt() ?? 0;
    if (_userPoints < productPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yetersiz puan!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Ürün Talebi'),
        content: Text(
          '${product['name']} ürünü için $productPoints puan karşılığında talep oluşturmak istediğinizden emin misiniz?\n\nTalep onaylandığında puanlarınız düşülecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _processRedemption(product);
            },
            child: const Text('Talep Oluştur'),
          ),
        ],
      ),
    );
  }

  Future<void> _processRedemption(Map<String, dynamic> product) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      final response = await apiService.post(
        '/api/request-product',
        data: {
          'user_id': authService.user?['id'],
          'product_id': product['id']
        },
        headers: authService.getAuthHeaders(),
      );
      
      if (response['success'] == true && mounted) {
        // Debug: API response'u kontrol et
        print('🔍 API Response: $response');
        print('🔍 QR Code: ${response['qr_code']}');
        print('🔍 Confirmation Code: ${response['confirmation_code']}');
        
        // Save QR code to customerQR table
        if (response['qr_code'] != null && response['qr_code'].toString().isNotEmpty) {
          await _saveQrToDatabase(response['qr_code'], 'product_request', productId: product['id'].toString());
        }
        
        // Show success dialog for product request with QR code
        _showProductRequestSuccessDialog(
          response['message'] ?? 'Ürün talebi başarıyla oluşturuldu!',
          product['name'],
          response['qr_code'] ?? '',
          response['confirmation_code'] ?? '',
        );
        
        // Refresh data
        _loadRedeemData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Ürün talebi oluşturulamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveQrToDatabase(String qrCode, String qrType, {String? campaignId, String? productId}) async {
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

  String? _dashboardQrCode;
  bool _isGeneratingDashboardQR = false;

  Future<void> _generateDashboardQR() async {
    setState(() => _isGeneratingDashboardQR = true);
    
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
          _dashboardQrCode = response['qr_data'];
        });
        
        // Save QR code to customerQR table
        await _saveQrToDatabase(response['qr_data'], 'dashboard');
        
        _showDashboardQRDialog();
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
        setState(() => _isGeneratingDashboardQR = false);
      }
    }
  }

  void _showDashboardQRDialog() {
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
              
              if (_dashboardQrCode != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: QrImageView(
                    data: _dashboardQrCode!,
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

  void _showProductRequestSuccessDialog(String message, String productName, String qrCode, String confirmationCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cardDecoration,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Success Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.pending_actions,
                  color: Colors.blue,
                  size: 30,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Ürün Talebi Oluşturuldu!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '$productName için talebiniz oluşturuldu. Şubede bu QR kodu göstererek ürününüzü alabilirsiniz.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
              
              // QR Code Display
              if (qrCode.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'QR Kod',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: QrImageView(
                          data: qrCode,
                          version: QrVersions.auto,
                          size: 150.0,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        qrCode,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bu QR kodu veya 6 haneli kodu şubede gösterin',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Confirmation Code
              if (confirmationCode.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 122, 165, 132).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color.fromARGB(255, 127, 170, 121).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Onay Kodu',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color.fromARGB(255, 116, 160, 110),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        confirmationCode,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: const Color.fromARGB(255, 105, 187, 126),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 130, 168, 133),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Tamam'),
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


  List<dynamic> get _filteredProducts {
    if (_selectedCategory == null) return _products;
    return _products.where((product) => 
      product['category_id'].toString() == _selectedCategory
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Puan Kullan',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(253, 255, 254, 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_userPoints Puan',
                        style: const TextStyle(
                          color: Color.fromARGB(175, 123, 185, 147),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.of(context).pushNamed('/profile'),
                      icon: const Icon(
                        Icons.account_circle,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Category Filter
              if (_categories.isNotEmpty)
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildCategoryChip('Tümü', null);
                      }
                      final category = _categories[index - 1];
                      return _buildCategoryChip(category['name'], category['id'].toString());
                    },
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : RefreshIndicator(
                        onRefresh: _loadRedeemData,
                        child: _filteredProducts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_cart,
                                      size: 64,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Ürün bulunmuyor',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.85,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  return _buildProductCard(product);
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCategoryChip(String title, String? categoryValue) {
    final isSelected = _selectedCategory == categoryValue;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = categoryValue;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color.fromARGB(255, 133, 177, 137) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color.fromARGB(255, 136, 177, 145) : AppTheme.cardBorder,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final int productPoints = (product['points'] as num?)?.toInt() ?? 0;
    final canAfford = _userPoints >= productPoints;
    
    return Container(
      decoration: AppTheme.cardDecoration.copyWith(
        color: canAfford ? AppTheme.cardBg : AppTheme.cardBg.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: product['image_url'] != null && product['image_url'].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        product['image_url'],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildPlaceholderImage();
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('Image load error: $error');
                          return _buildPlaceholderImage();
                        },
                      ),
                    )
                  : _buildPlaceholderImage(),
            ),
          ),
          
          // Product Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      product['name'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: canAfford ? Colors.black87 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: canAfford ? const Color.fromARGB(255, 103, 160, 120) : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$productPoints Puan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      if (canAfford)
                        GestureDetector(
                          onTap: () => _redeemProduct(product),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 117, 163, 113),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 130, 175, 126).withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.redeem,
              size: 40,
              color: Color.fromARGB(255, 127, 168, 130),
            ),
            SizedBox(height: 8),
            Text(
              'Ürün Resmi',
              style: TextStyle(
                color: Color.fromARGB(255, 129, 165, 120),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.black54,
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacementNamed('/dashboard');
              break;
            case 1:
              Navigator.of(context).pushReplacementNamed('/campaigns');
              break;
            case 2:
              _generateDashboardQR();
              break;
            case 3:
              // Already on redeem
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
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Kampanyalar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: 'QR Oluştur',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.redeem),
            label: 'Puan Kullan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Şubelerimiz',
          ),
        ],
      ),
    );
  }
}
