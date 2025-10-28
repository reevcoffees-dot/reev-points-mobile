import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _consentGiven = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kişisel verilerin işlenmesi için onay vermelisiniz.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        consentGiven: _consentGiven,
      );

      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarılı! E-posta adresinize doğrulama kodu gönderildi.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // E-posta doğrulama ekranına yönlendir
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: _emailController.text.trim(),
              userId: response['user_id'],
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarısız. Lütfen bilgilerinizi kontrol edin.'),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_add,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Text(
                        'Hesap Oluşturun',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'REEV Points\'e katılın',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Register Form
                Container(
                  decoration: AppTheme.cardDecoration,
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          controller: _nameController,
                          label: 'Ad Soyad',
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ad soyad gerekli';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        CustomTextField(
                          controller: _emailController,
                          label: 'E-posta',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'E-posta adresi gerekli';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Geçerli bir e-posta adresi girin';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        CustomTextField(
                          controller: _phoneController,
                          label: 'Telefon',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Telefon numarası gerekli';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Şifre',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Şifre gerekli';
                            }
                            if (value.length < 6) {
                              return 'Şifre en az 6 karakter olmalı';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Consent Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _consentGiven,
                              onChanged: (value) {
                                setState(() => _consentGiven = value ?? false);
                              },
                              activeColor: AppTheme.primaryColor,
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _consentGiven = !_consentGiven);
                                },
                                child: Text(
                                  'Kişisel verilerimin işlenmesine ve KVKK kapsamında bilgilendirilmeme onay veriyorum.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        CustomButton(
                          text: 'Kayıt Ol',
                          onPressed: _isLoading ? null : _register,
                          isLoading: _isLoading,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Login Link
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: RichText(
                            text: TextSpan(
                              text: 'Zaten hesabınız var mı? ',
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: const [
                                TextSpan(
                                  text: 'Giriş Yapın',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
