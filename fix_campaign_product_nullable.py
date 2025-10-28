#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sqlite3
import os

def fix_campaign_product_nullable():
    """campaign_product tablosunda product_name kolonunu nullable yap"""
    db_path = 'instance/cafe_loyalty.db'
    
    if not os.path.exists(db_path):
        print("❌ Veritabanı dosyası bulunamadı!")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("🔄 campaign_product tablosunu yeniden oluşturuyor...")
        
        # Mevcut verileri yedekle
        cursor.execute('CREATE TABLE campaign_product_backup AS SELECT * FROM campaign_product')
        
        # Eski tabloyu sil
        cursor.execute('DROP TABLE campaign_product')
        
        # Yeni tabloyu oluştur (product_name nullable)
        cursor.execute('''
            CREATE TABLE campaign_product (
                id INTEGER PRIMARY KEY,
                campaign_id INTEGER NOT NULL,
                product_id INTEGER,
                product_name TEXT,
                product_description TEXT,
                discount_type TEXT DEFAULT 'percentage',
                discount_value REAL DEFAULT 0,
                discount REAL DEFAULT 0,
                original_price REAL,
                campaign_price REAL,
                is_active BOOLEAN DEFAULT 1,
                created_at DATETIME,
                FOREIGN KEY(campaign_id) REFERENCES campaign(id),
                FOREIGN KEY(product_id) REFERENCES product(id)
            )
        ''')
        
        # Verileri geri yükle
        cursor.execute('INSERT INTO campaign_product SELECT * FROM campaign_product_backup')
        
        # Yedek tabloyu sil
        cursor.execute('DROP TABLE campaign_product_backup')
        
        conn.commit()
        print("✅ Migration tamamlandı - product_name artık nullable")
        
        # Tablo yapısını kontrol et
        cursor.execute("PRAGMA table_info(campaign_product)")
        columns = cursor.fetchall()
        print("\n📋 Güncellenmiş tablo yapısı:")
        for col in columns:
            nullable = "NULL" if col[3] == 0 else "NOT NULL"
            print(f"   - {col[1]} ({col[2]}) {nullable}")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Migration hatası: {e}")
        return False

if __name__ == "__main__":
    fix_campaign_product_nullable()
