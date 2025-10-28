#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sqlite3
from datetime import datetime
import os

def migrate_categories():
    """
    Kategori tablosunu oluşturur ve mevcut ürün kategorilerini yeni tabloya taşır
    """
    
    # Veritabanı dosyası yolu
    db_path = os.path.join('instance', 'cafe_loyalty.db')
    
    if not os.path.exists(db_path):
        print("Veritabanı dosyası bulunamadı!")
        return
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        print("Kategori tablosu oluşturuluyor...")
        
        # Category tablosunu oluştur
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS category (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name VARCHAR(50) NOT NULL UNIQUE,
                description TEXT,
                is_active BOOLEAN DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        print("Mevcut kategoriler tespit ediliyor...")
        
        # Mevcut ürünlerden benzersiz kategorileri al
        cursor.execute("SELECT DISTINCT category FROM product WHERE category IS NOT NULL AND category != ''")
        existing_categories = cursor.fetchall()
        
        # Varsayılan kategorileri ekle
        default_categories = [
            ('Genel', 'Genel kategorideki ürünler'),
            ('İçecekler', 'Sıcak ve soğuk içecekler'),
            ('Tatlılar', 'Tatlı ürünler'),
            ('Atıştırmalık', 'Atıştırmalık ürünler'),
            ('Kahvaltı', 'Kahvaltı ürünleri'),
            ('Ana Yemek', 'Ana yemek ürünleri')
        ]
        
        # Tüm kategorileri birleştir
        all_categories = set()
        
        # Varsayılan kategorileri ekle
        for cat_name, cat_desc in default_categories:
            all_categories.add((cat_name, cat_desc))
        
        # Mevcut kategorileri ekle
        for (cat_name,) in existing_categories:
            if cat_name and cat_name.strip():
                # Varsayılan kategorilerde varsa açıklamasını kullan
                desc = next((desc for name, desc in default_categories if name == cat_name), f'{cat_name} kategorisi')
                all_categories.add((cat_name, desc))
        
        print(f"{len(all_categories)} kategori ekleniyor...")
        
        # Kategorileri ekle
        for cat_name, cat_desc in all_categories:
            try:
                cursor.execute('''
                    INSERT OR IGNORE INTO category (name, description, is_active, created_at)
                    VALUES (?, ?, 1, ?)
                ''', (cat_name, cat_desc, datetime.now()))
                print(f"  + {cat_name}")
            except Exception as e:
                print(f"  - {cat_name} eklenirken hata: {e}")
        
        print("Product tablosuna category_id kolonu ekleniyor...")
        
        # Product tablosuna category_id kolonu ekle (eğer yoksa)
        try:
            cursor.execute("ALTER TABLE product ADD COLUMN category_id INTEGER")
            print("  + category_id kolonu eklendi")
        except sqlite3.OperationalError as e:
            if "duplicate column name" in str(e).lower():
                print("  + category_id kolonu zaten mevcut")
            else:
                print(f"  - Kolon eklenirken hata: {e}")
        
        print("Ürünlerin category_id değerleri güncelleniyor...")
        
        # Ürünlerin category_id değerlerini güncelle
        cursor.execute("SELECT id, category FROM product WHERE category IS NOT NULL")
        products = cursor.fetchall()
        
        updated_count = 0
        for product_id, category_name in products:
            if category_name and category_name.strip():
                # Kategori ID'sini bul
                cursor.execute("SELECT id FROM category WHERE name = ?", (category_name,))
                category_result = cursor.fetchone()
                
                if category_result:
                    category_id = category_result[0]
                    cursor.execute("UPDATE product SET category_id = ? WHERE id = ?", (category_id, product_id))
                    updated_count += 1
        
        print(f"  {updated_count} urun guncellendi")
        
        # Değişiklikleri kaydet
        conn.commit()
        print("\nMigration basariyla tamamlandi!")
        
        # İstatistikleri göster
        cursor.execute("SELECT COUNT(*) FROM category")
        category_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM product WHERE category_id IS NOT NULL")
        linked_products = cursor.fetchone()[0]
        
        print(f"\nIstatistikler:")
        print(f"   - Toplam kategori sayisi: {category_count}")
        print(f"   - Kategoriye bagli urun sayisi: {linked_products}")
        
    except Exception as e:
        print(f"Migration sirasinda hata olustu: {e}")
        conn.rollback()
    
    finally:
        conn.close()

if __name__ == "__main__":
    print("Kategori migration baslatiliyor...\n")
    migrate_categories()
    print("\nMigration tamamlandi!")
