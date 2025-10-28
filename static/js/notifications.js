// Push Notification Manager
class NotificationManager {
    constructor() {
        this.isSupported = 'serviceWorker' in navigator && 'PushManager' in window;
        this.registration = null;
        this.subscription = null;
        this.vapidPublicKey = null;
    }

    async init() {
        if (!this.isSupported) {
            console.warn('Push notifications are not supported in this browser');
            return false;
        }

        try {
            // Register service worker
            this.registration = await navigator.serviceWorker.register('/static/sw.js');
            console.log('Service Worker registered successfully');

            // Get VAPID public key from server
            await this.getVapidKey();

            // Check existing subscription
            this.subscription = await this.registration.pushManager.getSubscription();
            
            return true;
        } catch (error) {
            console.error('Failed to initialize notifications:', error);
            return false;
        }
    }

    async getVapidKey() {
        try {
            const response = await fetch('/api/vapid-key');
            const data = await response.json();
            this.vapidPublicKey = data.publicKey;
        } catch (error) {
            console.error('Failed to get VAPID key:', error);
            throw new Error('VAPID key alınamadı. Bildirimler çalışmayabilir.');
        }
    }

    async requestPermission() {
        if (!this.isSupported) {
            throw new Error('Push notifications are not supported');
        }

        const permission = await Notification.requestPermission();
        
        if (permission === 'granted') {
            await this.subscribe();
            return true;
        } else if (permission === 'denied') {
            throw new Error('Notification permission denied');
        } else {
            throw new Error('Notification permission dismissed');
        }
    }

    async subscribe() {
        if (!this.registration || !this.vapidPublicKey) {
            throw new Error('Service worker not ready');
        }

        try {
            const subscription = await this.registration.pushManager.subscribe({
                userVisibleOnly: true,
                applicationServerKey: this.urlBase64ToUint8Array(this.vapidPublicKey)
            });

            this.subscription = subscription;

            // Send subscription to server
            await this.sendSubscriptionToServer(subscription);
            
            console.log('Successfully subscribed to push notifications');
            return subscription;
        } catch (error) {
            console.error('Failed to subscribe to push notifications:', error);
            throw error;
        }
    }

    async unsubscribe() {
        if (!this.subscription) {
            return true;
        }

        try {
            await this.subscription.unsubscribe();
            await this.removeSubscriptionFromServer();
            this.subscription = null;
            console.log('Successfully unsubscribed from push notifications');
            return true;
        } catch (error) {
            console.error('Failed to unsubscribe:', error);
            throw error;
        }
    }

    async sendSubscriptionToServer(subscription) {
        const response = await fetch('/api/subscribe-notifications', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                subscription: subscription.toJSON()
            }),
            credentials: 'same-origin'
        });

        if (!response.ok) {
            throw new Error('Failed to send subscription to server');
        }

        return response.json();
    }

    async removeSubscriptionFromServer() {
        const response = await fetch('/api/unsubscribe-notifications', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'same-origin'
        });

        return response.ok;
    }

    urlBase64ToUint8Array(base64String) {
        const padding = '='.repeat((4 - base64String.length % 4) % 4);
        const base64 = (base64String + padding)
            .replace(/-/g, '+')
            .replace(/_/g, '/');

        const rawData = window.atob(base64);
        const outputArray = new Uint8Array(rawData.length);

        for (let i = 0; i < rawData.length; ++i) {
            outputArray[i] = rawData.charCodeAt(i);
        }
        return outputArray;
    }

    isSubscribed() {
        return this.subscription !== null;
    }

    getPermissionStatus() {
        if (!this.isSupported) {
            return 'not-supported';
        }
        
        return Notification.permission;
    }

    // Fallback notification system for unsupported browsers
    showFallbackNotification(title, body, type = 'info') {
        // Create in-app notification banner
        const notification = document.createElement('div');
        notification.className = `alert alert-${type} alert-dismissible fade show position-fixed`;
        notification.style.cssText = `
            top: 20px;
            right: 20px;
            z-index: 9999;
            max-width: 350px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        `;
        
        notification.innerHTML = `
            <strong>${title}</strong><br>
            ${body}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        
        document.body.appendChild(notification);
        
        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.remove();
            }
        }, 5000);
        
        return true;
    }

    // Test notification
    async sendTestNotification() {
        if (!this.isSubscribed()) {
            throw new Error('Not subscribed to notifications');
        }

        const response = await fetch('/api/test-notification', {
            method: 'POST',
            credentials: 'same-origin'
        });

        if (!response.ok) {
            throw new Error('Failed to send test notification');
        }

        return response.json();
    }
}

// Global notification manager instance
window.notificationManager = new NotificationManager();

// Auto-initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', async () => {
    await window.notificationManager.init();
    
    // Listen for service worker messages
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.addEventListener('message', event => {
            if (event.data && event.data.type === 'NOTIFICATION_CLICKED') {
                // Handle notification click navigation
                if (event.data.url && event.data.url !== window.location.pathname) {
                    window.location.href = event.data.url;
                }
            }
        });
    }
});
