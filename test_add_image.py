#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sqlite3
import os

def add_image_to_branch():
    # Veritabanı bağlantısı
    db_path = 'instance/cafe_loyalty.db'
    
    if not os.path.exists(db_path):
        print("Veritabanı dosyası bulunamadı!")
        return
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Mevcut şubeleri listele
        cursor.execute("SELECT id, name, image FROM branch")
        branches = cursor.fetchall()
        
        print("Mevcut şubeler:")
        for branch in branches:
            print(f"ID: {branch[0]} | Ad: {branch[1]} | Görsel: {branch[2] or 'Yok'}")
        
        # İlk şubeye test görseli ekle
        if branches:
            # Uploads klasöründeki bir görseli seç
            test_image = "logo_1756710283_Ekran_Alnts-Photoroom.png"
            
            cursor.execute("UPDATE branch SET image = ? WHERE id = ?", (test_image, branches[0][0]))
            conn.commit()
            
            print(f"\n{branches[0][1]} şubesine {test_image} görseli eklendi.")
            
            # Kontrol et
            cursor.execute("SELECT id, name, image FROM branch WHERE id = ?", (branches[0][0],))
            updated_branch = cursor.fetchone()
            print(f"Güncelleme sonrası: ID: {updated_branch[0]} | Ad: {updated_branch[1]} | Görsel: {updated_branch[2]}")
        
    except Exception as e:
        print(f"Hata: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    add_image_to_branch()
