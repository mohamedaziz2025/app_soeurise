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

async function sendPrivateMessage(req, res, next) {
    try {
        const targetUserId = req.params.userId;
        const message = (req.body?.message || "").toString().trim();
        if (!targetUserId || !/^[a-fA-F0-9]{24}$/.test(targetUserId)) {
            return res.status(400).json({
                success: false,
                message: "ID utilisateur invalide",
            });
        }
        if (!message) {
            return res.status(400).json({
                success: false,
                message: "Le message privé est requis",
            });
        }

        const notification = await notificationService.sendPrivateMessage({
            senderUserId: req.user._id,
            targetUserId,
            message,
        });
        res.status(201).json({ success: true, data: { notification } });
    } catch (err) {
        next(err);
    }
}

module.exports = {
    listNotifications,
    markRead,
    markAllRead,
    deleteNotification,
    sendPrivateMessage,
};
