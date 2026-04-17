const Event = require("../models/Event");

/**
 * @desc    Get all events
 * @route   GET /api/events
 * @access  Public
 */
exports.getAllEvents = async (req, res, next) => {
  try {
    const events = await Event.find().sort({ dateTime: 1 });
    
    res.json({
      success: true,
      data: events,
    });
  } catch (error) {
    next(error);
  }
};
