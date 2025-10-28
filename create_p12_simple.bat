@echo off
cd /d "%~dp0"

echo Creating P12 with password: MyStrongPassword123
"C:\Program Files\Git\usr\bin\openssl.exe" pkcs12 -export -out distribution_certificate.p12 -inkey private_key.pem -in ios_distribution.pem -passout pass:MyStrongPassword123

echo P12 file created with password: MyStrongPassword123
echo Remember this password for GitHub Secrets!

pause
