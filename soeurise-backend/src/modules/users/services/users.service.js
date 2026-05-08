const User = require("../models/User");
const { deleteFileSafe } = require("../../../utils/file");

/**
 * Mettre à jour le profil (firstName, lastName, username, email)
 * Vérifie l'unicité username/email
 */
async function updateProfile(userId, data) {
    const { firstName, lastName, username, email } = data;
    const emailLower = email.toLowerCase();

    // Vérifier unicité username (exclure soi-même)
    const usernameExists = await User.findOne({
        username,
        _id: { $ne: userId },
    });
    if (usernameExists) {
        const err = new Error("Ce nom d'utilisateur est déjà utilisé");
        err.statusCode = 409;
        throw err;
    }

    // Vérifier unicité email (exclure soi-même)
    const emailExists = await User.findOne({
        email: emailLower,
        _id: { $ne: userId },
    });
    if (emailExists) {
        const err = new Error("Cet email est déjà utilisé");
        err.statusCode = 409;
        throw err;
    }

    const user = await User.findById(userId);
    if (!user) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    user.firstName = firstName;
    user.lastName = lastName;
    user.username = username;
    user.email = emailLower;
    await user.save();

    return user.toPublic();
}

/**
 * Mettre à jour l'avatar (upload nouveau + supprimer ancien fichier)
 */
async function updateAvatar(userId, file) {
    const user = await User.findById(userId);
    if (!user) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const oldAvatarUrl = user.avatarUrl;

    user.avatarUrl = `/uploads/avatars/${file.filename}`;
    user.avatarMime = file.mimetype;
    await user.save();

    // Supprimer ancien fichier après save
    await deleteFileSafe(oldAvatarUrl);

    return user.toPublic();
}

/**
 * Supprimer l'avatar (fichier + vider champs)
 */
async function deleteAvatar(userId) {
    const user = await User.findById(userId);
    if (!user) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const oldAvatarUrl = user.avatarUrl;

    user.avatarUrl = "";
    user.avatarMime = "";
    await user.save();

    await deleteFileSafe(oldAvatarUrl);

    return user.toPublic();
}

/**
 * Toggle follow (public profile) or send follow request (private profile)
 */
async function toggleFollow(currentUserId, targetUserId) {
    if (currentUserId.toString() === targetUserId.toString()) {
        const err = new Error("Vous ne pouvez pas vous suivre vous-même");
        err.statusCode = 400;
        throw err;
    }

    const targetUser = await User.findById(targetUserId);
    if (!targetUser) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const currentUser = await User.findById(currentUserId);
    if (!currentUser) {
        const err = new Error("Utilisateur courant non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const isFollowing = currentUser.following.includes(targetUserId);

    if (isFollowing) {
        // Unfollow
        currentUser.following.pull(targetUserId);
        targetUser.followers.pull(currentUserId);
        await currentUser.save();
        await targetUser.save();
        return { isFollowing: false, isPending: false };
    } else {
        // Check target profile privacy
        if (targetUser.profilePrivacy === "private") {
            // Send follow request
            const existingRequest = targetUser.followRequests.find(
                (req) => req.from.toString() === currentUserId.toString()
            );

            if (existingRequest) {
                if (existingRequest.status === "pending") {
                    return { isFollowing: false, isPending: true, message: "Demande déjà envoyée" };
                } else if (existingRequest.status === "rejected") {
                    existingRequest.status = "pending";
                    existingRequest.requestedAt = new Date();
                }
            } else {
                targetUser.followRequests.push({
                    from: currentUserId,
                    status: "pending",
                });
            }

            await targetUser.save();
            return { isFollowing: false, isPending: true };
        } else {
            // Public profile - follow immediately
            currentUser.following.push(targetUserId);
            targetUser.followers.push(currentUserId);
            await currentUser.save();
            await targetUser.save();
            return { isFollowing: true, isPending: false };
        }
    }
}

/**
 * Handle follow request (accept/reject)
 */
async function handleFollowRequest(userId, requestFromUserId, action) {
    if (!["accept", "reject"].includes(action)) {
        const err = new Error('Action doit être "accept" ou "reject"');
        err.statusCode = 400;
        throw err;
    }

    const user = await User.findById(userId);
    if (!user) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    const request = user.followRequests.find(
        (req) => req.from.toString() === requestFromUserId.toString()
    );

    if (!request) {
        const err = new Error("Demande de suivi non trouvée");
        err.statusCode = 404;
        throw err;
    }

    if (action === "accept") {
        request.status = "accepted";
        const requester = await User.findById(requestFromUserId);
        if (requester) {
            requester.following.push(userId);
            user.followers.push(requestFromUserId);
            await requester.save();
            await user.save();
        }
    } else if (action === "reject") {
        request.status = "rejected";
        await user.save();
    }

    return { success: true, status: request.status };
}

/**
 * Update profile privacy setting
 */
async function updateProfilePrivacy(userId, privacy) {
    if (!["public", "private"].includes(privacy)) {
        const err = new Error('Privacy doit être "public" ou "private"');
        err.statusCode = 400;
        throw err;
    }

    const user = await User.findById(userId);
    if (!user) {
        const err = new Error("Utilisateur non trouvé");
        err.statusCode = 404;
        throw err;
    }

    user.profilePrivacy = privacy;
    await user.save();

    return user.toPublic();
}

module.exports = {
    updateProfile,
    updateAvatar,
    deleteAvatar,
    toggleFollow,
    handleFollowRequest,
    updateProfilePrivacy,
};
