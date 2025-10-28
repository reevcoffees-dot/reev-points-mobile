#!/usr/bin/env python3
"""
Database migration script to add auth_token column to User table
"""

import sqlite3
import os
import sys

def add_auth_token_column():
    """Add auth_token column to User table if it doesn't exist"""
    
    db_path = 'instance/cafe_loyalty.db'
    
    if not os.path.exists(db_path):
        print(f"Database file not found at {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check if auth_token column already exists
        cursor.execute("PRAGMA table_info(user)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'auth_token' in columns:
            print("auth_token column already exists in user table")
            conn.close()
            return True
        
        # Add auth_token column
        print("Adding auth_token column to user table...")
        cursor.execute("ALTER TABLE user ADD COLUMN auth_token VARCHAR(100)")
        
        # Create unique index for auth_token
        print("Creating unique index for auth_token...")
        cursor.execute("CREATE UNIQUE INDEX idx_user_auth_token ON user(auth_token)")
        
        conn.commit()
        print("Successfully added auth_token column and index")
        
        conn.close()
        return True
        
    except sqlite3.Error as e:
        print(f"Database error: {e}")
        if conn:
            conn.close()
        return False
    except Exception as e:
        print(f"Error: {e}")
        if conn:
            conn.close()
        return False

if __name__ == "__main__":
    print("Starting database migration to add auth_token column...")
    success = add_auth_token_column()
    
    if success:
        print("Migration completed successfully!")
        sys.exit(0)
    else:
        print("Migration failed!")
        sys.exit(1)
