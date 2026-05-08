const mongoose = require("mongoose");

const groupInviteSchema = new mongoose.Schema(
    {
        groupId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Group",
            required: true,
        },
        token: {
            type: String,
            required: true,
            unique: true,
            index: true,
        },
        createdBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
        },
        expiresAt: {
            type: Date,
            default: null,
        },
        maxUses: {
            type: Number,
            default: null,
        },
        usesCount: {
            type: Number,
            default: 0,
        },
        isActive: {
            type: Boolean,
            default: true,
        },
        lastUsedAt: {
            type: Date,
            default: null,
        },
    },
    { timestamps: true }
);

groupInviteSchema.methods.toPublic = function () {
    return {
        id: this._id,
        groupId: this.groupId,
        token: this.token,
        createdBy: this.createdBy,
        expiresAt: this.expiresAt,
        maxUses: this.maxUses,
        usesCount: this.usesCount,
        isActive: this.isActive,
        lastUsedAt: this.lastUsedAt,
        createdAt: this.createdAt,
    };
};

module.exports = mongoose.model("GroupInvite", groupInviteSchema);
