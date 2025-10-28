#!/usr/bin/env python3
"""
OpenCV ile QR kod okuma servisi
"""
import cv2
import numpy as np
import base64
from io import BytesIO
from PIL import Image

class QRScanner:
    def __init__(self):
        self.detector = cv2.QRCodeDetector()
    
    def decode_from_base64(self, base64_image):
        """Base64 görüntüden QR kod okur"""
        try:
            # Base64 string kontrolü
            if ',' in base64_image:
                image_data = base64.b64decode(base64_image.split(',')[1])
            else:
                image_data = base64.b64decode(base64_image)
            
            # PIL Image oluştur
            image = Image.open(BytesIO(image_data))
            
            # PIL'i numpy array'e çevir
            image_array = np.array(image)
            
            # Array boyut ve tip kontrolü
            if image_array.size == 0:
                return {'success': False, 'error': 'Boş görüntü verisi'}
            
            # Görüntü formatını kontrol et ve düzelt
            if len(image_array.shape) == 3:
                if image_array.shape[2] == 4:  # RGBA
                    opencv_image = cv2.cvtColor(image_array, cv2.COLOR_RGBA2BGR)
                elif image_array.shape[2] == 3:  # RGB
                    opencv_image = cv2.cvtColor(image_array, cv2.COLOR_RGB2BGR)
                else:
                    return {'success': False, 'error': 'Desteklenmeyen görüntü formatı'}
            elif len(image_array.shape) == 2:  # Grayscale
                opencv_image = image_array
            else:
                return {'success': False, 'error': 'Geçersiz görüntü boyutları'}
            
            # Veri tipini uint8'e çevir
            if opencv_image.dtype != np.uint8:
                opencv_image = opencv_image.astype(np.uint8)
            
            return self.decode_from_opencv(opencv_image)
            
        except Exception as e:
            return {'success': False, 'error': f'Base64 decode hatası: {str(e)}'}
    
    def decode_from_opencv(self, image):
        """OpenCV görüntüsünden QR kod okur"""
        try:
            # Görüntü geçerlilik kontrolü
            if image is None or image.size == 0:
                return {'success': False, 'error': 'Geçersiz görüntü verisi'}
            
            # Veri tipini kontrol et
            if image.dtype != np.uint8:
                image = image.astype(np.uint8)
            
            # OpenCV QRCodeDetector ile orijinal görüntü dene
            try:
                data, bbox, _ = self.detector.detectAndDecode(image)
                if data:
                    return {
                        'success': True,
                        'data': data,
                        'method': 'OpenCV QRCodeDetector (Orijinal)'
                    }
            except Exception as opencv_error:
                print(f"OpenCV orijinal hatası: {opencv_error}")
            
            # OpenCV QRCodeDetector ile iyileştirilmiş görüntü dene
            try:
                enhanced_image = self.enhance_image(image)
                data, bbox, _ = self.detector.detectAndDecode(enhanced_image)
                if data:
                    return {
                        'success': True,
                        'data': data,
                        'method': 'OpenCV QRCodeDetector + Enhancement'
                    }
            except Exception as opencv_enhanced_error:
                print(f"OpenCV enhanced hatası: {opencv_enhanced_error}")
            
            return {'success': False, 'error': 'QR kod bulunamadı'}
            
        except Exception as e:
            return {'success': False, 'error': f'QR okuma hatası: {str(e)}'}
    
    def enhance_image(self, image):
        """Görüntü iyileştirme işlemleri"""
        try:
            # Görüntü tipini kontrol et
            if image is None or image.size == 0:
                return image
            
            # Veri tipini uint8'e çevir
            if image.dtype != np.uint8:
                image = image.astype(np.uint8)
            
            # Gri tonlamaya çevir
            if len(image.shape) == 3:
                if image.shape[2] == 3:  # BGR
                    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
                elif image.shape[2] == 4:  # BGRA
                    gray = cv2.cvtColor(image, cv2.COLOR_BGRA2GRAY)
                else:
                    gray = image[:, :, 0]  # İlk kanalı al
            else:
                gray = image
            
            # Görüntü boyut kontrolü
            if gray.shape[0] < 10 or gray.shape[1] < 10:
                return gray
            
            # Kontrast ve parlaklık artırma
            enhanced = cv2.convertScaleAbs(gray, alpha=1.5, beta=30)
            
            # Gaussian blur ile gürültü azaltma
            blurred = cv2.GaussianBlur(enhanced, (3, 3), 0)
            
            # Adaptive threshold ile kenar belirginleştirme
            thresh = cv2.adaptiveThreshold(
                blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                cv2.THRESH_BINARY, 11, 2
            )
            
            # Morfolojik işlemler ile QR kod yapısını iyileştir
            kernel = np.ones((2, 2), np.uint8)
            cleaned = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
            
            return cleaned
            
        except Exception as e:
            print(f"Görüntü iyileştirme hatası: {e}")
            return image

# Global scanner instance
qr_scanner = QRScanner()

def scan_qr_from_base64(base64_image):
    """Flask endpoint için QR okuma fonksiyonu"""
    return qr_scanner.decode_from_base64(base64_image)

if __name__ == "__main__":
    # Test
    scanner = QRScanner()
    print("QR Scanner hazır!")
