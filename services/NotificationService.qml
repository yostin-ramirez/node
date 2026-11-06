pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon: receives system notifications and decides what is shown and for how long
// Display lifetime is owned here, so a sender closing early never cuts it short
Singleton {
    id: root

    // Latest shown notification as plain data, kept after hiding so the UI can fade out safely
    property var current: ({
            appName: "",
            title: "",
            body: "",
            image: ""
        })
    property bool isActive: false

    // Time limits in milliseconds
    readonly property int _defaultDuration: 5000
    readonly property int _minDuration: 3000
    readonly property int _maxDuration: 10000

    // A notification stays at least this long before a newer one replaces it
    readonly property int _minVisibleTime: 1200

    // Entry shape: { data, duration, source } where source is the live notification or null once closed
    property var _shown: null
    property var _pending: null
    property real _shownAt: 0

    // Closes the visible notification as dismissed by the user
    function dismiss() {
        if (_shown)
            _advance(true);
    }

    function _receive(notification) {
        // Tracking keeps the object alive until it is closed
        notification.tracked = true;
        notification.closed.connect(() => root._detach(notification));

        const entry = {
            data: _snapshot(notification),
            duration: _durationOf(notification),
            source: notification
        };

        if (!_shown) {
            _show(entry);
            return;
        }

        // Only the newest waiting entry survives
        _release(_pending, entry, false);
        _pending = entry;

        const wait = _minVisibleTime - (Date.now() - _shownAt);
        if (wait <= 0) {
            _advance(false);
        } else {
            swapTimer.interval = wait;
            swapTimer.restart();
        }
    }

    function _show(entry) {
        _shown = entry;
        _shownAt = Date.now();
        current = entry.data;
        isActive = true;

        hideTimer.interval = entry.duration;
        hideTimer.restart();
    }

    // Finishes the shown entry and moves on to the pending one, if any
    function _advance(byUser) {
        hideTimer.stop();
        swapTimer.stop();

        const finished = _shown;
        const next = _pending;
        _shown = null;
        _pending = null;

        _release(finished, next, byUser);

        if (next)
            _show(next);
        else
            isActive = false;
    }

    // Closes the sender side of an entry
    // Skipped when the server reused the id for the new one, closing by id would hit it too
    function _release(entry, keeper, byUser) {
        if (!entry || !entry.source)
            return;
        if (keeper && keeper.source && keeper.source.id === entry.source.id)
            return;

        if (byUser)
            entry.source.dismiss();
        else
            entry.source.expire();
    }

    // The sender closed it: keep the snapshot, just drop the dead reference
    function _detach(notification) {
        if (_shown && _shown.source === notification)
            _shown.source = null;
        if (_pending && _pending.source === notification)
            _pending.source = null;
    }

    function _snapshot(notification) {
        return {
            appName: notification.appName,
            title: notification.summary || notification.appName,
            body: notification.body,
            // Identical strings keep the Image from reloading between notifications
            image: _resolveImage(notification)
        };
    }

    // Sender image (e.g. profile picture) wins over the app icon
    function _resolveImage(notification) {
        if (notification.image)
            return notification.image;

        const icon = notification.appIcon;
        if (!icon)
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon;

        return Quickshell.iconPath(icon, true);
    }

    // expireTimeout is in seconds, clamped so the bubble never lingers or flashes
    function _durationOf(notification) {
        const requested = notification.expireTimeout * 1000;
        const duration = requested > 0 ? requested : _defaultDuration;
        return Math.max(_minDuration, Math.min(_maxDuration, duration));
    }

    NotificationServer {
        keepOnReload: false
        imageSupported: true
        onNotification: notification => root._receive(notification)
    }

    Timer {
        id: hideTimer
        onTriggered: root._advance(false)
    }

    // Fires when the shown entry has been visible long enough to be replaced
    Timer {
        id: swapTimer
        onTriggered: root._advance(false)
    }
}
