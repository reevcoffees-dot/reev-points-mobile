#!/usr/bin/env python3
"""
ProductRedemption tablosuna qr_code alanı eklemek için migration script
"""

import sqlite3
import os

def add_qr_code_column():
    # Database dosyasının yolu
    db_path = 'cafe_loyalty.db'
    
    if not os.path.exists(db_path):
        print(f"Database dosyası bulunamadı: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Önce sütun var mı kontrol et
        cursor.execute("PRAGMA table_info(product_redemption)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'qr_code' not in columns:
            # QR kod sütunu ekle
            cursor.execute('ALTER TABLE product_redemption ADD COLUMN qr_code TEXT')
            print("✅ QR kod sütunu eklendi!")
        else:
            print("ℹ️ QR kod sütunu zaten mevcut")
        
        # Index ekle
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_product_redemption_qr_code ON product_redemption(qr_code)')
        
        conn.commit()
        
        # Tablo yapısını kontrol et
        cursor.execute("PRAGMA table_info(product_redemption)")
        columns = cursor.fetchall()
        print("\n📋 Güncellenmiş tablo yapısı:")
        for col in columns:
            print(f"  - {col[1]} ({col[2]})")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Hata: {e}")
        return False

if __name__ == "__main__":
    add_qr_code_column()
