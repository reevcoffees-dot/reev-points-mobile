#!/usr/bin/env python3
"""
CampaignUsage tablosuna yeni alanlar eklemek için migration scripti
"""

import sqlite3
import os
from datetime import datetime

def migrate_database():
    """Veritabanına yeni alanları ekle"""
    
    # Veritabanı dosyasının yolunu belirle
    db_path = os.path.join('instance', 'cafe_loyalty.db')
    
    if not os.path.exists(db_path):
        print(f"❌ Veritabanı dosyası bulunamadı: {db_path}")
        return False
    
    try:
        # Veritabanına bağlan
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("🔄 Veritabanı migration başlatılıyor...")
        
        # Mevcut tabloyu kontrol et
        cursor.execute("PRAGMA table_info(campaign_usage)")
        columns = [column[1] for column in cursor.fetchall()]
        print(f"📋 Mevcut sütunlar: {columns}")
        
        # Yeni sütunları ekle (eğer yoksa)
        new_columns = [
            ('selected_campaign_product_id', 'INTEGER'),
            ('selected_product_name', 'VARCHAR(200)'),
            ('selected_product_details', 'TEXT')
        ]
        
        for column_name, column_type in new_columns:
            if column_name not in columns:
                try:
                    alter_sql = f"ALTER TABLE campaign_usage ADD COLUMN {column_name} {column_type}"
                    cursor.execute(alter_sql)
                    print(f"✅ Sütun eklendi: {column_name} ({column_type})")
                except sqlite3.Error as e:
                    print(f"⚠️  Sütun eklenirken hata: {column_name} - {e}")
            else:
                print(f"ℹ️  Sütun zaten mevcut: {column_name}")
        
        # Foreign key constraint'i ekle (SQLite'da ALTER TABLE ile foreign key eklenemez, 
        # bu yüzden sadece sütunu ekliyoruz)
        
        # Değişiklikleri kaydet
        conn.commit()
        
        # Güncellenmiş tablo yapısını kontrol et
        cursor.execute("PRAGMA table_info(campaign_usage)")
        updated_columns = [column[1] for column in cursor.fetchall()]
        print(f"📋 Güncellenmiş sütunlar: {updated_columns}")
        
        print("✅ Migration başarıyla tamamlandı!")
        
        # Bağlantıyı kapat
        conn.close()
        
        return True
        
    except sqlite3.Error as e:
        print(f"❌ Veritabanı hatası: {e}")
        return False
    except Exception as e:
        print(f"❌ Genel hata: {e}")
        return False

def verify_migration():
    """Migration'ın başarılı olduğunu doğrula"""
    
    db_path = os.path.join('instance', 'cafe_loyalty.db')
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Tablo yapısını kontrol et
        cursor.execute("PRAGMA table_info(campaign_usage)")
        columns = cursor.fetchall()
        
        required_columns = [
            'selected_campaign_product_id',
            'selected_product_name', 
            'selected_product_details'
        ]
        
        existing_columns = [col[1] for col in columns]
        
        print("\n🔍 Migration doğrulaması:")
        all_present = True
        
        for req_col in required_columns:
            if req_col in existing_columns:
                print(f"✅ {req_col} - Mevcut")
            else:
                print(f"❌ {req_col} - Eksik")
                all_present = False
        
        conn.close()
        
        if all_present:
            print("\n🎉 Tüm yeni sütunlar başarıyla eklendi!")
            return True
        else:
            print("\n⚠️  Bazı sütunlar eksik!")
            return False
            
    except Exception as e:
        print(f"❌ Doğrulama hatası: {e}")
        return False

if __name__ == "__main__":
    print("=" * 50)
    print("🔧 CampaignUsage Tablosu Migration")
    print("=" * 50)
    print(f"📅 Tarih: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Migration'ı çalıştır
    if migrate_database():
        print()
        # Doğrulama yap
        verify_migration()
    else:
        print("\n❌ Migration başarısız!")
    
    print("\n" + "=" * 50)
