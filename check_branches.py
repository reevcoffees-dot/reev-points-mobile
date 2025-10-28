#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sqlite3
import os

def check_branches():
    """Mevcut şubeleri listeler"""
    
    db_path = os.path.join('instance', 'cafe_loyalty.db')
    
    if not os.path.exists(db_path):
        print("Veritabanı dosyası bulunamadı!")
        return
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Tüm şubeleri listele
        cursor.execute("SELECT id, name, email, is_active, image FROM branch")
        branches = cursor.fetchall()
        
        print("Mevcut şubeler:")
        print("-" * 80)
        for branch in branches:
            status = "Aktif" if branch[3] else "Pasif"
            image = branch[4] if branch[4] else "Görsel yok"
            print(f"ID: {branch[0]} | Ad: {branch[1]} | Email: {branch[2]} | Durum: {status} | Görsel: {image}")
        
        conn.close()
        
    except Exception as e:
        print(f"Hata: {str(e)}")

if __name__ == "__main__":
    check_branches()
