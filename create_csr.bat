@echo off
cd /d "%~dp0"

echo Creating private key...
"C:\Program Files\Git\usr\bin\openssl.exe" genrsa -out private_key.pem 2048

echo Creating CSR...
"C:\Program Files\Git\usr\bin\openssl.exe" req -new -key private_key.pem -out CertificateSigningRequest.certSigningRequest -subj "/C=TR/ST=Istanbul/L=Istanbul/O=REEV/OU=Mobile/CN=REEV Points Distribution/emailAddress=reev@example.com"

echo Done! Files created:
echo - private_key.pem
echo - CertificateSigningRequest.certSigningRequest

pause
