#!/usr/bin/env python3
"""
Language column migration script for User table
Adds language column to existing users with default 'tr' value
"""

import sqlite3
import os

def migrate_language():
    db_path = 'instance/cafe_loyalty.db'
    
    if not os.path.exists(db_path):
        print("Database file not found. Will be created when app starts.")
        return
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check if language column exists
        cursor.execute("PRAGMA table_info(user)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'language' not in columns:
            print("Adding language column to user table...")
            cursor.execute("ALTER TABLE user ADD COLUMN language VARCHAR(5) DEFAULT 'tr'")
            
            # Update existing users to have Turkish as default language
            cursor.execute("UPDATE user SET language = 'tr' WHERE language IS NULL")
            
            conn.commit()
            print("Language column added successfully!")
        else:
            print("Language column already exists.")
            
        conn.close()
        
    except Exception as e:
        print(f"Migration error: {e}")

if __name__ == '__main__':
    migrate_language()
