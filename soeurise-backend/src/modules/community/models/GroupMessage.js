const mongoose = require("mongoose");

const groupMessageSchema = new mongoose.Schema(
    {
        groupId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Group",
            required: true,
            index: true,
        },
        senderId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
        },
        text: {
            type: String,
            trim: true,
            maxlength: 5000,
            default: "",
        },
        imageUrl: { type: String, default: "" },
        imageMime: { type: String, default: "" },
    },
    { timestamps: true }
);

groupMessageSchema.methods.toPublic = function () {
    const sender = this.senderId || {};
    return {
        id: this._id,
        groupId: this.groupId,
        text: this.text,
        imageUrl: this.imageUrl,
        imageMime: this.imageMime,
        createdAt: this.createdAt,
        sender: sender && sender._id
            ? {
                id: sender._id,
                firstName: sender.firstName,
                lastName: sender.lastName,
                username: sender.username,
                avatarUrl: sender.avatarUrl,
            }
            : null,
    };
};

module.exports = mongoose.model("GroupMessage", groupMessageSchema);
