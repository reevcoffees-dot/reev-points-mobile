@echo off
echo Laragon SSL Kurulumu Baslatiliyor...

REM SSL klasorunu olustur
if not exist "C:\laragon\etc\ssl" mkdir "C:\laragon\etc\ssl"

REM Sertifikalari kopyala
copy "cert.pem" "C:\laragon\etc\ssl\laragon.crt"
copy "key.pem" "C:\laragon\etc\ssl\laragon.key"

REM Virtual host yapilandirmasini kopyala
copy "laragon_ssl_config.conf" "C:\laragon\etc\apache2\sites-enabled\auto.websadakat.test.conf"

echo.
echo SSL kurulumu tamamlandi!
echo.
echo Sonraki adimlar:
echo 1. Laragon Control Panel'den Apache'yi yeniden baslatın
echo 2. Flask uygulamasini calistirin: python app.py
echo 3. https://websadakat.test adresine gidin
echo.
pause
