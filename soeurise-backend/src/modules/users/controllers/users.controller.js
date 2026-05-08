const usersService = require("../services/users.service");
const { updateProfileSchema } = require("../validators/users.validators");

/**
 * GET /api/users/me
 */
async function getMe(req, res, next) {
    try {
        res.json({ success: true, data: { user: req.user.toPublic() } });
    } catch (err) {
        next(err);
    }
}

/**
 * PUT /api/users/me
 */
async function updateMe(req, res, next) {
    try {
        const { error, value } = updateProfileSchema.validate(req.body, {
            abortEarly: false,
            stripUnknown: true, // supprime role, isActive, etc.
        });
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Données invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const user = await usersService.updateProfile(req.user._id, value);
        res.json({
            success: true,
            message: "Profil mis à jour",
            data: { user },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * PUT /api/users/me/avatar
 */
async function updateAvatar(req, res, next) {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: "Aucun fichier avatar envoyé",
            });
        }

        const user = await usersService.updateAvatar(req.user._id, req.file);
        res.json({
            success: true,
            message: "Avatar mis à jour",
            data: { user },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * DELETE /api/users/me/avatar
 */
async function deleteAvatar(req, res, next) {
    try {
        const user = await usersService.deleteAvatar(req.user._id);
        res.json({
            success: true,
            message: "Avatar supprimé",
            data: { user },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/users/:id/follow
 */
async function toggleFollow(req, res, next) {
    try {
        const result = await usersService.toggleFollow(req.user._id, req.params.id);
        res.json({
            success: true,
            message: result.isPending ? "Demande de suivi envoyée" : (result.isFollowing ? "Abonné" : "Désabonné"),
            data: result,
        });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/users/me/follow-requests
 */
async function getFollowRequests(req, res, next) {
    try {
        const user = req.user;
        const requests = (user.followRequests || []).filter((r) => r.status === "pending");
        res.json({ success: true, data: { requests } });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/users/me/follow-requests/:requesterId/accept
 */
async function acceptFollowRequest(req, res, next) {
    try {
        const result = await usersService.handleFollowRequest(req.user._id, req.params.requesterId, "accept");
        res.json({ success: true, message: "Demande acceptée", data: result });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/users/me/follow-requests/:requesterId/reject
 */
async function rejectFollowRequest(req, res, next) {
    try {
        const result = await usersService.handleFollowRequest(req.user._id, req.params.requesterId, "reject");
        res.json({ success: true, message: "Demande rejetée", data: result });
    } catch (err) {
        next(err);
    }
}

/**
 * PUT /api/users/me/privacy
 */
async function updateProfilePrivacy(req, res, next) {
    try {
        const { privacy } = req.body;
        if (!privacy) {
            return res.status(400).json({
                success: false,
                message: "Le paramètre 'privacy' est requis (public|private)",
            });
        }

        const user = await usersService.updateProfilePrivacy(req.user._id, privacy);
        res.json({
            success: true,
            message: `Profil défini comme ${privacy === "private" ? "privé" : "public"}`,
            data: { user },
        });
    } catch (err) {
        next(err);
    }
}

module.exports = {
    getMe,
    updateMe,
    updateAvatar,
    deleteAvatar,
    toggleFollow,
    getFollowRequests,
    acceptFollowRequest,
    rejectFollowRequest,
    updateProfilePrivacy,
};
