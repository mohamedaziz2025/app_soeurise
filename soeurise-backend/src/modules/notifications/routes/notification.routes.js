const express = require("express");
const router = express.Router();

const { requireAuth } = require("../../../middlewares/auth");
const notificationController = require("../controllers/notification.controller");

router.use(requireAuth);

// GET /api/notifications
router.get("/", notificationController.listNotifications);

// POST /api/notifications/read-all
router.post("/read-all", notificationController.markAllRead);

// POST /api/notifications/private/:userId
router.post("/private/:userId", notificationController.sendPrivateMessage);

// POST /api/notifications/:id/read
router.post("/:id/read", notificationController.markRead);

// DELETE /api/notifications/:id
router.delete("/:id", notificationController.deleteNotification);

module.exports = router;
