const notificationService = require("../services/notification.service");

async function listNotifications(req, res, next) {
    try {
        const limit = Math.min(parseInt(req.query.limit, 10) || 30, 100);
        const items = await notificationService.listNotifications(req.user._id, limit);
        res.json({ success: true, data: { notifications: items } });
    } catch (err) {
        next(err);
    }
}

async function markRead(req, res, next) {
    try {
        const notif = await notificationService.markRead(req.user._id, req.params.id);
        res.json({ success: true, data: { notification: notif } });
    } catch (err) {
        next(err);
    }
}

async function markAllRead(req, res, next) {
    try {
        const result = await notificationService.markAllRead(req.user._id);
        res.json({ success: true, message: result.message });
    } catch (err) {
        next(err);
    }
}

async function deleteNotification(req, res, next) {
    try {
        const result = await notificationService.deleteNotification(req.user._id, req.params.id);
        res.json({ success: true, message: result.message });
    } catch (err) {
        next(err);
    }
}

module.exports = {
    listNotifications,
    markRead,
    markAllRead,
    deleteNotification,
};
