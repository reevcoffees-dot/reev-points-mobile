#!/usr/bin/env python3
import sqlite3
import os
from datetime import datetime

def migrate_database():
    db_path = 'instance/cafe_loyalty.db'
    
    if not os.path.exists(db_path):
        print("Database file not found. Will be created when app starts.")
        return
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check if updated_at column exists in user table
        cursor.execute("PRAGMA table_info(user)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'updated_at' not in columns:
            print("Adding updated_at column to user table...")
            cursor.execute("ALTER TABLE user ADD COLUMN updated_at DATETIME")
            
            # Set current timestamp for existing users
            current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            cursor.execute("UPDATE user SET updated_at = ? WHERE updated_at IS NULL", (current_time,))
            
            conn.commit()
            print("updated_at column added successfully!")
        else:
            print("updated_at column already exists.")
            
        conn.close()
        
    except Exception as e:
        print(f"Migration error: {e}")

if __name__ == "__main__":
    migrate_database()
