import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class ProductApprovalScreen extends StatefulWidget {
  const ProductApprovalScreen({super.key});

  @override
  State<ProductApprovalScreen> createState() => _ProductApprovalScreenState();
}

class _ProductApprovalScreenState extends State<ProductApprovalScreen> {
  List<dynamic> _pendingProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingProducts();
  }

  Future<void> _loadPendingProducts() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Check if user is authenticated
      if (!authService.isAuthenticated || authService.user == null) {
        return;
      }
      
      final userId = authService.user!['id'];
      final response = await apiService.get(
        '/api/pending-products?user_id=$userId',
        headers: authService.getAuthHeaders(),
      );
      
      if (mounted) {
        setState(() {
          _pendingProducts = response['pending_products'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bekleyen ürünler yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _approveProduct(Map<String, dynamic> product) async {
    final int productPoints = (product['points'] as num?)?.toInt() ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ürün Onayı'),
        content: Text(
          '${product['name']} ürününü onaylamak istediğinizden emin misiniz?\n\n'
          'Bu işlem sonucunda $productPoints puan hesabınızdan düşülecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _processApproval(product);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }

  Future<void> _processApproval(Map<String, dynamic> product) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      final response = await apiService.approveProduct(
        productId: product['id'].toString(),
        userId: authService.user!['id'].toString(),
        headers: authService.getAuthHeaders(),
      );
      
      if (response['success'] == true && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Ürün başarıyla onaylandı!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Show point deduction notification
        final pointsDeducted = response['points_deducted'] ?? product['points'];
        _showPointDeductionDialog(pointsDeducted, product['name']);
        
        // Refresh data
        _loadPendingProducts();
        
        // Update user points in AuthService
        if (response['new_user_points'] != null) {
          final updatedUser = Map<String, dynamic>.from(authService.user!);
          updatedUser['points'] = response['new_user_points'];
          authService.updateUser(updatedUser);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Onaylama işlemi başarısız'),
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

  void _showPointDeductionDialog(int pointsDeducted, String productName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cardDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 30,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Ürün Onaylandı!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '$productName ürünü başarıyla onaylandı.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
              
              // Points Deducted Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.remove_circle,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Düşülen Puan',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pointsDeducted Puan',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
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
                        backgroundColor: AppTheme.primaryColor,
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
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ürün Onayları',
                        style: Theme.of(context).textTheme.headlineMedium,
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
                        onRefresh: _loadPendingProducts,
                        child: _pendingProducts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.approval,
                                      size: 64,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Onay bekleyen ürün bulunmuyor',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _pendingProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _pendingProducts[index];
                                  return _buildPendingProductCard(product);
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingProductCard(Map<String, dynamic> product) {
    final int productPoints = (product['points'] as num?)?.toInt() ?? 0;
    final String status = product['status'] ?? 'pending';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Product Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product['image_url'] != null && product['image_url'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.redeem,
                                color: AppTheme.primaryColor,
                                size: 30,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.redeem,
                          color: AppTheme.primaryColor,
                          size: 30,
                        ),
                ),
                
                const SizedBox(width: 16),
                
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? '',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Talep Tarihi: ${product['request_date'] ?? ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Points and Action
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
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
                    
                    const SizedBox(height: 8),
                    
                    if (status == 'pending')
                      ElevatedButton(
                        onPressed: () => _approveProduct(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Onayla',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Onay Bekliyor';
      case 'approved':
        return 'Onaylandı';
      case 'rejected':
        return 'Reddedildi';
      default:
        return 'Bilinmiyor';
    }
  }
}
