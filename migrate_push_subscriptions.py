#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Push Subscription tablosu oluşturma migration scripti
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import app, db
from sqlalchemy import text

def migrate_push_subscriptions():
    """Push subscription tablosunu oluştur"""
    
    with app.app_context():
        try:
            # Push subscription tablosunu oluştur
            db.engine.execute(text("""
                CREATE TABLE IF NOT EXISTS push_subscription (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER NOT NULL,
                    endpoint TEXT NOT NULL,
                    p256dh_key TEXT NOT NULL,
                    auth_key TEXT NOT NULL,
                    is_active BOOLEAN DEFAULT 1,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES user (id)
                )
            """))
            
            # Index'leri oluştur
            db.engine.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_push_subscription_user_id 
                ON push_subscription (user_id)
            """))
            
            db.engine.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_push_subscription_active 
                ON push_subscription (is_active)
            """))
            
            print("✅ Push subscription tablosu başarıyla oluşturuldu!")
            
        except Exception as e:
            print(f"❌ Migration hatası: {e}")
            raise

if __name__ == '__main__':
    migrate_push_subscriptions()
