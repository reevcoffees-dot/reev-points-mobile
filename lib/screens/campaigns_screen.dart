import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_button.dart';
import 'branches_screen.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  List<dynamic> _campaigns = [];
  bool _isLoading = true;
  String? _selectedCampaignQR;
  bool _isGeneratingQR = false;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      final response = await apiService.get(
        AppConstants.campaignsEndpoint,
        headers: authService.getAuthHeaders(),
      );
      
      if (mounted) {
        setState(() {
          _campaigns = response['campaigns'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kampanyalar yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _generateCampaignQR(int campaignId, List<dynamic> products) async {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir ürün seçin')),
      );
      return;
    }

    setState(() => _isGeneratingQR = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      final response = await apiService.post(
        '/api/generate-qr',
        data: {
          'user_id': authService.user?['id'],
          'campaign_id': campaignId,
          'selected_product_id': products.isNotEmpty ? products.first['id'] : null,
        },
        headers: authService.getAuthHeaders(),
      );
      
      if (response['success'] == true && mounted) {
        setState(() {
          _selectedCampaignQR = response['qr_code'];
        });
        
        // Save QR code to customerQR table
        await _saveQrToDatabase(response['qr_code'], 'campaign', campaignId: campaignId.toString());
        
        _showQRDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR kod oluşturulurken hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingQR = false);
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

  Future<void> _generateDashboardQR() async {
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
          _selectedCampaignQR = response['qr_data'];
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
                _selectedCampaignQR != null && _selectedCampaignQR!.startsWith('CUSTOMER') 
                    ? 'QR Kodunuz' 
                    : 'Kampanya QR Kodunuz',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 20),
              
              if (_selectedCampaignQR != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: QrImageView(
                    data: _selectedCampaignQR!,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              
              const SizedBox(height: 20),
              
              Text(
                _selectedCampaignQR != null && _selectedCampaignQR!.startsWith('CUSTOMER')
                    ? 'Bu QR kodu şubede okutarak puan kazanabilirsiniz.'
                    : 'Bu QR kodu şubede okutarak kampanya indiriminden yararlanabilirsiniz.',
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

  void _showProductSelectionDialog(Map<String, dynamic> campaign) {
    List<dynamic> selectedProducts = [];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.cardDecoration,
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ürün Seçin',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: campaign['products']?.length ?? 0,
                    itemBuilder: (context, index) {
                      final product = campaign['products'][index];
                      final isSelected = selectedProducts.any((p) => p['id'] == product['id']);
                      
                      return CheckboxListTile(
                        title: Text(
                          product['name'] ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          '${(product['points'] as num?)?.toInt() ?? 0} puan - %${(product['discount'] as num?)?.toInt() ?? 0} indirim',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                        value: isSelected,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedProducts.add(product);
                            } else {
                              selectedProducts.removeWhere((p) => p['id'] == product['id']);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
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
                        text: 'QR Oluştur',
                        onPressed: selectedProducts.isEmpty ? null : () {
                          Navigator.of(context).pop();
                          _generateCampaignQR(campaign['id'], selectedProducts);
                        },
                        isLoading: _isGeneratingQR,
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
                        'Kampanyalar',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
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
              
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : RefreshIndicator(
                        onRefresh: _loadCampaigns,
                        child: _campaigns.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.campaign_outlined,
                                      size: 64,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aktif kampanya bulunmuyor',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _campaigns.length,
                                itemBuilder: (context, index) {
                                  final campaign = _campaigns[index];
                                  return _buildCampaignCard(campaign);
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

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campaign Image
          if (campaign['image_url'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                campaign['image_url'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 200,
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  child: const Icon(
                    Icons.campaign,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campaign Title
                Text(
                  campaign['title'] ?? '',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Campaign Description
                if (campaign['description'] != null)
                  Text(
                    campaign['description'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Campaign Details
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${campaign['start_date']} - ${campaign['end_date']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                if (campaign['valid_branches'] != null && campaign['valid_branches'].isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Geçerli şubeler: ${campaign['valid_branches'].join(', ')}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 20),
                
                // Action Button
                CustomButton(
                  text: 'Kampanya QR Oluştur',
                  onPressed: () => _showProductSelectionDialog(campaign),
                  icon: Icons.qr_code,
                ),
              ],
            ),
          ),
        ],
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
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacementNamed('/dashboard');
              break;
            case 1:
              // Already on campaigns
              break;
            case 2:
              _generateDashboardQR();
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
