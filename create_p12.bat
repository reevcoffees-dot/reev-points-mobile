@echo off
cd /d "%~dp0"

echo Converting .cer to .pem...
"C:\Program Files\Git\usr\bin\openssl.exe" x509 -inform DER -outform PEM -in ios_distribution.cer -out ios_distribution.pem

echo Creating P12 file...
echo You will be asked to enter a password for the P12 file. Please use a strong password and remember it!
"C:\Program Files\Git\usr\bin\openssl.exe" pkcs12 -export -out distribution_certificate.p12 -inkey private_key.pem -in ios_distribution.pem

echo Done! P12 file created: distribution_certificate.p12
echo Remember the password you entered - you'll need it for GitHub Secrets!

pause
