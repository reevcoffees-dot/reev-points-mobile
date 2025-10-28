from pywebpush import webpush
import base64
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.backends import default_backend

def generate_vapid_keys():
    """VAPID anahtar çifti oluştur"""
    # Private key oluştur
    private_key = ec.generate_private_key(ec.SECP256R1(), default_backend())
    
    # Private key'i PEM formatında al
    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    
    # Public key'i al
    public_key = private_key.public_key()
    
    # Public key'i uncompressed point formatında al
    public_numbers = public_key.public_numbers()
    x = public_numbers.x.to_bytes(32, 'big')
    y = public_numbers.y.to_bytes(32, 'big')
    uncompressed_point = b'\x04' + x + y
    
    # Base64 URL-safe encoding
    public_key_b64 = base64.urlsafe_b64encode(uncompressed_point).decode('utf-8').rstrip('=')
    private_key_b64 = base64.urlsafe_b64encode(private_pem).decode('utf-8').rstrip('=')
    
    return public_key_b64, private_key_b64

if __name__ == "__main__":
    public_key, private_key = generate_vapid_keys()
    
    print("VAPID Anahtarları Oluşturuldu:")
    print("=" * 50)
    print(f"Public Key: {public_key}")
    print(f"Private Key: {private_key}")
    print("=" * 50)
    print("\n.env dosyasına eklenecek:")
    print(f"VAPID_PUBLIC_KEY={public_key}")
    print(f"VAPID_PRIVATE_KEY={private_key}")
    print(f"VAPID_CLAIMS_EMAIL=admin@reevpoints.com")
