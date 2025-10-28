#!/usr/bin/env python3
"""
Mesaj sistemi için veritabanı migration scripti
Bu script Message tablosunu mevcut veritabanına ekler.
"""

import os
import sys
from datetime import datetime
import pytz

# Flask app'i import et
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import app, db, Message, User, get_turkey_time

def migrate_messages():
    """Message tablosunu oluştur ve test verisi ekle"""
    
    with app.app_context():
        try:
            print("Mesaj sistemi migration başlatılıyor...")
            
            # Tabloları oluştur
            db.create_all()
            print("✓ Message tablosu oluşturuldu")
            
            # Test mesajı ekle (admin'den tüm müşterilere)
            customers = User.query.filter_by(is_admin=False).all()
            
            if customers:
                test_message_title = "Hoş Geldiniz! 🎉"
                test_message_content = """Merhaba değerli müşterimiz,

Yeni mesajlaşma sistemimize hoş geldiniz! Artık admin panelimizden size özel mesajlar gönderebiliyoruz.

Bu sistem sayesinde:
• Kampanya duyurularını
• Özel teklifleri  
• Önemli bildirimleri
• Puan durumu güncellemelerini

Doğrudan size ulaştırabileceğiz.

Mesajlarınızı dashboard'unuzdan "Mesajlarım" bölümünden kontrol edebilirsiniz.

Teşekkürler,
Cafe Sadakat Ekibi"""

                for customer in customers:
                    # Aynı mesajın daha önce gönderilip gönderilmediğini kontrol et
                    existing_message = Message.query.filter_by(
                        title=test_message_title,
                        recipient_id=customer.id
                    ).first()
                    
                    if not existing_message:
                        welcome_message = Message(
                            title=test_message_title,
                            content=test_message_content,
                            recipient_id=customer.id,
                            is_admin_message=True
                        )
                        db.session.add(welcome_message)
                
                db.session.commit()
                print(f"✓ {len(customers)} müşteriye hoş geldin mesajı gönderildi")
            
            print("✓ Mesaj sistemi migration tamamlandı!")
            
            # İstatistikleri göster
            total_messages = Message.query.count()
            unread_messages = Message.query.filter_by(is_read=False).count()
            
            print(f"\n📊 Mesaj İstatistikleri:")
            print(f"   Toplam mesaj: {total_messages}")
            print(f"   Okunmamış mesaj: {unread_messages}")
            
            return True
            
        except Exception as e:
            print(f"❌ Migration hatası: {e}")
            db.session.rollback()
            return False

if __name__ == '__main__':
    success = migrate_messages()
    if success:
        print("\n🎉 Migration başarıyla tamamlandı!")
        print("Artık mesajlaşma sistemi kullanıma hazır.")
    else:
        print("\n💥 Migration başarısız oldu!")
        sys.exit(1)
