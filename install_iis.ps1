# IIS ve HTTP Platform Handler Kurulum Script'i
# PowerShell'i Administrator olarak çalıştırın

Write-Host "IIS ve HTTP Platform Handler kuruluyor..." -ForegroundColor Green

# IIS özelliklerini aktif et
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security
Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering
Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent
Enable-WindowsOptionalFeature -Online -FeatureName IIS-DefaultDocument
Enable-WindowsOptionalFeature -Online -FeatureName IIS-DirectoryBrowsing
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45

Write-Host "HTTP Platform Handler indiriliyor..." -ForegroundColor Yellow

# HTTP Platform Handler'ı indir ve kur
$url = "https://download.microsoft.com/download/4/9/c/49cd28db-4aa6-4a51-9437-20eba5d6d9b5/DotNetCore.1.0.0-WindowsHosting.exe"
$output = "$env:TEMP\DotNetCore.WindowsHosting.exe"

try {
    Invoke-WebRequest -Uri $url -OutFile $output
    Start-Process -FilePath $output -ArgumentList "/quiet" -Wait
    Write-Host "HTTP Platform Handler kuruldu!" -ForegroundColor Green
} catch {
    Write-Host "HTTP Platform Handler manuel olarak kurulmalı:" -ForegroundColor Red
    Write-Host "https://www.microsoft.com/web/downloads/platform.aspx" -ForegroundColor Yellow
}

# IIS'i yeniden başlat
Write-Host "IIS yeniden başlatılıyor..." -ForegroundColor Yellow
iisreset

Write-Host "Kurulum tamamlandı! IIS Manager'ı açabilirsiniz." -ForegroundColor Green
Write-Host "Sonraki adım: Site oluşturma ve proje dosyalarını kopyalama" -ForegroundColor Cyan
