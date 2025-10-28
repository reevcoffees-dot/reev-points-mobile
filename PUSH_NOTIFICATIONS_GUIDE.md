# Push Notifications System - Implementation Guide

## Overview
The Reevpoints loyalty system now includes a comprehensive web push notification system that allows real-time communication with customers on their devices.

## Features Implemented

### 1. Service Worker (`static/sw.js`)
- Handles push events and displays notifications
- Manages notification clicks with deep linking
- Supports background sync and messaging
- Automatically navigates users to relevant pages

### 2. Notification Manager (`static/js/notifications.js`)
- `NotificationManager` class for subscription management
- Handles permission requests and subscription registration
- Provides methods for enable/disable/test notifications
- Integrates with VAPID keys for secure push messaging

### 3. Database Model (`PushSubscription`)
- Stores user notification subscriptions
- Tracks subscription endpoints and keys
- Manages active/inactive subscription states
- Links to User model for targeted notifications

### 4. Customer Dashboard Integration
- Notification permission status display
- Enable/Disable/Test notification buttons
- Real-time UI updates based on permission state
- User-friendly notification management interface

## API Endpoints

### `/api/vapid-key` (GET)
Returns the VAPID public key for push subscription registration.

**Response:**
```json
{
  "publicKey": "BEl62iUYgUivxIkv69yViEuiBIa40HI0DLLuxazjqAKVXTJtkKaMrHqk-NbMFcFvqx4XFWyQRWEaUSH_-AYmDGE"
}
```

### `/api/subscribe-notifications` (POST)
Registers a new push subscription for the current user.

**Request:**
```json
{
  "subscription": {
    "endpoint": "https://fcm.googleapis.com/fcm/send/...",
    "keys": {
      "p256dh": "...",
      "auth": "..."
    }
  }
}
```

### `/api/unsubscribe-notifications` (POST)
Deactivates all push subscriptions for the current user.

### `/api/test-notification` (POST)
Sends a test notification to the current user.

## Notification Types

### 1. Campaign Notifications (`campaign`)
- Triggered when new campaigns are created
- Sent to all customers
- Links to `/campaigns` page
- Title: "🎉 Yeni Kampanya: [Campaign Title]"

### 2. Message Notifications (`message`)
- Triggered when admin sends messages
- Sent to selected customers
- Links to `/messages` page
- Title: "📩 Yeni Mesaj: [Message Title]"

### 3. Point Earning Notifications (`points`)
- Triggered when customers earn points via QR codes
- Links to `/dashboard` page
- Title: "🎯 Puan Kazandınız!"

### 4. Campaign Usage Notifications (`campaign_usage`)
- Triggered when campaign QR codes are used
- Links to `/campaigns` page
- Title: "🎉 Kampanya Kullanıldı: [Campaign Title]"

### 5. Test Notifications (`test`)
- Manual test notifications
- Links to `/dashboard` page
- Title: "Test Bildirimi 🧪"

## Implementation Details

### Push Notification Function
```python
def send_push_notification(user_id, title, body, notification_type="general", url="/dashboard", data=None):
    # Sends push notifications to user's active subscriptions
    # Handles subscription management and error handling
    # Returns success/failure status
```

### Campaign Notification Function
```python
def send_campaign_notification(campaign):
    # Sends campaign announcements to all customers
    # Automatically called when new campaigns are created
    # Returns count of successful notifications sent
```

## Browser Support
- Chrome 42+
- Firefox 44+
- Safari 16+ (macOS 13+, iOS 16.4+)
- Edge 17+
- Opera 29+

## Security Features
- VAPID authentication for secure messaging
- User permission-based notifications
- Subscription validation and error handling
- Automatic cleanup of failed subscriptions

## Usage Instructions

### For Customers:
1. Visit the dashboard
2. Click "Bildirimleri Etkinleştir" to enable notifications
3. Allow notifications when prompted by browser
4. Use "Test Et" to verify notifications are working
5. Use "Devre Dışı Bırak" to disable notifications

### For Admins:
1. Create campaigns - automatic notifications sent to all customers
2. Send messages - automatic notifications sent to selected customers
3. QR code usage automatically triggers point and campaign notifications

## Migration Script
Run `migrate_push_subscriptions.py` to create the required database table:

```bash
python migrate_push_subscriptions.py
```

## Troubleshooting

### Notifications Not Working:
1. Check browser compatibility
2. Verify HTTPS connection (required for push notifications)
3. Ensure user has granted notification permission
4. Check browser's notification settings
5. Verify service worker registration

### Database Issues:
1. Run migration script to create push_subscription table
2. Check database connectivity
3. Verify User model relationships

### VAPID Key Issues:
1. Ensure VAPID keys are properly configured
2. Check environment variables in production
3. Verify public key format

## Production Deployment Notes

### Environment Variables:
```
VAPID_PUBLIC_KEY=your_public_key_here
VAPID_PRIVATE_KEY=your_private_key_here
VAPID_SUBJECT=mailto:your_email@domain.com
```

### HTTPS Requirement:
Push notifications require HTTPS in production. Ensure SSL certificates are properly configured.

### Performance Considerations:
- Notifications are sent asynchronously
- Failed subscriptions are automatically deactivated
- Database indexes on user_id and is_active fields for performance

## Testing Checklist

- [ ] Service worker registers successfully
- [ ] VAPID key endpoint returns valid key
- [ ] Subscription registration works
- [ ] Test notifications are received
- [ ] Campaign creation sends notifications
- [ ] Message sending triggers notifications
- [ ] QR code usage sends point notifications
- [ ] Campaign QR usage sends notifications
- [ ] Notification clicks navigate to correct pages
- [ ] Unsubscription works properly
- [ ] UI updates reflect permission status correctly

## Future Enhancements

1. **Rich Notifications**: Add images and action buttons
2. **Notification History**: Track sent notifications in database
3. **Scheduling**: Allow scheduled notifications
4. **Segmentation**: Target notifications by customer segments
5. **Analytics**: Track notification engagement metrics
6. **Templates**: Create reusable notification templates
