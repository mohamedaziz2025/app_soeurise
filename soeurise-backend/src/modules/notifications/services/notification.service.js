const Notification = require("../models/Notification");

function getIoSafe() {
    try {
        // eslint-disable-next-line global-require
        const { getIo } = require("../../../socket");
        return getIo();
    } catch (_) {
        return null;
    }
}

async function createNotification({ userId, type, title = "", message = "", data = {} }) {
    const notif = await Notification.create({
        userId,
        type,
        title,
        message,
        data,
    });

    const io = getIoSafe();
    if (io) {
        io.to(`user:${userId}`).emit("notification", notif.toPublic());
    }

    return notif.toPublic();
}

async function listNotifications(userId, limit = 30) {
    const items = await Notification.find({ userId })
        .sort({ createdAt: -1 })
        .limit(limit);

    return items.map((n) => n.toPublic());
}

async function markRead(userId, notificationId) {
    const notif = await Notification.findOne({ _id: notificationId, userId });
    if (!notif) {
        const err = new Error("Notification introuvable");
        err.statusCode = 404;
        throw err;
    }

    if (!notif.isRead) {
        notif.isRead = true;
        await notif.save();
    }

    return notif.toPublic();
}

async function markAllRead(userId) {
    await Notification.updateMany({ userId, isRead: false }, { isRead: true });
    return { message: "Toutes les notifications sont lues" };
}

async function deleteNotification(userId, notificationId) {
    const notif = await Notification.findOne({ _id: notificationId, userId });
    if (!notif) {
        const err = new Error("Notification introuvable");
        err.statusCode = 404;
        throw err;
    }

    await Notification.findByIdAndDelete(notificationId);
    return { message: "Notification supprimee" };
}

module.exports = {
    createNotification,
    listNotifications,
    markRead,
    markAllRead,
    deleteNotification,
};
