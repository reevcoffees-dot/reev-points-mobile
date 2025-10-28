/**
 * Basit HTTP uyumlu QR Scanner - jsQR kullanarak
 */

class SimpleQRScanner {
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

        // Canvas oluştur
        this.canvasElement = document.createElement('canvas');
        this.context = this.canvasElement.getContext('2d');

        this.resultsElement.innerHTML = 
            '<div class="alert alert-info"><i class="fas fa-camera"></i> <strong>Basit QR Scanner Başlatılıyor...</strong></div>';

        try {
            // Basit kamera erişimi
            const stream = await navigator.mediaDevices.getUserMedia({
                video: { 
                    facingMode: 'environment',
                    width: 640,
                    height: 480
                }
            });

            this.videoElement.srcObject = stream;
            
            this.videoElement.onloadedmetadata = () => {
                this.videoElement.play().then(() => {
                    console.log('Video başlatıldı');
                    this.startFrameCapture();
                    
                    this.resultsElement.innerHTML = 
                        '<div class="alert alert-success"><i class="fas fa-camera"></i> <strong>QR Scanner Aktif!</strong><br>' +
                        'QR kodunu kameraya gösterin.</div>';
                });
            };

        } catch (error) {
            console.error('Kamera hatası:', error);
            this.handleCameraError(error);
        }
    }

    startFrameCapture() {
        // Her 200ms'de bir QR tarama
        this.scanInterval = setInterval(() => {
            this.scanFrame();
        }, 200);
    }

    scanFrame() {
        if (!this.videoElement || this.videoElement.readyState !== 4) {
            return;
        }

        try {
            // Video boyutlarını al
            this.canvasElement.width = this.videoElement.videoWidth;
            this.canvasElement.height = this.videoElement.videoHeight;
            
            // Video frame'ini canvas'a çiz
            this.context.drawImage(
                this.videoElement, 
                0, 0, 
                this.canvasElement.width, 
                this.canvasElement.height
            );

            // Canvas'tan ImageData al
            const imageData = this.context.getImageData(
                0, 0, 
                this.canvasElement.width, 
                this.canvasElement.height
            );

            // jsQR ile QR kod ara
            if (typeof jsQR !== 'undefined') {
                const qrCode = jsQR(imageData.data, imageData.width, imageData.height);
                
                if (qrCode) {
                    console.log('QR kod bulundu:', qrCode.data);
                    this.onQRCodeFound(qrCode.data);
                }
            }

        } catch (error) {
            console.error('Frame tarama hatası:', error);
        }
    }

    onQRCodeFound(qrData) {
        console.log('QR kod okundu:', qrData);
        
        this.resultsElement.innerHTML = 
            `<div class="alert alert-success"><i class="fas fa-check-circle"></i> <strong>QR Kod Bulundu!</strong><br>` +
            `Kod: <code>${qrData}</code></div>`;

        // QR kodunu input alanına yaz
        const qrInput = document.getElementById('customer_qr_code');
        if (qrInput) {
            qrInput.value = qrData;
            console.log('QR kod input alanına yazıldı');
        }

        // Modal'ı kapat
        const modal = bootstrap.Modal.getInstance(document.getElementById('cameraModal'));
        if (modal) {
            modal.hide();
        }

        // Taramayı durdur
        this.stopScanning();
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
        let errorMessage = 'Kamera hatası: ' + error.message;
        
        this.resultsElement.innerHTML = 
            `<div class="alert alert-danger"><i class="fas fa-exclamation-triangle"></i> <strong>Hata!</strong><br>` +
            `${errorMessage}<br><br>` +
            `<strong>Alternatif:</strong> "Fotoğraf Çek/Seç" butonunu kullanın.</div>`;
        
        this.isScanning = false;
    }
}

// Global instance
const simpleQRScanner = new SimpleQRScanner();
