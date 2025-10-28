#!/usr/bin/env python3
import requests
import sys

def test_server_connection():
    """Test if Flask server is accessible"""
    base_urls = [
        'http://192.168.74.6:1519',
        'http://88.247.42.6:1519',
        'http://localhost:1519',
        'http://127.0.0.1:1519'
    ]
    
    for url in base_urls:
        try:
            print(f"Testing {url}...")
            response = requests.get(f"{url}/api/dashboard?user_id=126", timeout=5)
            print(f"✅ {url} - Status: {response.status_code}")
            if response.status_code == 200:
                print(f"   Response: {response.json()}")
            return url
        except requests.exceptions.ConnectionError:
            print(f"❌ {url} - Connection failed")
        except requests.exceptions.Timeout:
            print(f"⏱️ {url} - Timeout")
        except Exception as e:
            print(f"❌ {url} - Error: {e}")
    
    print("\n🔍 No server found. Please start Flask server with: python app.py")
    return None

if __name__ == "__main__":
    working_url = test_server_connection()
    if working_url:
        print(f"\n✅ Server is accessible at: {working_url}")
    else:
        print("\n❌ Server is not accessible on any tested address")
