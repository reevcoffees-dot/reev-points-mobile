#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sqlite3
import os
from datetime import datetime

def migrate_campaign_product_table():
    """CampaignProduct tablosuna product_id ve discount kolonlarını ekle"""
    db_path = 'instance/cafe_loyalty.db'
    
    if not os.path.exists(db_path):
        print("❌ Veritabanı dosyası bulunamadı!")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Mevcut tablo yapısını kontrol et
        cursor.execute("PRAGMA table_info(campaign_product)")
        columns = [column[1] for column in cursor.fetchall()]
        print(f"📋 Mevcut kolonlar: {columns}")
        
        changes_made = False
        
        # product_id kolonu ekle
        if 'product_id' not in columns:
            print("➕ product_id kolonu ekleniyor...")
            cursor.execute("ALTER TABLE campaign_product ADD COLUMN product_id INTEGER")
            cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_campaign_product_product_id 
                ON campaign_product(product_id)
            """)
            changes_made = True
            print("✅ product_id kolonu eklendi")
        else:
            print("ℹ️  product_id kolonu zaten mevcut")
        
        # discount kolonu ekle
        if 'discount' not in columns:
            print("➕ discount kolonu ekleniyor...")
            cursor.execute("ALTER TABLE campaign_product ADD COLUMN discount REAL DEFAULT 0")
            changes_made = True
            print("✅ discount kolonu eklendi")
        else:
            print("ℹ️  discount kolonu zaten mevcut")
        
        if changes_made:
            conn.commit()
            print("✅ Veritabanı migration başarıyla tamamlandı!")
        else:
            print("ℹ️  Hiçbir değişiklik yapılmadı, tüm kolonlar zaten mevcut")
        
        # Güncellenmiş tablo yapısını göster
        cursor.execute("PRAGMA table_info(campaign_product)")
        updated_columns = cursor.fetchall()
        print("\n📋 Güncellenmiş tablo yapısı:")
        for col in updated_columns:
            print(f"   - {col[1]} ({col[2]})")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Migration hatası: {e}")
        return False

if __name__ == "__main__":
    print("🚀 CampaignProduct tablo migration başlatılıyor...")
    print(f"⏰ Zaman: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    success = migrate_campaign_product_table()
    
    if success:
        print("\n🎉 Migration başarıyla tamamlandı!")
    else:
        print("\n💥 Migration başarısız oldu!")
