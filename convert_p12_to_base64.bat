@echo off
cd /d "%~dp0"

echo Converting P12 to Base64...
powershell -Command "[Convert]::ToBase64String([IO.File]::ReadAllBytes('distribution_certificate.p12')) | Out-File -FilePath 'certificate_base64.txt' -Encoding ASCII"

echo Done! Base64 content saved to: certificate_base64.txt
echo Copy this content to GitHub Secrets as CERTIFICATES_P12

pause
