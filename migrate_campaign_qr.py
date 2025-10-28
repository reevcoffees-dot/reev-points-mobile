#!/usr/bin/env python3
"""
Kampanya QR Kod Sistemi için Veritabanı Migration Scripti
Bu script yeni kampanya QR kod özelliklerini mevcut veritabanına ekler.
"""

import sqlite3
import os

def migrate_campaign_qr_system():
    """Kampanya QR kod sistemi için gerekli tabloları ve kolonları ekler"""
    
    db_path = 'instance/cafe_loyalty.db'
    
    if not os.path.exists(db_path):
        print("Veritabanı dosyası bulunamadı. Uygulama başlatıldığında oluşturulacak.")
        return
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("Kampanya QR kod sistemi migration başlatılıyor...")
        
        # 1. Campaign tablosuna yeni kolonlar ekle
        print("Campaign tablosuna QR kod kolonları ekleniyor...")
        
        # Mevcut kolonları kontrol et
        cursor.execute("PRAGMA table_info(campaign)")
        existing_columns = [column[1] for column in cursor.fetchall()]
        
        # Yeni kolonları ekle
        new_campaign_columns = [
            ('max_usage_per_customer', 'INTEGER DEFAULT 1'),
            ('total_usage_limit', 'INTEGER'),
            ('qr_enabled', 'BOOLEAN DEFAULT 1')
        ]
        
        for column_name, column_def in new_campaign_columns:
            if column_name not in existing_columns:
                cursor.execute(f"ALTER TABLE campaign ADD COLUMN {column_name} {column_def}")
                print(f"  ✓ {column_name} kolonu eklendi")
            else:
                print(f"  - {column_name} kolonu zaten mevcut")
        
        # 2. CampaignProduct tablosunu oluştur
        print("CampaignProduct tablosu oluşturuluyor...")
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS campaign_product (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                campaign_id INTEGER NOT NULL,
                product_name VARCHAR(200) NOT NULL,
                product_description TEXT,
                discount_type VARCHAR(20) DEFAULT 'percentage',
                discount_value FLOAT DEFAULT 0,
                original_price FLOAT,
                campaign_price FLOAT,
                is_active BOOLEAN DEFAULT 1,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (campaign_id) REFERENCES campaign(id)
            )
        """)
        print("  ✓ CampaignProduct tablosu oluşturuldu")
        
        # 3. CampaignUsage tablosunu oluştur
        print("CampaignUsage tablosu oluşturuluyor...")
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS campaign_usage (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                campaign_id INTEGER NOT NULL,
                customer_id INTEGER NOT NULL,
                qr_code VARCHAR(200) UNIQUE NOT NULL,
                is_used BOOLEAN DEFAULT 0,
                used_at DATETIME,
                used_by_branch_id INTEGER,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                expires_at DATETIME,
                FOREIGN KEY (campaign_id) REFERENCES campaign(id),
                FOREIGN KEY (customer_id) REFERENCES user(id),
                FOREIGN KEY (used_by_branch_id) REFERENCES branch(id)
            )
        """)
        print("  ✓ CampaignUsage tablosu oluşturuldu")
        
        # 4. İndeksler oluştur
        print("İndeksler oluşturuluyor...")
        indexes = [
            ("idx_campaign_product_campaign_id", "campaign_product", "campaign_id"),
            ("idx_campaign_usage_campaign_id", "campaign_usage", "campaign_id"),
            ("idx_campaign_usage_customer_id", "campaign_usage", "customer_id"),
            ("idx_campaign_usage_qr_code", "campaign_usage", "qr_code"),
            ("idx_campaign_usage_used_by_branch", "campaign_usage", "used_by_branch_id")
        ]
        
        for index_name, table_name, column_name in indexes:
            try:
                cursor.execute(f"CREATE INDEX IF NOT EXISTS {index_name} ON {table_name}({column_name})")
                print(f"  ✓ {index_name} indeksi oluşturuldu")
            except sqlite3.Error as e:
                print(f"  ! {index_name} indeksi oluşturulamadı: {e}")
        
        # 5. Mevcut kampanyalar için varsayılan değerleri güncelle
        print("Mevcut kampanyalar için varsayılan değerler ayarlanıyor...")
        cursor.execute("""
            UPDATE campaign 
            SET max_usage_per_customer = 1, 
                qr_enabled = 1 
            WHERE max_usage_per_customer IS NULL 
               OR qr_enabled IS NULL
        """)
        updated_campaigns = cursor.rowcount
        print(f"  ✓ {updated_campaigns} kampanya güncellendi")
        
        # Değişiklikleri kaydet
        conn.commit()
        print("\n✅ Kampanya QR kod sistemi migration başarıyla tamamlandı!")
        print("\nYeni özellikler:")
        print("- Kampanya başına müşteri kullanım limiti")
        print("- Toplam kampanya kullanım limiti")
        print("- QR kod etkinleştirme/devre dışı bırakma")
        print("- Kampanya ürün yönetimi")
        print("- QR kod kullanım takibi")
        print("- Detaylı raporlama")
        
    except sqlite3.Error as e:
        print(f"❌ Migration hatası: {e}")
        conn.rollback()
    except Exception as e:
        print(f"❌ Beklenmeyen hata: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    migrate_campaign_qr_system()
