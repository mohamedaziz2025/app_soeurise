const express = require("express");
const router = express.Router();
const eventsController = require("../controllers/events.controller");

// GET /api/events
router.get("/", eventsController.getAllEvents);

module.exports = router;
