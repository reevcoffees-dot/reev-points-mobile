import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  List<dynamic> _branches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      final response = await apiService.get(
        '/api/branches',
        headers: authService.getAuthHeaders(),
      );
      
      if (mounted) {
        setState(() {
          _branches = response['branches'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Şubeler yüklenirken hata: $e')),
        );
      }
    }
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
                        'Şubelerimiz',
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
                        onRefresh: _loadBranches,
                        child: _branches.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.store,
                                      size: 64,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Şube bilgisi bulunamadı',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _branches.length,
                                itemBuilder: (context, index) {
                                  final branch = _branches[index];
                                  return _buildBranchCard(branch);
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

  Widget _buildBranchCard(Map<String, dynamic> branch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branch Banner Image (if available)
            if (branch['image_url'] != null && branch['image_url'].toString().isNotEmpty)
              Container(
                width: double.infinity,
                height: 120,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    branch['image_url'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.store,
                            color: AppTheme.primaryColor,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            Row(
              children: [
                // Branch Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch['name'] ?? 'Şube Adı',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (branch['working_hours'] != null)
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              branch['working_hours'],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                
                // Status Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (branch['is_active'] == true) ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (branch['is_active'] == true) ? 'Açık' : 'Kapalı',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Address
            if (branch['address'] != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      branch['address'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 8),
            
            // Phone
            if (branch['phone'] != null)
              Row(
                children: [
                  const Icon(
                    Icons.phone,
                    size: 16,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    branch['phone'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Harita uygulamasında aç
                      _openInMaps(branch['address'] ?? '');
                    },
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('Yol Tarifi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Telefon uygulamasında aç
                      _callBranch(branch['phone'] ?? '');
                    },
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Ara'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openInMaps(String address) {
    // TODO: Harita uygulamasında açma işlemi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Yol tarifi: $address')),
    );
  }

  void _callBranch(String phone) {
    // TODO: Telefon arama işlemi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Aranıyor: $phone')),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          currentIndex: 4, // Şubelerimiz sekmesi aktif
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.of(context).pushReplacementNamed('/dashboard');
                break;
              case 1:
                Navigator.of(context).pushReplacementNamed('/campaigns');
                break;
              case 2:
                // QR oluşturma işlemi - dashboard'a git
                Navigator.of(context).pushReplacementNamed('/dashboard');
                break;
              case 3:
                Navigator.of(context).pushReplacementNamed('/redeem');
                break;
              case 4:
                // Zaten şubeler sayfasındayız, hiçbir şey yapma
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
}
