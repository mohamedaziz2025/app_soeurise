const crypto = require("crypto");
const Group = require("../models/Group");
const GroupMember = require("../models/GroupMember");
const GroupMessage = require("../models/GroupMessage");
const GroupInvite = require("../models/GroupInvite");
const Subscription = require("../models/Subscription");
const User = require("../../users/models/User");
const { formatPagination } = require("../../../utils/pagination");
const { APP_BASE_URL } = require("../../../config/env");

function buildInviteUrl(token) {
    if (!APP_BASE_URL) return "";
    const base = APP_BASE_URL.endsWith("/")
        ? APP_BASE_URL.slice(0, -1)
        : APP_BASE_URL;
    return `${base}/invite/${token}`;
}

// ──────────────────────────────────────────
//  Phase 3-4: fonctions existantes
// ──────────────────────────────────────────

async function createGroup(userId, data, imageFile) {
    const exists = await Group.findOne({ name: data.name });
    if (exists) {
        const err = new Error("Un groupe avec ce nom existe déjà");
        err.statusCode = 409;
        throw err;
    }

    const groupData = {
        name: data.name,
        description: data.description || "",
        isPublic: data.isPublic !== undefined ? data.isPublic : true,
        requiresSubscription: data.requiresSubscription || false,
        createdBy: userId,
    };

    if (imageFile) {
        groupData.imageUrl = `/uploads/groups/${imageFile.filename}`;
        groupData.imageMime = imageFile.mimetype;
    }

    const group = await Group.create(groupData);

    await GroupMember.create({
        groupId: group._id,
        userId: userId,
        roleInGroup: "owner",
        status: "active",
        joinedAt: new Date(),
    });

    return group.toPublic();
}

async function listPublicGroups(page, limit, search) {
    const skip = (page - 1) * limit;
    const filter = { isPublic: true };

    if (search && search.trim()) {
        const regex = new RegExp(search.trim(), "i");
        filter.$or = [{ name: regex }, { description: regex }];
    }

    const [groups, total] = await Promise.all([
        Group.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
        Group.countDocuments(filter),
    ]);

    return {
        groups: groups.map((g) => g.toPublic()),
        pagination: formatPagination(page, limit, total),
    };
}

async function canViewGroup(groupId, userId) {
    const group = await Group.findById(groupId);
    if (!group) {
        const err = new Error("Groupe non trouvé");
        err.statusCode = 404;
        throw err;
    }

    if (group.isPublic) {
        return { canView: true, group: group.toPublic() };
    }

    if (!userId) {
        return { canView: false, group: null };
    }

    const member = await GroupMember.findOne({
        groupId, userId, status: "active",
    });

    return {
        canView: !!member,
        group: member ? group.toPublic() : null,
    };
}

async function joinGroup(groupId, userId) {
    const group = await Group.findById(groupId);
    if (!group) {
        const err = new Error("Groupe non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const existing = await GroupMember.findOne({ groupId, userId });
    if (existing) {
        if (existing.status === "banned") {
            const err = new Error("Vous êtes banni de ce groupe");
            err.statusCode = 403;
            throw err;
        }
        if (existing.status === "active") {
            return {
                membership: existing.toPublic(),
                message: "Vous êtes déjà membre de ce groupe",
                status: existing.status,
                alreadyMember: true,
            };
        }
        if (existing.status === "pending") {
            return {
                membership: existing.toPublic(),
                message: "Votre demande d'adhésion est en attente",
                status: existing.status,
                alreadyMember: true,
            };
        }
    }

    if (group.requiresSubscription) {
        const sub = await Subscription.findOne({
            groupId, userId, status: "active",
        });
        if (!sub) {
            const err = new Error("Une souscription active est requise pour rejoindre ce groupe");
            err.statusCode = 403;
            throw err;
        }
    }

    const status = group.isPublic ? "active" : "pending";

    const member = await GroupMember.create({
        groupId, userId,
        roleInGroup: "member",
        status,
        joinedAt: status === "active" ? new Date() : null,
    });

    return {
        membership: member.toPublic(),
        message: status === "active"
            ? "Vous avez rejoint le groupe"
            : "Demande d'adhésion envoyée, en attente d'approbation",
        status,
        alreadyMember: false,
    };
}

async function getMembership(groupId, userId) {
    const group = await Group.findById(groupId);
    if (!group) {
        const err = new Error("Groupe non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const member = await GroupMember.findOne({ groupId, userId });

    if (!member) {
        return { status: "none", roleInGroup: null, membership: null };
    }

    return {
        status: member.status,
        roleInGroup: member.roleInGroup,
        isMuted: member.isMuted,
        membership: member.toPublic(),
    };
}

async function listMyMemberships(userId) {
    const members = await GroupMember.find({
        userId,
        status: { $in: ["active", "pending"] },
    }).select("groupId status roleInGroup isMuted");

    return members.map((m) => ({
        groupId: m.groupId,
        status: m.status,
        roleInGroup: m.roleInGroup,
        isMuted: m.isMuted,
    }));
}

async function isSubscribed(groupId, userId) {
    if (!userId) return { subscribed: false, subscription: null };

    const sub = await Subscription.findOne({
        groupId, userId, status: "active",
    });

    return {
        subscribed: !!sub,
        subscription: sub ? sub.toPublic() : null,
    };
}

async function getSubscription(groupId, userId) {
    const group = await Group.findById(groupId);
    if (!group) {
        const err = new Error("Groupe non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const sub = await Subscription.findOne({ groupId, userId });

    return {
        isSubscribed: !!sub && sub.status === "active",
        plan: sub ? sub.plan : null,
        status: sub ? sub.status : null,
        subscription: sub ? sub.toPublic() : null,
    };
}

// ──────────────────────────────────────────
//  Phase 5: gestion membres & demandes
// ──────────────────────────────────────────

/**
 * Liste des demandes pending pour un groupe
 */
async function listPendingRequests(groupId) {
    const group = await Group.findById(groupId);
    if (!group) {
        const err = new Error("Groupe non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const requests = await GroupMember.find({
        groupId, status: "pending",
    }).populate("userId", "firstName lastName username email avatarUrl");

    return requests.map((r) => ({
        id: r._id,
        user: r.userId
            ? {
                id: r.userId._id,
                firstName: r.userId.firstName,
                lastName: r.userId.lastName,
                username: r.userId.username,
                email: r.userId.email,
                avatarUrl: r.userId.avatarUrl,
            }
            : null,
        roleInGroup: r.roleInGroup,
        status: r.status,
        createdAt: r.createdAt,
    }));
}

/**
 * Accepter ou rejeter une demande d'adhésion
 * accept → status "active" + joinedAt
 * reject → supprimer le membership
 */
async function handleRequest(groupId, memberId, action) {
    const member = await GroupMember.findOne({
        _id: memberId,
        groupId,
        status: "pending",
    });

    if (!member) {
        const err = new Error("Demande non trouvée ou déjà traitée");
        err.statusCode = 404;
        throw err;
    }

    if (action === "accept") {
        member.status = "active";
        member.joinedAt = new Date();
        await member.save();
        return { membership: member.toPublic(), message: "Demande acceptée" };
    } else {
        // reject → supprimer le record
        await GroupMember.findByIdAndDelete(memberId);
        return { membership: null, message: "Demande rejetée" };
    }
}

/**
 * Ajouter un membre directement (par owner/moderator/admin)
 */
async function addMember(groupId, targetUserId, roleInGroup) {
    const group = await Group.findById(groupId);
    if (!group) {
        const err = new Error("Groupe non trouvé");
        err.statusCode = 404;
        throw err;
    }

    // Vérifier que l'utilisateur cible existe
    const targetUser = await User.findById(targetUserId);
    if (!targetUser) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    // Vérifier doublon
    const existing = await GroupMember.findOne({
        groupId, userId: targetUserId,
    });
    if (existing) {
        const err = new Error("Cet utilisateur est déjà membre ou a une demande en cours");
        err.statusCode = 409;
        throw err;
    }

    // Vérifier subscription si requise
    if (group.requiresSubscription) {
        const sub = await Subscription.findOne({
            groupId, userId: targetUserId, status: "active",
        });
        if (!sub) {
            const err = new Error("L'utilisateur n'a pas de souscription active pour ce groupe");
            err.statusCode = 403;
            throw err;
        }
    }

    const member = await GroupMember.create({
        groupId,
        userId: targetUserId,
        roleInGroup: roleInGroup || "member",
        status: "active",
        joinedAt: new Date(),
    });

    return member.toPublic();
}

/**
 * Modifier le rôle ou le statut d'un membre
 */
async function updateMember(groupId, memberId, updates) {
    const member = await GroupMember.findOne({ _id: memberId, groupId });

    if (!member) {
        const err = new Error("Membre non trouvé");
        err.statusCode = 404;
        throw err;
    }

    // Protéger l'owner: on ne peut pas changer le statut de l'owner
    if (member.roleInGroup === "owner" && updates.status === "banned") {
        const err = new Error("Impossible de bannir le propriétaire du groupe");
        err.statusCode = 403;
        throw err;
    }

    if (updates.roleInGroup !== undefined) {
        member.roleInGroup = updates.roleInGroup;
    }
    if (updates.status !== undefined) {
        member.status = updates.status;
        if (updates.status === "active" && !member.joinedAt) {
            member.joinedAt = new Date();
        }
    }
    if (updates.isMuted !== undefined) {
        member.isMuted = updates.isMuted;
    }

    await member.save();
    return member.toPublic();
}

/**
 * Supprimer un membre du groupe
 */
async function removeMember(groupId, memberId) {
    const member = await GroupMember.findOne({ _id: memberId, groupId });

    if (!member) {
        const err = new Error("Membre non trouvé");
        err.statusCode = 404;
        throw err;
    }

    // Protéger l'owner
    if (member.roleInGroup === "owner") {
        const err = new Error("Impossible de supprimer le propriétaire du groupe");
        err.statusCode = 403;
        throw err;
    }

    await GroupMember.findByIdAndDelete(memberId);
    return { message: "Membre supprimé du groupe" };
}

async function leaveGroup(groupId, userId) {
    const member = await GroupMember.findOne({ groupId, userId, status: "active" });

    if (!member) {
        const err = new Error("Vous n'etes pas membre actif de ce groupe");
        err.statusCode = 404;
        throw err;
    }

    if (member.roleInGroup === "owner") {
        const err = new Error("Le proprietaire ne peut pas quitter le groupe");
        err.statusCode = 403;
        throw err;
    }

    await GroupMember.findByIdAndDelete(member._id);
    return { message: "Vous avez quitte le groupe" };
}

async function listMembers(groupId) {
    const group = await Group.findById(groupId);
    if (!group) {
        const err = new Error("Groupe non trouve");
        err.statusCode = 404;
        throw err;
    }

    const members = await GroupMember.find({ groupId })
        .populate("userId", "firstName lastName username email avatarUrl")
        .sort({ createdAt: 1 });

    return members.map((m) => ({
        id: m._id,
        groupId: m.groupId,
        user: m.userId
            ? {
                id: m.userId._id,
                firstName: m.userId.firstName,
                lastName: m.userId.lastName,
                username: m.userId.username,
                email: m.userId.email,
                avatarUrl: m.userId.avatarUrl,
            }
            : null,
        roleInGroup: m.roleInGroup,
        status: m.status,
        isMuted: m.isMuted,
        joinedAt: m.joinedAt,
        createdAt: m.createdAt,
    }));
}

async function listMessages(groupId, userId, limit = 30, before) {
    const member = await GroupMember.findOne({ groupId, userId, status: "active" });
    if (!member) {
        const err = new Error("Vous n'etes pas membre actif de ce groupe");
        err.statusCode = 403;
        throw err;
    }

    const query = { groupId };
    if (before) {
        query.createdAt = { $lt: before };
    }

    const messages = await GroupMessage.find(query)
        .sort({ createdAt: -1 })
        .limit(limit)
        .populate("senderId", "firstName lastName username avatarUrl");

    return messages.map((m) => m.toPublic()).reverse();
}

async function createMessage(groupId, userId, text, imageFile) {
    const member = await GroupMember.findOne({ groupId, userId, status: "active" });
    if (!member) {
        const err = new Error("Vous n'etes pas membre actif de ce groupe");
        err.statusCode = 403;
        throw err;
    }

    if (member.isMuted) {
        const err = new Error("Vous etes mute dans ce groupe");
        err.statusCode = 403;
        throw err;
    }

    const trimmed = (text || "").trim();
    if (!trimmed && !imageFile) {
        const err = new Error("Message vide");
        err.statusCode = 400;
        throw err;
    }

    const messageData = {
        groupId,
        senderId: userId,
        text: trimmed,
        imageUrl: imageFile ? `/uploads/group-messages/${imageFile.filename}` : "",
        imageMime: imageFile ? imageFile.mimetype : "",
    };

    const message = await GroupMessage.create(messageData);
    const populated = await GroupMessage.findById(message._id).populate(
        "senderId",
        "firstName lastName username avatarUrl"
    );

    return populated.toPublic();
}

// ──────────────────────────────────────────
//  Phase 6: liens d'invitation & recherche utilisateurs
// ──────────────────────────────────────────

async function searchUsers(search, limit, excludeUserId) {
    const trimmed = (search || "").trim();
    if (!trimmed) return [];

    const regex = new RegExp(trimmed, "i");
    const filter = {
        isActive: true,
        $or: [
            { firstName: regex },
            { lastName: regex },
            { username: regex },
            { email: regex },
        ],
    };

    if (excludeUserId) {
        filter._id = { $ne: excludeUserId };
    }

    const users = await User.find(filter).limit(limit);
    return users.map((u) => u.toPublic());
}

async function createInvite(groupId, userId, options) {
    const group = await Group.findById(groupId);
    if (!group) {
        const err = new Error("Groupe non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const token = crypto.randomBytes(24).toString("hex");
    const inviteData = {
        groupId,
        createdBy: userId,
        token,
    };

    if (options && options.expiresInDays) {
        inviteData.expiresAt = new Date(
            Date.now() + options.expiresInDays * 24 * 60 * 60 * 1000
        );
    }

    if (options && options.maxUses) {
        inviteData.maxUses = options.maxUses;
    }

    const invite = await GroupInvite.create(inviteData);

    return {
        invite: {
            ...invite.toPublic(),
            inviteUrl: buildInviteUrl(token),
        },
        group: group.toPublic(),
    };
}

async function joinByInvite(token, userId) {
    const invite = await GroupInvite.findOne({ token, isActive: true });
    if (!invite) {
        const err = new Error("Lien d'invitation invalide ou expiré");
        err.statusCode = 404;
        throw err;
    }

    if (invite.expiresAt && invite.expiresAt.getTime() < Date.now()) {
        const err = new Error("Lien d'invitation expiré");
        err.statusCode = 410;
        throw err;
    }

    if (invite.maxUses && invite.usesCount >= invite.maxUses) {
        const err = new Error("Lien d'invitation déjà utilisé");
        err.statusCode = 410;
        throw err;
    }

    const group = await Group.findById(invite.groupId);
    if (!group) {
        const err = new Error("Groupe non trouvé");
        err.statusCode = 404;
        throw err;
    }

    if (group.requiresSubscription) {
        const sub = await Subscription.findOne({
            groupId: group._id,
            userId,
            status: "active",
        });
        if (!sub) {
            const err = new Error(
                "Une souscription active est requise pour rejoindre ce groupe"
            );
            err.statusCode = 403;
            throw err;
        }
    }

    let member = await GroupMember.findOne({ groupId: group._id, userId });

    if (member) {
        if (member.status === "banned") {
            const err = new Error("Vous êtes banni de ce groupe");
            err.statusCode = 403;
            throw err;
        }
        if (member.status === "active") {
            return {
                membership: member.toPublic(),
                group: group.toPublic(),
                invite: invite.toPublic(),
                alreadyMember: true,
            };
        }
        if (member.status === "pending") {
            member.status = "active";
            member.joinedAt = new Date();
            await member.save();
        }
    } else {
        member = await GroupMember.create({
            groupId: group._id,
            userId,
            roleInGroup: "member",
            status: "active",
            joinedAt: new Date(),
        });
    }

    invite.usesCount += 1;
    invite.lastUsedAt = new Date();
    if (invite.maxUses && invite.usesCount >= invite.maxUses) {
        invite.isActive = false;
    }
    await invite.save();

    return {
        membership: member.toPublic(),
        group: group.toPublic(),
        invite: invite.toPublic(),
        alreadyMember: false,
    };
}

module.exports = {
    createGroup,
    listPublicGroups,
    canViewGroup,
    joinGroup,
    getMembership,
    listMyMemberships,
    isSubscribed,
    getSubscription,
    // Phase 5
    listPendingRequests,
    handleRequest,
    addMember,
    updateMember,
    removeMember,
    leaveGroup,
    listMembers,
    listMessages,
    createMessage,
    searchUsers,
    createInvite,
    joinByInvite,
};
