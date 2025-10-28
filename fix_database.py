#!/usr/bin/env python3
import sqlite3
import os
from datetime import datetime

def fix_database_schema():
    """Fix missing columns in the database"""
    db_path = 'instance/cafe_loyalty.db'
    
    if not os.path.exists(db_path):
        print(f"Database file not found: {db_path}")
        return
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Check if created_at column exists in product_redemption table
        cursor.execute("PRAGMA table_info(product_redemption)")
        columns = [column[1] for column in cursor.fetchall()]
        print(f"Current product_redemption columns: {columns}")
        
        # Add missing created_at column if it doesn't exist
        if 'created_at' not in columns:
            print("Adding created_at column to product_redemption table...")
            cursor.execute("""
                ALTER TABLE product_redemption 
                ADD COLUMN created_at DATETIME
            """)
            # Update existing rows with current timestamp
            cursor.execute("""
                UPDATE product_redemption 
                SET created_at = datetime('now') 
                WHERE created_at IS NULL
            """)
            print("Added created_at column")
        
        # Add missing qr_code column if it doesn't exist
        if 'qr_code' not in columns:
            print("Adding qr_code column to product_redemption table...")
            cursor.execute("""
                ALTER TABLE product_redemption 
                ADD COLUMN qr_code VARCHAR(255)
            """)
            print("Added qr_code column")
        
        # Check if redeemed_at column exists, if not rename from existing column or add it
        if 'redeemed_at' not in columns:
            print("Adding redeemed_at column to product_redemption table...")
            cursor.execute("""
                ALTER TABLE product_redemption 
                ADD COLUMN redeemed_at DATETIME
            """)
            # Update existing rows with created_at value if available
            cursor.execute("""
                UPDATE product_redemption 
                SET redeemed_at = created_at 
                WHERE redeemed_at IS NULL AND created_at IS NOT NULL
            """)
            # For rows without created_at, use current timestamp
            cursor.execute("""
                UPDATE product_redemption 
                SET redeemed_at = datetime('now') 
                WHERE redeemed_at IS NULL
            """)
            print("Added redeemed_at column")
        
        # Check if confirmation_code column exists, if not add it
        if 'confirmation_code' not in columns:
            print("Adding confirmation_code column to product_redemption table...")
            cursor.execute("""
                ALTER TABLE product_redemption 
                ADD COLUMN confirmation_code VARCHAR(255)
            """)
            print("Added confirmation_code column")
        
        # Check if ProductRating table exists
        cursor.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name='product_rating'
        """)
        
        if not cursor.fetchone():
            print("Creating product_rating table...")
            cursor.execute("""
                CREATE TABLE product_rating (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER NOT NULL,
                    product_id INTEGER NOT NULL,
                    rating INTEGER NOT NULL,
                    comment TEXT,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME,
                    FOREIGN KEY (user_id) REFERENCES user (id),
                    FOREIGN KEY (product_id) REFERENCES product (id),
                    UNIQUE (user_id, product_id)
                )
            """)
            print("Created product_rating table")
        
        conn.commit()
        print("Database schema updated successfully!")
        
    except Exception as e:
        print(f"Error updating database: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    fix_database_schema()
