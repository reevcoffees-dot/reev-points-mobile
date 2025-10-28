#!/usr/bin/env python3
"""
Database migration script to add preferred_branch_id column to User table
"""

import sqlite3
import os

def migrate_database():
    db_path = 'instance/cafe_loyalty.db'
    
    if not os.path.exists(db_path):
        print("Database file not found. Will be created when app starts.")
        return
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check if preferred_branch_id column exists
        cursor.execute("PRAGMA table_info(user)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'preferred_branch_id' not in columns:
            print("Adding preferred_branch_id column to user table...")
            cursor.execute("ALTER TABLE user ADD COLUMN preferred_branch_id INTEGER")
            conn.commit()
            print("Migration completed successfully!")
        else:
            print("preferred_branch_id column already exists.")
        
        # Check if campaign_branches table exists
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='campaign_branches'")
        if not cursor.fetchone():
            print("Creating campaign_branches table...")
            cursor.execute("""
                CREATE TABLE campaign_branches (
                    campaign_id INTEGER NOT NULL,
                    branch_id INTEGER NOT NULL,
                    PRIMARY KEY (campaign_id, branch_id),
                    FOREIGN KEY (campaign_id) REFERENCES campaign(id),
                    FOREIGN KEY (branch_id) REFERENCES branch(id)
                )
            """)
            conn.commit()
            print("campaign_branches table created successfully!")
        else:
            print("campaign_branches table already exists.")
            
        conn.close()
        
    except Exception as e:
        print(f"Migration error: {e}")

if __name__ == '__main__':
    migrate_database()
