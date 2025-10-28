# IIS Deployment Guide - Cafe Sadakat Uygulaması

## Gereksinimler

### 1. Python Kurulumu
- Python 3.9+ kurulu olmalı
- Python PATH'e eklenmiş olmalı
- Pip package manager aktif olmalı

### 2. IIS Özellikleri
- IIS yüklü ve aktif
- HTTP Platform Handler modülü yüklü
- Application Development Features aktif

## Kurulum Adımları

### 1. Proje Dosyalarını Kopyalama
```
C:\inetpub\wwwroot\cafe-sadakat\
├── app.py
├── wsgi.py
├── web.config
├── requirements.txt
├── runtime.txt
├── .env
├── templates/
├── static/
└── instance/
```

### 2. Python Paketlerini Yükleme
```bash
cd C:\inetpub\wwwroot\cafe-sadakat
pip install -r requirements.txt
```

### 3. Environment Variables (.env)
```
SECRET_KEY=your-secret-key-here
DATABASE_URL=sqlite:///instance/cafe_loyalty.db
MAIL_SERVER=mail.yemenkahvesi.com.tr
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USE_SSL=False
MAIL_USERNAME=your-email@domain.com
MAIL_PASSWORD=your-password
FLASK_ENV=production
```

### 4. IIS Site Yapılandırması

#### A. Yeni Site Oluşturma
1. IIS Manager'ı açın
2. Sites → Add Website
3. Site name: "CafeSadakat"
4. Physical path: `C:\inetpub\wwwroot\cafe-sadakat`
5. Port: 80 (veya istediğiniz port)

#### B. Application Pool Ayarları
1. Application Pools → CafeSadakat
2. .NET CLR Version: "No Managed Code"
3. Managed Pipeline Mode: "Integrated"
4. Identity: ApplicationPoolIdentity

### 5. Web.config Düzenleme
`web.config` dosyasındaki Python path'ini kontrol edin:
```xml
<httpPlatform processPath="c:\python\python.exe"
```
Python kurulum yolunuza göre güncelleyin.

### 6. Permissions Ayarlama
```
C:\inetpub\wwwroot\cafe-sadakat\
├── IIS_IUSRS → Full Control
├── IUSR → Read & Execute
└── Application Pool Identity → Full Control
```

### 7. Database Initialization
İlk çalıştırmada veritabanı otomatik oluşturulacak:
```
instance/cafe_loyalty.db
```

## Test Etme

### 1. Local Test
```bash
python wsgi.py
```

### 2. IIS Test
- Browser'da site adresini açın
- Admin paneline giriş yapın: admin@cafe.com / admin123

## Troubleshooting

### Yaygın Hatalar

#### 1. Python Bulunamıyor
```
Error: Python executable not found
```
**Çözüm:** web.config'deki Python path'ini kontrol edin

#### 2. Module Import Error
```
Error: No module named 'flask'
```
**Çözüm:** requirements.txt'yi tekrar yükleyin

#### 3. Database Permission Error
```
Error: Unable to open database file
```
**Çözüm:** instance/ klasörüne write permission verin

#### 4. Static Files Yüklenmiyor
```
404 Error on CSS/JS files
```
**Çözüm:** IIS'de static content handling aktif edin

### Log Dosyaları
- `python.log` - Python application logs
- IIS logs - `C:\inetpub\logs\LogFiles\`

## Production Optimizasyonu

### 1. Security
- .env dosyasını güvenli konuma taşıyın
- Database şifrelerini güçlendirin
- HTTPS kullanın

### 2. Performance
- Static files için caching aktif edin
- Gzip compression kullanın
- Database connection pooling

### 3. Monitoring
- Application Insights entegrasyonu
- Health check endpoints
- Error logging

## Backup Stratejisi

### 1. Database Backup
```bash
# SQLite backup
copy instance\cafe_loyalty.db backup\cafe_loyalty_backup.db
```

### 2. Application Backup
- Tüm proje klasörünü yedekleyin
- .env dosyasını ayrı yedekleyin

## Support

Sorun yaşadığınızda kontrol edilecekler:
1. Python version compatibility
2. IIS module installation
3. File permissions
4. Environment variables
5. Database connectivity

---
**Not:** Bu guide Windows Server 2016+ ve IIS 10+ için hazırlanmıştır.
