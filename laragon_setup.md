# Laragon ile Flask Uygulaması Kurulumu

## 1. Laragon Kurulumu
- Laragon'u indirin ve kurun: https://laragon.org/
- Full sürümünü tercih edin (Apache, MySQL, PHP, Node.js dahil)

## 2. Python Kurulumu
```bash
# Laragon Terminal'de
python --version
pip --version
```

## 3. Proje Klasörü Ayarları
```bash
# Laragon www klasörüne proje kopyalayın
C:\laragon\www\websadakat\
```

## 4. Virtual Host Oluşturma
Laragon otomatik virtual host oluşturur:
- Klasör adı: `websadakat`
- URL: `http://websadakat.test`

## 5. Apache Konfigürasyonu
`C:\laragon\etc\apache2\sites-enabled\auto.websadakat.test.conf` dosyası:

```apache
<VirtualHost *:80>
    DocumentRoot "C:/laragon/www/websadakat/"
    ServerName websadakat.test
    ServerAlias *.websadakat.test
    
    # Python Flask için proxy ayarları
    ProxyPreserveHost On
    ProxyRequests Off
    ProxyPass / http://127.0.0.1:5000/
    ProxyPassReverse / http://127.0.0.1:5000/
    
    # Gerekli modüller
    LoadModule proxy_module modules/mod_proxy.so
    LoadModule proxy_http_module modules/mod_proxy_http.so
</VirtualHost>
```

## 6. Flask Uygulaması Başlatma
```bash
# Proje klasöründe
cd C:\laragon\www\websadakat
pip install -r requirements.txt
python app.py
```

## 7. Otomatik Başlatma (İsteğe Bağlı)
`start_flask.bat` dosyası oluşturun:
```batch
@echo off
cd /d "C:\laragon\www\websadakat"
python app.py
```

## 8. Erişim
- Ana sayfa: http://websadakat.test
- Branch login: http://websadakat.test/branch/login
- Admin panel: http://websadakat.test/admin
