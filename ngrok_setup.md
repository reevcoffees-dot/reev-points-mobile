# Ngrok Kurulumu ve Kullanımı

## 1. Ngrok İndirme ve Kurulum

### Adım 1: Ngrok İndir
1. https://ngrok.com/download adresine gidin
2. Windows için ngrok.exe dosyasını indirin
3. İndirilen dosyayı `C:\Users\Yemen\Desktop\websadakat\` klasörüne koyun

### Adım 2: Ngrok Hesabı Oluştur
1. https://dashboard.ngrok.com/signup adresine gidin
2. Ücretsiz hesap oluşturun
3. Dashboard'dan authtoken'ınızı kopyalayın

### Adım 3: Authtoken Ayarla
```bash
# Terminal'de çalıştırın
ngrok config add-authtoken YOUR_AUTHTOKEN_HERE
```

## 2. Flask Uygulamasını Paylaş

### Adım 1: Flask Uygulamasını Başlat
```bash
python app.py
```

### Adım 2: Ngrok ile Paylaş
```bash
# Yeni terminal açın
ngrok http 1519
```

## 3. Sonuç
Ngrok size şu şekilde URL verecek:
- HTTP: http://abc123.ngrok.io
- HTTPS: https://abc123.ngrok.io

Bu URL'yi diğer kullanıcılarla paylaşabilirsiniz!

## 4. Avantajları
✅ Anında HTTPS
✅ Güvenlik uyarısı yok
✅ Tüm cihazlardan erişim
✅ Kolay paylaşım
