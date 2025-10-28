# Laragon SSL Kurulumu - Websadakat Projesi

## 1. SSL Sertifikası Oluşturma
```bash
# Proje klasöründe SSL sertifikası oluşturun
cd C:\Users\Yemen\Desktop\websadakat
python generate_ssl.py
```

## 2. Laragon SSL Klasörü Hazırlama
```bash
# Laragon SSL klasörünü oluşturun (yoksa)
mkdir C:\laragon\etc\ssl

# Sertifikaları Laragon SSL klasörüne kopyalayın
copy cert.pem C:\laragon\etc\ssl\laragon.crt
copy key.pem C:\laragon\etc\ssl\laragon.key
```

## 3. Apache SSL Modüllerini Etkinleştirme
`C:\laragon\etc\apache2\httpd.conf` dosyasında şu satırların açık olduğundan emin olun:
```apache
LoadModule ssl_module modules/mod_ssl.so
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule headers_module modules/mod_headers.so
Include conf/extra/httpd-ssl.conf
```

## 4. Virtual Host Yapılandırması
`laragon_ssl_config.conf` dosyasını şu konuma kopyalayın:
```
C:\laragon\etc\apache2\sites-enabled\auto.websadakat.test.conf
```

## 5. Flask Uygulamasını Başlatma
```bash
# Proje klasöründe Flask uygulamasını başlatın
cd C:\Users\Yemen\Desktop\websadakat
python app.py
```

## 6. Laragon'u Yeniden Başlatma
- Laragon Control Panel'den Apache'yi durdurun
- Apache'yi tekrar başlatın
- "SSL" butonunun aktif olduğundan emin olun

## 7. Erişim URL'leri
- **HTTPS Ana Sayfa**: https://websadakat.test
- **HTTPS Branch Login**: https://websadakat.test/branch/login  
- **HTTPS Admin Panel**: https://websadakat.test/admin

## 8. Tarayıcı Güvenlik Uyarısı
Self-signed sertifika kullandığınız için tarayıcı güvenlik uyarısı verecek:
- Chrome: "Advanced" → "Proceed to websadakat.test (unsafe)"
- Firefox: "Advanced" → "Accept the Risk and Continue"

## 9. Sertifikayı Güvenilir Hale Getirme (İsteğe Bağlı)
Windows'ta sertifikayı güvenilir hale getirmek için:
1. `cert.pem` dosyasına çift tıklayın
2. "Install Certificate" → "Local Machine" → "Next"
3. "Place all certificates in the following store" → "Browse"
4. "Trusted Root Certification Authorities" seçin → "OK" → "Next" → "Finish"

## 10. Test Etme
```bash
# SSL bağlantısını test etmek için
curl -k https://websadakat.test
```

## Sorun Giderme
- **Apache başlamıyorsa**: SSL modüllerinin yüklendiğini kontrol edin
- **Sertifika hatası**: Dosya yollarının doğru olduğunu kontrol edin
- **Port çakışması**: 443 portunun başka bir uygulama tarafından kullanılmadığını kontrol edin
