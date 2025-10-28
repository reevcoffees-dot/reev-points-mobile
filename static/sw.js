// Service Worker for Push Notifications
const CACHE_NAME = 'cafe-loyalty-v1';

// Install event
self.addEventListener('install', event => {
    console.log('Service Worker installing...');
    self.skipWaiting();
});

// Activate event
self.addEventListener('activate', event => {
    console.log('Service Worker activating...');
    event.waitUntil(self.clients.claim());
});

// Push event handler
self.addEventListener('push', event => {
    console.log('Push event received:', event);
    
    let notificationData = {
        title: 'Cafe Sadakat',
        body: 'Yeni bir bildiriminiz var!',
        icon: '/static/icons/icon-192.png',
        badge: '/static/icons/icon-192.png',
        tag: 'cafe-notification',
        requireInteraction: true,
        actions: [
            {
                action: 'view',
                title: 'Görüntüle',
                icon: '/static/icons/icon-192.png'
            },
            {
                action: 'dismiss',
                title: 'Kapat'
            }
        ],
        data: {
            url: '/dashboard'
        }
    };

    // Parse push data if available
    if (event.data) {
        try {
            const pushData = event.data.json();
            notificationData = {
                ...notificationData,
                ...pushData
            };
        } catch (e) {
            console.error('Error parsing push data:', e);
            notificationData.body = event.data.text() || notificationData.body;
        }
    }

    event.waitUntil(
        self.registration.showNotification(notificationData.title, notificationData)
    );
});

// Notification click handler
self.addEventListener('notificationclick', event => {
    console.log('Notification clicked:', event);
    
    event.notification.close();
    
    const action = event.action;
    const notificationData = event.notification.data || {};
    
    if (action === 'dismiss') {
        return;
    }
    
    // Default action or 'view' action
    let urlToOpen = notificationData.url || '/dashboard';
    
    // Handle different notification types
    if (notificationData.type === 'message') {
        urlToOpen = '/messages';
    } else if (notificationData.type === 'campaign') {
        urlToOpen = '/campaigns';
    }
    
    event.waitUntil(
        clients.matchAll({ type: 'window', includeUncontrolled: true })
            .then(clientList => {
                // Check if the app is already open
                for (let client of clientList) {
                    if (client.url.includes(self.location.origin)) {
                        client.focus();
                        client.postMessage({
                            type: 'NOTIFICATION_CLICKED',
                            url: urlToOpen,
                            data: notificationData
                        });
                        return;
                    }
                }
                
                // If no window is open, open a new one
                return clients.openWindow(urlToOpen);
            })
    );
});

// Background sync (for offline support)
self.addEventListener('sync', event => {
    console.log('Background sync triggered:', event.tag);
    
    if (event.tag === 'background-sync') {
        event.waitUntil(
            // Handle background sync tasks
            Promise.resolve()
        );
    }
});

// Message handler for communication with main thread
self.addEventListener('message', event => {
    console.log('Service Worker received message:', event.data);
    
    if (event.data && event.data.type === 'SKIP_WAITING') {
        self.skipWaiting();
    }
});
