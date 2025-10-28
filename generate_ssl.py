#!/usr/bin/env python3
"""
SSL sertifikası oluşturma scripti
"""
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
import datetime
import ipaddress

def generate_ssl_certificate():
    # Private key oluştur
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
    )

    # Sertifika bilgileri
    subject = issuer = x509.Name([
        x509.NameAttribute(NameOID.COUNTRY_NAME, "TR"),
        x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "Istanbul"),
        x509.NameAttribute(NameOID.LOCALITY_NAME, "Istanbul"),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, "REEV Coffee"),
        x509.NameAttribute(NameOID.COMMON_NAME, "websadakat.test"),
    ])

    # Sertifika oluştur
    cert = x509.CertificateBuilder().subject_name(
        subject
    ).issuer_name(
        issuer
    ).public_key(
        private_key.public_key()
    ).serial_number(
        x509.random_serial_number()
    ).not_valid_before(
        datetime.datetime.utcnow()
    ).not_valid_after(
        datetime.datetime.utcnow() + datetime.timedelta(days=365)
    ).add_extension(
        x509.SubjectAlternativeName([
            x509.DNSName("websadakat.test"),
            x509.DNSName("*.websadakat.test"),
            x509.IPAddress(ipaddress.IPv4Address("127.0.0.1")),
            x509.DNSName("localhost"),
        ]),
        critical=False,
    ).sign(private_key, hashes.SHA256())

    # Private key dosyasını yaz
    with open("key.pem", "wb") as f:
        f.write(private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        ))

    # Sertifika dosyasını yaz
    with open("cert.pem", "wb") as f:
        f.write(cert.public_bytes(serialization.Encoding.PEM))

    print("SSL sertifikaları başarıyla oluşturuldu:")
    print("- cert.pem (sertifika)")
    print("- key.pem (private key)")
    print("\nArtık Flask uygulamanız HTTPS destekleyecek!")

if __name__ == "__main__":
    try:
        generate_ssl_certificate()
    except ImportError:
        print("cryptography kütüphanesi gerekli. Yüklemek için:")
        print("pip install cryptography")
    except Exception as e:
        print(f"Hata: {e}")
