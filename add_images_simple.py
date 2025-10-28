#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sqlite3
import os

def add_images_to_all_branches():
    # Veritabanı bağlantısı
    db_path = 'instance/cafe_loyalty.db'
    
    if not os.path.exists(db_path):
        print("Veritabani dosyasi bulunamadi!")
        return
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Mevcut şubeleri listele
        cursor.execute("SELECT id, name, image FROM branch")
        branches = cursor.fetchall()
        
        # Test görselleri
        test_images = [
            "logo_1756710283_Ekran_Alnts-Photoroom.png",
            "20250828_183303_WhatsApp_Gorsel_2025-08-28_saat_15.12.13_5a217f2b.jpg",
            "20250829_162002_lmnt.jpg"
        ]
        
        print("Subelere gorsel ekleniyor...")
        for i, branch in enumerate(branches):
            if not branch[2]:  # Eğer görsel yoksa
                image = test_images[i % len(test_images)]
                cursor.execute("UPDATE branch SET image = ? WHERE id = ?", (image, branch[0]))
                print(f"+ {branch[1]} subesine {image} eklendi")
            else:
                print(f"+ {branch[1]} subesinde zaten gorsel var: {branch[2]}")
        
        conn.commit()
        
        # Sonuçları kontrol et
        print("\nGuncel durum:")
        cursor.execute("SELECT id, name, image FROM branch")
        updated_branches = cursor.fetchall()
        
        for branch in updated_branches:
            print(f"ID: {branch[0]} | Ad: {branch[1]} | Gorsel: {branch[2] or 'Yok'}")
        
    except Exception as e:
        print(f"Hata: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    add_images_to_all_branches()
