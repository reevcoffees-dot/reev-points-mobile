import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_button.dart';
import 'branches_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _dashboardQrCode;
  bool _isGeneratingDashboardQR = false;
  List<Map<String, dynamic>> _transactionHistory = [];
  List<Map<String, dynamic>> _messages = [];
  
  // Şifre değiştirme form kontrolleri
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _changePasswordFormKey = GlobalKey<FormState>();
  bool _isChangingPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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

  Future<void> _loadTransactionHistory() async {
    
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
      
      print('İşlem geçmişi yükleniyor - User ID: $userId');
      
      final response = await apiService.getTransactionHistory(
        userId: userId.toString(),
        headers: authService.getAuthHeaders(),
      );
      
      print('API Response: $response');
      
      if (response['success'] == true && mounted) {
        final transactions = List<Map<String, dynamic>>.from(
          response['transactions'] ?? []
        );
        print('İşlem sayısı: ${transactions.length}');
        
        setState(() {
          _transactionHistory = transactions;
        });
        
        if (transactions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Henüz işlem geçmişiniz bulunmuyor.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (mounted) {
        final errorMessage = response['error'] ?? 'İşlem geçmişi yüklenemedi';
        print('API Error: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Transaction history error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem geçmişi yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Transaction loading completed
    }
  }

  Future<void> _loadMessages() async {
    
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
      
      print('Mesajlar yükleniyor - User ID: $userId');
      
      final response = await apiService.get(
        '${AppConstants.messagesEndpoint}?user_id=$userId',
        headers: authService.getAuthHeaders(),
      );
      
      print('Messages API Response: $response');
      
      if (response['success'] == true && mounted) {
        final messages = List<Map<String, dynamic>>.from(
          response['messages'] ?? []
        );
        print('Mesaj sayısı: ${messages.length}');
        
        setState(() {
          _messages = messages;
        });
        
        if (messages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Henüz mesajınız bulunmuyor.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (mounted) {
        final errorMessage = response['error'] ?? 'Mesajlar yüklenemedi';
        print('Messages API Error: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Messages error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesajlar yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Messages loading completed
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

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
                    Text(
                      'Profil',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Card
                      Container(
                        decoration: AppTheme.cardDecoration,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Avatar
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Text(
                              user?['name'] ?? 'Kullanıcı',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              user?['email'] ?? '',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Menu Items
                      _buildMenuItem(
                        icon: Icons.history,
                        title: 'İşlem Geçmişi',
                        onTap: () {
                          _showTransactionHistory();
                        },
                      ),
                      
                      _buildMenuItem(
                        icon: Icons.message,
                        title: 'Mesajlar',
                        onTap: () {
                          _showMessages();
                        },
                      ),
                      
                      _buildMenuItem(
                        icon: Icons.lock,
                        title: 'Şifre Değiştir',
                        onTap: () {
                          _showChangePasswordDialog();
                        },
                      ),
                      
                      _buildMenuItem(
                        icon: Icons.language,
                        title: 'Dil Ayarları',
                        onTap: () {
                          _showLanguageDialog();
                        },
                      ),
                      
                      _buildMenuItem(
                        icon: Icons.notifications,
                        title: 'Bildirim Ayarları',
                        onTap: () {
                          _showNotificationSettings();
                        },
                      ),
                      
                      _buildMenuItem(
                        icon: Icons.help,
                        title: 'Yardım',
                        onTap: () {
                          _showHelp();
                        },
                      ),
                      
                      _buildMenuItem(
                        icon: Icons.info,
                        title: 'Hakkında',
                        onTap: () {
                          _showAboutDialog();
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Logout Button
                      CustomButton(
                        text: 'Çıkış Yap',
                        onPressed: () => _showLogoutDialog(),
                        icon: Icons.logout,
                        backgroundColor: Colors.red,
                      ),
                    ],
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

  void _showTransactionHistory() async {
    // Önce veriyi yükle, sonra dialog'u göster
    await _loadTransactionHistory();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('İşlem Geçmişi'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              const Text('Son işlemleriniz:'),
              const SizedBox(height: 16),
              Expanded(
                child: _transactionHistory.isEmpty
                  ? const Center(
                      child: Text(
                        'Henüz işlem geçmişiniz bulunmuyor.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _transactionHistory.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactionHistory[index];
                        return _buildTransactionItemFromData(transaction);
                      },
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItemFromData(Map<String, dynamic> transaction) {
    final String transactionType = transaction['transaction_type'] ?? 'Bilinmeyen İşlem';
    final int points = transaction['points'] ?? 0;
    final String date = transaction['created_at'] ?? '';
    final String description = transaction['description'] ?? transactionType;
    
    // Tarihi formatla
    String formattedDate = date;
    try {
      final DateTime parsedDate = DateTime.parse(date);
      formattedDate = '${parsedDate.day.toString().padLeft(2, '0')}.${parsedDate.month.toString().padLeft(2, '0')}.${parsedDate.year}';
    } catch (e) {
      // Tarih parse edilemezse orijinal değeri kullan
    }
    
    final String pointsText = points > 0 ? '+$points Puan' : '$points Puan';
    final bool isPositive = points > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(formattedDate, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(
            pointsText,
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  void _showMessages() async {
    // Önce mesajları yükle, sonra dialog'u göster
    await _loadMessages();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mesajlar'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              const Text('Sistem mesajlarınız:'),
              const SizedBox(height: 16),
              Expanded(
                child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'Henüz mesajınız bulunmuyor.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageItemFromData(message);
                      },
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItemFromData(Map<String, dynamic> message) {
    final String title = message['title'] ?? 'Başlık Yok';
    final String content = message['content'] ?? '';
    final String date = message['created_at'] ?? '';
    final bool isRead = message['is_read'] ?? false;
    final bool isAdminMessage = message['is_admin_message'] ?? false;
    final String senderName = message['sender_name'] ?? 'Sistem';
    
    // Tarihi formatla
    String formattedDate = date;
    try {
      final DateTime parsedDate = DateTime.parse(date);
      formattedDate = '${parsedDate.day.toString().padLeft(2, '0')}.${parsedDate.month.toString().padLeft(2, '0')}.${parsedDate.year}';
    } catch (e) {
      // Tarih parse edilemezse orijinal değeri kullan
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isRead ? Colors.grey[300]! : Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title, 
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                    color: isRead ? Colors.grey[700] : Colors.black,
                  ),
                ),
              ),
              Text(
                formattedDate, 
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content, 
            style: TextStyle(
              fontSize: 14,
              color: isRead ? Colors.grey[600] : Colors.black87,
            ),
          ),
          if (isAdminMessage) ...[
            const SizedBox(height: 4),
            Text(
              'Gönderen: $senderName',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Bildirim Ayarları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Push Bildirimleri'),
              subtitle: const Text('Uygulama bildirimleri'),
              value: true,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Push bildirimleri ${value ? 'açıldı' : 'kapatıldı'}')),
                );
              },
            ),
            SwitchListTile(
              title: const Text('E-posta Bildirimleri'),
              subtitle: const Text('Kampanya ve duyuru e-postaları'),
              value: false,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('E-posta bildirimleri ${value ? 'açıldı' : 'kapatıldı'}')),
                );
              },
            ),
            SwitchListTile(
              title: const Text('SMS Bildirimleri'),
              subtitle: const Text('Önemli bilgilendirme SMS\'leri'),
              value: true,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('SMS bildirimleri ${value ? 'açıldı' : 'kapatıldı'}')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Yardım'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sık Sorulan Sorular',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildHelpItem(
                  'Nasıl puan kazanırım?',
                  'Şubelerimizde QR kod okutarak puan kazanabilirsiniz. Her QR kod okutma için 1 puan kazanırsınız.',
                ),
                _buildHelpItem(
                  'Puanlarımı nasıl kullanırım?',
                  'Puan Kullan sekmesinden ürünleri görüntüleyebilir ve puanlarınızla ürün talep edebilirsiniz.',
                ),
                _buildHelpItem(
                  'Kampanyalar nasıl çalışır?',
                  'Kampanyalar sekmesinden aktif kampanyaları görüntüleyebilir ve kampanya QR kodları oluşturabilirsiniz.',
                ),
                _buildHelpItem(
                  'Şubeleriniz nerede?',
                  'Şubelerimiz sekmesinden tüm şube lokasyonlarını ve iletişim bilgilerini görüntüleyebilirsiniz.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'İletişim',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text('E-posta: info@reevpoints.tr'),
                const Text('Telefon: +90 (212) 123 45 67'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: ListTile(
        leading: Icon(
          icon,
          color: AppTheme.primaryColor,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.black54,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Dil Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('🇹🇷', 'Türkçe', 'tr'),
            _buildLanguageOption('🇺🇸', 'English', 'en'),
            _buildLanguageOption('🇷🇺', 'Русский', 'ru'),
            _buildLanguageOption('🇩🇪', 'Deutsch', 'de'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String flag, String name, String code) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name),
      onTap: () {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name seçildi')),
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('REEV Points'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versiyon: 1.0.0'),
            SizedBox(height: 8),
            Text('REEV Coffee sadakat programı mobil uygulaması'),
            SizedBox(height: 16),
            Text('© 2024 REEV Coffee'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    // Form alanlarını temizle
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Şifre Değiştir'),
        content: Form(
          key: _changePasswordFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mevcut Şifre',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mevcut şifrenizi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Yeni şifrenizi girin';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre (Tekrar)',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Yeni şifrenizi tekrar girin';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: _isChangingPassword ? null : _changePassword,
            child: _isChangingPassword
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_changePasswordFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isChangingPassword = true);

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

      final response = await apiService.changePassword(
        userId: userId.toString(),
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        headers: authService.getAuthHeaders(),
      );

      if (response['success'] == true && mounted) {
        Navigator.of(context).pop(); // Dialog'u kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifreniz başarıyla değiştirildi'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        final errorMessage = response['error'] ?? 'Şifre değiştirilemedi';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Password change error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şifre değiştirirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Çıkış Yap'),
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
        currentIndex: 0, // Ana sayfa seçili göster
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
