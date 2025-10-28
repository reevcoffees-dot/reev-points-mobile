import sqlite3

def fix_nullable():
    conn = sqlite3.connect('instance/cafe_loyalty.db')
    cursor = conn.cursor()
    
    # Backup existing data
    cursor.execute('CREATE TABLE campaign_product_temp AS SELECT * FROM campaign_product')
    
    # Drop original table
    cursor.execute('DROP TABLE campaign_product')
    
    # Create new table with nullable product_name
    cursor.execute('''
        CREATE TABLE campaign_product (
            id INTEGER PRIMARY KEY,
            campaign_id INTEGER NOT NULL,
            product_id INTEGER,
            product_name TEXT,
            product_description TEXT,
            discount_type TEXT DEFAULT 'percentage',
            discount_value REAL DEFAULT 0,
            discount REAL DEFAULT 0,
            original_price REAL,
            campaign_price REAL,
            is_active BOOLEAN DEFAULT 1,
            created_at DATETIME
        )
    ''')
    
    # Restore data
    cursor.execute('INSERT INTO campaign_product SELECT * FROM campaign_product_temp')
    
    # Clean up
    cursor.execute('DROP TABLE campaign_product_temp')
    
    conn.commit()
    conn.close()
    print('Migration completed successfully')

if __name__ == '__main__':
    fix_nullable()
