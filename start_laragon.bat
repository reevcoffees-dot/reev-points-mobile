@echo off
title Laragon ve Flask Uygulamasi Baslat
echo ========================================
echo    LARAGON VE FLASK UYGULAMASI BASLAT
echo ========================================
echo.

REM Laragon'un kurulu olup olmadığını kontrol et
if not exist "C:\laragon\laragon.exe" (
    echo HATA: Laragon bulunamadi!
    echo Lutfen Laragon'u kurun: https://laragon.org/
    pause
    exit /b 1
)

echo [1/4] Laragon baslatiliyor...
start "" "C:\laragon\laragon.exe"
timeout /t 5 /nobreak >nul

echo [2/4] Apache ve MySQL servisleri bekleniyor...
timeout /t 10 /nobreak >nul

echo [3/4] Proje klasoru kontrol ediliyor...
if not exist "C:\laragon\www\websadakat" (
    echo UYARI: Proje klasoru bulunamadi!
    echo Projeyi C:\laragon\www\websadakat klasorune kopyalayin
    pause
)

echo [4/4] Flask uygulamasi baslatiliyor...
cd /d "C:\laragon\www\websadakat"

REM Python ve pip kontrolü
python --version >nul 2>&1
if errorlevel 1 (
    echo HATA: Python bulunamadi!
    echo Lutfen Python'u kurun veya PATH'e ekleyin
    pause
    exit /b 1
)

REM Gerekli paketleri kur
echo Gerekli paketler kontrol ediliyor...
pip install -r requirements.txt >nul 2>&1

echo.
echo ========================================
echo Flask uygulamasi baslatiliyor...
echo URL: http://websadakat.test
echo Alternatif: http://127.0.0.1:5000
echo ========================================
echo.

REM Flask uygulamasını başlat
python app.py

echo.
echo Uygulama kapatildi.
pause
