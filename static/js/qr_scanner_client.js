/**
 * Yerel OpenCV + PyZbar QR Scanner Client
 */

class LocalQRScanner {
    constructor() {
        this.isScanning = false;
        this.videoElement = null;
        this.canvasElement = null;
        this.context = null;
        this.scanInterval = null;
    }

    async startScanning(videoElementId, resultsElementId) {
        if (this.isScanning) {
            console.log('Zaten tarama yapılıyor');
            return;
        }

        this.isScanning = true;
        this.videoElement = document.getElementById(videoElementId);
        this.resultsElement = document.getElementById(resultsElementId);
        
        if (!this.videoElement) {
            console.error('Video element bulunamadı!');
            return;
        }

        // Canvas oluştur (görünmez)
        this.canvasElement = document.createElement('canvas');
        this.context = this.canvasElement.getContext('2d');

        this.resultsElement.innerHTML = 
            '<div class="alert alert-info"><i class="fas fa-camera"></i> <strong>Kamera Kontrolü Yapılıyor...</strong></div>';

        // Navigator ve mediaDevices kontrolü
        if (!navigator) {
            this.handleCameraError(new Error('Navigator desteklenmiyor'));
            return;
        }

        if (!navigator.mediaDevices) {
            this.handleCameraError(new Error('MediaDevices API desteklenmiyor (HTTPS gerekli)'));
            return;
        }

        if (!navigator.mediaDevices.getUserMedia) {
            this.handleCameraError(new Error('getUserMedia desteklenmiyor'));
            return;
        }

        try {
            const stream = await navigator.mediaDevices.getUserMedia({
                video: {
                    facingMode: { ideal: 'environment' },
                    width: { min: 320, ideal: 640, max: 1280 },
                    height: { min: 240, ideal: 480, max: 720 }
                }
            });

            this.videoElement.srcObject = stream;
            
            this.videoElement.onloadedmetadata = () => {
                this.videoElement.play().then(() => {
                    console.log('Video başarıyla başlatıldı');
                    this.startFrameCapture();
                    
                    this.resultsElement.innerHTML = 
                        '<div class="alert alert-success"><i class="fas fa-camera"></i> <strong>Yerel OpenCV Scanner Aktif!</strong><br>' +
                        'QR kodunu kameraya gösterin, otomatik okunacak.</div>';
                });
            };

        } catch (error) {
            console.error('Kamera erişim hatası:', error);
            this.handleCameraError(error);
        }
    }

    startFrameCapture() {
        // Her 300ms'de bir frame yakala ve analiz et (daha hızlı tarama)
        this.scanInterval = setInterval(() => {
            this.captureAndAnalyze();
        }, 300);
    }

    async captureAndAnalyze() {
        if (!this.videoElement || this.videoElement.readyState !== 4) {
            return;
        }

        try {
            // Video frame'ini canvas'a çiz
            this.canvasElement.width = this.videoElement.videoWidth;
            this.canvasElement.height = this.videoElement.videoHeight;
            
            this.context.drawImage(
                this.videoElement, 
                0, 0, 
                this.canvasElement.width, 
                this.canvasElement.height
            );

            // Canvas'ı base64'e çevir
            const base64Image = this.canvasElement.toDataURL('image/jpeg', 0.8);

            // Backend'e gönder
            const response = await fetch('/scan_qr_local', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    image: base64Image
                })
            });

            const result = await response.json();

            if (result.success && result.data) {
                console.log('QR kod bulundu:', result.data);
                this.onQRCodeFound(result.data, result.method || 'OpenCV + PyZbar');
            } else if (result.error && !result.error.includes('QR kod bulunamadı')) {
                // Sadece gerçek hataları logla, "QR kod bulunamadı" normal durum
                console.warn('QR tarama hatası:', result.error);
            }

        } catch (error) {
            console.error('Frame analiz hatası:', error);
        }
    }

    onQRCodeFound(qrData, method) {
        console.log(`QR kod okundu (${method}):`, qrData);
        
        this.resultsElement.innerHTML = 
            `<div class="alert alert-success"><i class="fas fa-check-circle"></i> <strong>QR Kod Bulundu!</strong><br>` +
            `Yöntem: ${method}<br>` +
            `Kod: <code>${qrData}</code></div>`;

        // QR kodunu input alanına yaz
        const qrInput = document.getElementById('customer_qr_code');
        if (qrInput) {
            qrInput.value = qrData;
            console.log('QR kod input alanına yazıldı:', qrData);
        }

        // Modal'ı kapat
        const modal = bootstrap.Modal.getInstance(document.getElementById('cameraModal'));
        if (modal) {
            modal.hide();
        }

        // Taramayı durdur
        this.stopScanning();
        
        // Otomatik işlem yapmak istiyorsanız bu satırı açın:
        // if (typeof processQRCode === 'function') {
        //     processQRCode(qrData);
        // }
    }

    stopScanning() {
        this.isScanning = false;
        
        if (this.scanInterval) {
            clearInterval(this.scanInterval);
            this.scanInterval = null;
        }

        if (this.videoElement && this.videoElement.srcObject) {
            const tracks = this.videoElement.srcObject.getTracks();
            tracks.forEach(track => track.stop());
            this.videoElement.srcObject = null;
        }

        console.log('QR tarama durduruldu');
    }

    handleCameraError(error) {
        let errorMessage = 'Kamera erişim hatası: ';
        let instructions = '';
        
        if (error.name === 'NotAllowedError') {
            errorMessage += 'Kamera izni reddedildi.';
            instructions = '<br><strong>Çözüm:</strong><br>' +
                          '• Tarayıcı adres çubuğundaki kamera simgesine tıklayın<br>' +
                          '• "İzin ver" seçeneğini seçin<br>' +
                          '• Sayfayı yenileyin ve tekrar deneyin';
        } else if (error.name === 'NotFoundError') {
            errorMessage += 'Kamera bulunamadı.';
            instructions = '<br><strong>Kontrol edin:</strong><br>' +
                          '• Cihazınızda kamera olduğundan emin olun<br>' +
                          '• Başka bir uygulama kamerayı kullanmıyor olsun';
        } else if (error.name === 'NotSupportedError' || error.message.includes('HTTPS gerekli')) {
            errorMessage += 'HTTPS gerekli veya MediaDevices desteklenmiyor.';
            instructions = '<br><strong>Mobil HTTP Çözümü:</strong><br>' +
                          '• <strong>"Fotoğraf Çek/Seç"</strong> butonunu kullanın<br>' +
                          '• Bu mobil cihazlarda HTTP üzerinde çalışır<br>' +
                          '• Kamera uygulaması açılır ve QR okur';
        } else if (error.message.includes('MediaDevices API desteklenmiyor')) {
            errorMessage += 'Bu tarayıcı kamera API\'sini desteklemiyor.';
            instructions = '<br><strong>Alternatif Çözüm:</strong><br>' +
                          '• <strong>"Fotoğraf Çek/Seç"</strong> butonunu kullanın<br>' +
                          '• Mobil cihazlarda daha uyumlu çalışır<br>' +
                          '• Manuel QR girişi de yapabilirsiniz';
        } else {
            errorMessage += error.message;
            instructions = '<br><strong>Genel Çözümler:</strong><br>' +
                          '• <strong>"Fotoğraf Çek/Seç"</strong> butonunu deneyin<br>' +
                          '• Sayfayı yenileyin<br>' +
                          '• Farklı bir tarayıcı deneyin';
        }

        this.resultsElement.innerHTML = 
            `<div class="alert alert-danger"><i class="fas fa-exclamation-triangle"></i> <strong>Hata!</strong><br>${errorMessage}${instructions}</div>`;
        
        this.isScanning = false;
    }
}

// Global instance
const localQRScanner = new LocalQRScanner();
