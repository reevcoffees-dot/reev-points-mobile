@echo off
echo SSL Sertifikasini Windows'a guvenilir olarak ekleniyor...

REM Sertifikayi Trusted Root Certification Authorities'e ekle
certlm.msc /s /r localMachine /store root cert.pem

echo.
echo Alternatif yontem:
echo 1. cert.pem dosyasina cift tiklayin
echo 2. "Install Certificate" butonuna tiklayin
echo 3. "Local Machine" secin ve "Next" tiklayin
echo 4. "Place all certificates in the following store" secin
echo 5. "Browse" tiklayin ve "Trusted Root Certification Authorities" secin
echo 6. "OK" ve "Next" tiklayin
echo 7. "Finish" tiklayin
echo.
echo Sertifika yuklendikten sonra tarayiciyi yeniden baslatın.
echo.
pause
