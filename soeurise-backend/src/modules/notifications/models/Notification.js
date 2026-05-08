const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true,
        },
        type: {
            type: String,
            required: true,
        },
        title: { type: String, default: "" },
        message: { type: String, default: "" },
        data: { type: Object, default: {} },
        isRead: { type: Boolean, default: false },
    },
    { timestamps: true }
);

notificationSchema.methods.toPublic = function () {
    return {
        id: this._id,
        userId: this.userId,
        type: this.type,
        title: this.title,
        message: this.message,
        data: this.data,
        isRead: this.isRead,
        createdAt: this.createdAt,
    };
};

module.exports = mongoose.model("Notification", notificationSchema);
