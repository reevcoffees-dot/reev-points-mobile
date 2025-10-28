#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sqlite3
import os

def migrate_branch_table():
    """Branch tablosuna image ve working_hours kolonlarını ekler"""
    
    db_path = os.path.join('instance', 'cafe_loyalty.db')
    
    if not os.path.exists(db_path):
        print("❌ Veritabanı dosyası bulunamadı!")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Mevcut branch tablosu yapısını kontrol et
        cursor.execute("PRAGMA table_info(branch)")
        columns = [column[1] for column in cursor.fetchall()]
        
        print("Mevcut branch tablosu kolonlari:", columns)
        
        # image kolonu yoksa ekle
        if 'image' not in columns:
            print("'image' kolonu ekleniyor...")
            cursor.execute("ALTER TABLE branch ADD COLUMN image VARCHAR(200)")
            print("'image' kolonu eklendi")
        else:
            print("'image' kolonu zaten mevcut")
        
        # working_hours kolonu yoksa ekle
        if 'working_hours' not in columns:
            print("'working_hours' kolonu ekleniyor...")
            cursor.execute("ALTER TABLE branch ADD COLUMN working_hours VARCHAR(100)")
            print("'working_hours' kolonu eklendi")
        else:
            print("'working_hours' kolonu zaten mevcut")
        
        # Değişiklikleri kaydet
        conn.commit()
        
        # Güncellenmiş tablo yapısını göster
        cursor.execute("PRAGMA table_info(branch)")
        updated_columns = [column[1] for column in cursor.fetchall()]
        print("Guncellenmiş branch tablosu kolonlari:", updated_columns)
        
        conn.close()
        print("Migration basariyla tamamlandi!")
        return True
        
    except Exception as e:
        print(f"Migration hatasi: {str(e)}")
        return False

if __name__ == "__main__":
    print("Branch tablosu migration baslatiliyor...")
    migrate_branch_table()
