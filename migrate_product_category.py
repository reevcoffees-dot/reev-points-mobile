#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sqlite3
import os

def add_category_column():
    # Veritabanı bağlantısı
    db_path = 'instance/cafe_loyalty.db'
    
    if not os.path.exists(db_path):
        print("Veritabani dosyasi bulunamadi!")
        return
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Category kolonu var mı kontrol et
        cursor.execute("PRAGMA table_info(product)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'category' not in columns:
            # Category kolonu ekle
            cursor.execute("ALTER TABLE product ADD COLUMN category VARCHAR(50) DEFAULT 'Genel'")
            print("Product tablosuna category kolonu eklendi.")
            
            # Mevcut ürünlere kategori ata
            cursor.execute("UPDATE product SET category = 'İçecekler' WHERE name LIKE '%kahve%' OR name LIKE '%çay%' OR name LIKE '%latte%' OR name LIKE '%cappuccino%'")
            cursor.execute("UPDATE product SET category = 'Tatlılar' WHERE name LIKE '%pasta%' OR name LIKE '%kek%' OR name LIKE '%tart%' OR name LIKE '%tiramisu%'")
            cursor.execute("UPDATE product SET category = 'Atıştırmalık' WHERE name LIKE '%sandviç%' OR name LIKE '%toast%' OR name LIKE '%börek%'")
            
            conn.commit()
            print("Mevcut urunlere kategoriler atandi.")
        else:
            print("Category kolonu zaten mevcut.")
        
        # Mevcut ürünleri ve kategorilerini listele
        cursor.execute("SELECT id, name, category FROM product")
        products = cursor.fetchall()
        
        print("\nMevcut urunler ve kategorileri:")
        for product in products:
            print(f"ID: {product[0]} | Ad: {product[1]} | Kategori: {product[2]}")
        
    except Exception as e:
        print(f"Hata: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    add_category_column()
