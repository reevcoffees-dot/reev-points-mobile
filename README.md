# REEV Points Mobile App

REEV Coffee sadakat programı için Flutter mobil uygulaması. Web projesiyle aynı tasarım ve renklere sahip, tam entegre bir mobil deneyim sunar.

## 🚀 Özellikler

### 🔐 Kullanıcı Yönetimi
- Kullanıcı kayıt ve giriş sistemi
- E-posta doğrulaması
- Güvenli oturum yönetimi
- Profil yönetimi

### 📱 QR Kod Sistemi
- QR kod oluşturma (puan kazanmak için)
- QR kod tarama (kamera ile)
- Kampanya QR kodları
- Gerçek zamanlı QR işleme

### 🎯 Puan Sistemi
- Puan kazanma ve kullanma
- Puan bakiyesi takibi
- İşlem geçmişi
- Ödül ürünleri

### 🎪 Kampanya Yönetimi
- Aktif kampanyalar listesi
- Kampanya QR kodları
- Ürün seçimi ve indirimler
- Şube bazlı kampanyalar

### 🔔 Bildirimler
- Push notification desteği
- Firebase Cloud Messaging
- Yerel bildirimler
- Puan kazanma bildirimleri

## 🎨 Tasarım

Web projesiyle %100 uyumlu tasarım:
- **Renkler**: Aynı renk paleti (#8B4513, #D2691E, #F4A460, #A6DBB8, #4D705C)
- **Glassmorphism**: Cam efekti kartlar
- **Gradient**: Arka plan renk geçişleri
- **Typography**: Segoe UI font ailesi
- **Animasyonlar**: Hover ve geçiş efektleri

## 📁 Proje Yapısı

```
lib/
├── main.dart                 # Ana uygulama
├── screens/                  # Ekranlar
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── dashboard_screen.dart
│   ├── campaigns_screen.dart
│   ├── redeem_screen.dart
│   ├── qr_scanner_screen.dart
│   └── profile_screen.dart
├── services/                 # Servisler
│   ├── auth_service.dart
│   ├── api_service.dart
│   └── notification_service.dart
├── widgets/                  # Özel widget'lar
│   ├── custom_button.dart
│   └── custom_text_field.dart
└── utils/                    # Yardımcı dosyalar
    ├── app_theme.dart
    └── app_constants.dart
```

## 🛠️ Kurulum

### Gereksinimler
- Flutter SDK (3.0.0+)
- Dart SDK
- Android Studio / VS Code
- Firebase hesabı (push notification için)

### Adımlar

1. **Bağımlılıkları yükleyin:**
```bash
flutter pub get
```

2. **Firebase yapılandırması:**
   - Firebase Console'da proje oluşturun
   - `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarını ekleyin
   - Push notification için gerekli izinleri ayarlayın

3. **API URL'sini ayarlayın:**
   - `lib/utils/app_constants.dart` dosyasında `baseUrl`'i Flask sunucunuzun adresine güncelleyin

4. **Uygulamayı çalıştırın:**
```bash
flutter run
```

## 🔧 Konfigürasyon

### API Entegrasyonu
Flask sunucunuzla entegrasyon için `app_constants.dart` dosyasında API endpoint'lerini ayarlayın:

```dart
static const String baseUrl = 'http://your-server.com'; // Production
// static const String baseUrl = 'http://localhost:5000'; // Development
```

### Firebase Push Notifications
1. Firebase Console'da FCM'i etkinleştirin
2. VAPID anahtarlarını oluşturun
3. Android/iOS için gerekli konfigürasyonları yapın

## 📱 Ekranlar

### 🏠 Ana Sayfa (Dashboard)
- Kullanıcı puanları
- QR kod oluşturma
- Hızlı erişim butonları
- Son aktiviteler

### 📷 QR Tarayıcı
- Kamera ile QR kod tarama
- Gerçek zamanlı işleme
- Flash ve kamera değiştirme
- Başarı/hata bildirimleri

### 🎯 Kampanyalar
- Aktif kampanyalar listesi
- Kampanya detayları
- Ürün seçimi
- Kampanya QR oluşturma

### 🎁 Puan Kullan
- Ödül ürünleri
- Kategori filtreleme
- Puan ile satın alma
- Stok durumu

### 👤 Profil
- Kullanıcı bilgileri
- Ayarlar menüsü
- Dil seçimi
- Çıkış işlemi

## 🔐 Güvenlik

- Güvenli token tabanlı kimlik doğrulama
- HTTPS API iletişimi
- Şifreli yerel veri saklama
- Input validasyonu
- XSS koruması

## 🌐 Çok Dil Desteği

Desteklenen diller:
- 🇹🇷 Türkçe (varsayılan)
- 🇺🇸 İngilizce
- 🇷🇺 Rusça
- 🇩🇪 Almanca

## 📊 Performans

- Lazy loading
- Image caching
- Efficient state management
- Minimal API calls
- Optimized animations

## 🧪 Test

```bash
# Unit testler
flutter test

# Widget testler
flutter test test/widget_test.dart

# Integration testler
flutter drive --target=test_driver/app.dart
```

## 📦 Build

### Android APK
```bash
flutter build apk --release
```

### iOS IPA
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 📞 İletişim

- **Proje**: REEV Points Mobile
- **Versiyon**: 1.0.0
- **Platform**: Flutter
- **Minimum SDK**: Android 21+ / iOS 11+

---

**Not**: Bu mobil uygulama, mevcut Flask web projenizle tam uyumlu çalışacak şekilde tasarlanmıştır. Aynı API endpoint'lerini kullanır ve aynı veritabanı yapısını destekler.
