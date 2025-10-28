# REEV Points Mobile App - Kurulum Rehberi

## 🚀 Hızlı Başlangıç

### 1. Flutter Kurulumu
```bash
# Flutter SDK'yı indirin ve PATH'e ekleyin
# https://docs.flutter.dev/get-started/install

# Kurulumu kontrol edin
flutter doctor
```

### 2. Proje Bağımlılıklarını Yükleyin
```bash
cd mobile_app
flutter pub get
```

### 3. API Konfigürasyonu
`lib/utils/app_constants.dart` dosyasında Flask sunucunuzun adresini güncelleyin:

```dart
// Geliştirme için
static const String baseUrl = 'http://localhost:5000';

// Production için
static const String baseUrl = 'https://your-domain.com';
```

### 4. Firebase Kurulumu (Push Notification için)

#### A. Firebase Console'da Proje Oluşturun
1. [Firebase Console](https://console.firebase.google.com/) açın
2. "Add project" tıklayın
3. Proje adı: `reev-points`
4. Analytics'i etkinleştirin

#### B. Android Konfigürasyonu
1. Firebase Console'da "Add app" → Android
2. Package name: `com.reev.points`
3. `google-services.json` dosyasını indirin
4. Dosyayı `android/app/` klasörüne kopyalayın

#### C. iOS Konfigürasyonu
1. Firebase Console'da "Add app" → iOS
2. Bundle ID: `com.reev.points`
3. `GoogleService-Info.plist` dosyasını indirin
4. Dosyayı `ios/Runner/` klasörüne kopyalayın

#### D. Firebase Options Güncelleyin
`lib/firebase_options.dart` dosyasında Firebase console'dan aldığınız değerleri güncelleyin:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'your-actual-api-key',
  appId: 'your-actual-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  storageBucket: 'your-actual-project-id.appspot.com',
);
```

### 5. Uygulamayı Çalıştırın

#### Android
```bash
flutter run
```

#### iOS (macOS gerekli)
```bash
flutter run -d ios
```

#### Web
```bash
flutter run -d web
```

## 🔧 Flask API Entegrasyonu

### Gerekli API Endpoint'leri
Mobil uygulama aşağıdaki endpoint'leri kullanır:

```python
# Kullanıcı işlemleri
POST /api/login
POST /api/register
GET  /api/profile

# Dashboard
GET  /api/dashboard

# QR işlemleri
POST /api/generate-qr
POST /api/scan-qr
POST /api/generate-campaign-qr

# Kampanyalar
GET  /api/campaigns

# Puan kullanma
GET  /api/redeem
POST /api/redeem-product

# Push notification
GET  /api/vapid-key
POST /api/subscribe-notifications
POST /api/unsubscribe-notifications
POST /api/test-notification
```

### Flask API Örnek Endpoint'leri

```python
@app.route('/api/dashboard')
@login_required
def api_dashboard():
    return jsonify({
        'success': True,
        'total_points': current_user.points,
        'recent_activities': [
            {
                'description': 'QR kod tarandı',
                'points': 1,
                'date': '2024-01-01'
            }
        ]
    })

@app.route('/api/generate-qr', methods=['POST'])
@login_required
def api_generate_qr():
    # QR kod oluşturma logic'i
    qr_data = generate_user_qr(current_user.id)
    return jsonify({
        'success': True,
        'qr_data': qr_data
    })

@app.route('/api/scan-qr', methods=['POST'])
@login_required
def api_scan_qr():
    qr_data = request.json.get('qr_data')
    # QR kod işleme logic'i
    points_earned = process_qr_scan(qr_data, current_user.id)
    return jsonify({
        'success': True,
        'message': 'QR kod başarıyla işlendi',
        'points_earned': points_earned
    })
```

## 📱 Test Etme

### 1. Android Emulator
```bash
# Android Studio'da emulator başlatın
flutter run
```

### 2. Fiziksel Cihaz
```bash
# USB debugging etkinleştirin
# Cihazı bağlayın
flutter devices
flutter run -d <device-id>
```

### 3. QR Kod Testi
- Dashboard'da QR kod oluşturun
- QR Scanner ekranında kamerayı test edin
- Web projenizdeki branch panel ile QR kodları test edin

## 🔒 Güvenlik Ayarları

### Android Permissions
`android/app/src/main/AndroidManifest.xml` dosyasında gerekli izinler:
- CAMERA (QR tarama)
- INTERNET (API çağrıları)
- VIBRATE (bildirimler)

### iOS Permissions
`ios/Runner/Info.plist` dosyasında gerekli açıklamalar:
- NSCameraUsageDescription
- NSLocationWhenInUseUsageDescription

## 🚨 Sorun Giderme

### Yaygın Hatalar

#### 1. Firebase Hatası
```
Error: No Firebase App '[DEFAULT]' has been created
```
**Çözüm**: `google-services.json` ve `GoogleService-Info.plist` dosyalarının doğru yerde olduğundan emin olun.

#### 2. API Bağlantı Hatası
```
Network error: Connection refused
```
**Çözüm**: Flask sunucunuzun çalıştığından ve `app_constants.dart`'taki URL'nin doğru olduğundan emin olun.

#### 3. QR Tarama Sorunu
```
Camera permission denied
```
**Çözüm**: Cihaz ayarlarından kamera iznini manuel olarak verin.

### Debug Modu
```bash
# Detaylı log için
flutter run --verbose

# Release build test
flutter run --release
```

## 📦 Production Build

### Android APK
```bash
flutter build apk --release
# Dosya: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Google Play için)
```bash
flutter build appbundle --release
# Dosya: build/app/outputs/bundle/release/app-release.aab
```

### iOS (macOS gerekli)
```bash
flutter build ios --release
# Xcode ile Archive edin
```

## 🔄 Güncelleme Süreci

1. Kod değişikliklerini yapın
2. `pubspec.yaml`'da version numarasını artırın
3. Test edin
4. Build alın
5. App Store/Google Play'e yükleyin

## 📞 Destek

Herhangi bir sorunla karşılaştığınızda:
1. `flutter doctor` çalıştırın
2. Log'ları kontrol edin
3. Firebase Console'u kontrol edin
4. API endpoint'lerini test edin

---

**Not**: Bu mobil uygulama, mevcut Flask web projenizle tam uyumlu çalışır. Aynı veritabanını ve API'leri kullanır.
