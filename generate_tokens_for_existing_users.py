#!/usr/bin/env python3
"""
Generate auth tokens for existing users who don't have them
"""

import sqlite3
import os
import secrets

def generate_tokens_for_existing_users():
    """Generate auth tokens for users who don't have them"""
    
    db_path = 'instance/cafe_loyalty.db'
    
    if not os.path.exists(db_path):
        print(f"Database file not found at {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Find users without auth tokens
        cursor.execute("SELECT id, email FROM user WHERE auth_token IS NULL OR auth_token = ''")
        users_without_tokens = cursor.fetchall()
        
        if not users_without_tokens:
            print("All users already have auth tokens")
            conn.close()
            return True
        
        print(f"Found {len(users_without_tokens)} users without auth tokens")
        
        # Generate tokens for users
        for user_id, email in users_without_tokens:
            token = secrets.token_urlsafe(32)
            cursor.execute("UPDATE user SET auth_token = ? WHERE id = ?", (token, user_id))
            print(f"Generated token for user {email} (ID: {user_id})")
        
        conn.commit()
        print(f"Successfully generated tokens for {len(users_without_tokens)} users")
        
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
    print("Generating auth tokens for existing users...")
    success = generate_tokens_for_existing_users()
    
    if success:
        print("Token generation completed successfully!")
    else:
        print("Token generation failed!")
