const communityService = require("../services/community.service");
const {
    createGroupSchema,
    listPublicSchema,
    groupIdSchema,
    handleRequestSchema,
    addMemberSchema,
    updateMemberSchema,
    memberIdSchema,
    createInviteSchema,
    inviteTokenSchema,
    searchUsersSchema,
} = require("../validators/community.validators");

// ──────────────────────────────────────────
//  Phase 3-4: handlers existants
// ──────────────────────────────────────────

async function createGroup(req, res, next) {
    try {
        const { error, value } = createGroupSchema.validate(req.body, {
            abortEarly: false,
            stripUnknown: true,
        });
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Données invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const group = await communityService.createGroup(
            req.user._id,
            value,
            req.file || null
        );

        res.status(201).json({
            success: true,
            message: "Groupe créé avec succès",
            data: { group },
        });
    } catch (err) {
        next(err);
    }
}

async function listPublicGroups(req, res, next) {
    try {
        const { error, value } = listPublicSchema.validate(req.query);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Paramètres invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const data = await communityService.listPublicGroups(
            value.page,
            value.limit,
            value.search
        );

        res.json({ success: true, data });
    } catch (err) {
        next(err);
    }
}

async function getGroup(req, res, next) {
    try {
        const { error } = groupIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const result = await communityService.canViewGroup(
            req.params.id,
            req.user ? req.user._id : null
        );

        if (!result.canView) {
            return res.status(403).json({
                success: false,
                message: "Accès non autorisé à ce groupe",
            });
        }

        const subResult = await communityService.isSubscribed(
            req.params.id,
            req.user ? req.user._id : null
        );

        res.json({
            success: true,
            data: {
                group: result.group,
                isSubscribed: subResult.subscribed,
                subscription: subResult.subscription,
            },
        });
    } catch (err) {
        next(err);
    }
}

async function joinGroup(req, res, next) {
    try {
        const { error } = groupIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const result = await communityService.joinGroup(
            req.params.id,
            req.user._id
        );

        const statusCode = result.alreadyMember ? 200 : 201;
        res.status(statusCode).json({
            success: true,
            message: result.message,
            data: {
                membership: result.membership,
                status: result.status,
                alreadyMember: result.alreadyMember,
            },
        });
    } catch (err) {
        next(err);
    }
}

async function getMyMembership(req, res, next) {
    try {
        const { error } = groupIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const result = await communityService.getMembership(
            req.params.id,
            req.user._id
        );

        res.json({
            success: true,
            data: {
                status: result.status,
                roleInGroup: result.roleInGroup,
                isMuted: result.isMuted,
                membership: result.membership,
            },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/community/groups/memberships/me
 */
async function listMyMemberships(req, res, next) {
    try {
        const memberships = await communityService.listMyMemberships(req.user._id);
        res.json({ success: true, data: { memberships } });
    } catch (err) {
        next(err);
    }
}

async function getMySubscription(req, res, next) {
    try {
        const { error } = groupIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const result = await communityService.getSubscription(
            req.params.id,
            req.user._id
        );

        res.json({
            success: true,
            data: {
                isSubscribed: result.isSubscribed,
                plan: result.plan,
                status: result.status,
                subscription: result.subscription,
            },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/community/groups/:id/leave
 */
async function leaveGroup(req, res, next) {
    try {
        const { error } = groupIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const result = await communityService.leaveGroup(
            req.params.id,
            req.user._id
        );

        res.json({ success: true, message: result.message });
    } catch (err) {
        next(err);
    }
}

// ──────────────────────────────────────────
//  Phase 5: gestion membres & demandes
// ──────────────────────────────────────────

/**
 * GET /api/community/groups/:id/requests
 */
async function listRequests(req, res, next) {
    try {
        const requests = await communityService.listPendingRequests(req.params.id);
        res.json({ success: true, data: { requests } });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/community/groups/:id/members
 */
async function listMembers(req, res, next) {
    try {
        const { error } = groupIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const members = await communityService.listMembers(req.params.id);
        res.json({ success: true, data: { members } });
    } catch (err) {
        next(err);
    }
}

/**
 * PATCH /api/community/groups/:id/requests/:memberId
 */
async function handleRequest(req, res, next) {
    try {
        const { error: pError } = memberIdSchema.validate(req.params);
        if (pError) {
            return res.status(400).json({
                success: false,
                message: "Paramètres invalides",
            });
        }

        const { error, value } = handleRequestSchema.validate(req.body, {
            stripUnknown: true,
        });
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Données invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const result = await communityService.handleRequest(
            req.params.id,
            req.params.memberId,
            value.action
        );

        res.json({
            success: true,
            message: result.message,
            data: { membership: result.membership },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/community/groups/:id/members
 */
async function addMember(req, res, next) {
    try {
        const { error, value } = addMemberSchema.validate(req.body, {
            stripUnknown: true,
        });
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Données invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const member = await communityService.addMember(
            req.params.id,
            value.userId,
            value.roleInGroup
        );

        res.status(201).json({
            success: true,
            message: "Membre ajouté avec succès",
            data: { member },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * PATCH /api/community/groups/:id/members/:memberId
 */
async function updateMember(req, res, next) {
    try {
        const { error: pError } = memberIdSchema.validate(req.params);
        if (pError) {
            return res.status(400).json({
                success: false,
                message: "Paramètres invalides",
            });
        }

        const { error, value } = updateMemberSchema.validate(req.body, {
            stripUnknown: true,
        });
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Données invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const member = await communityService.updateMember(
            req.params.id,
            req.params.memberId,
            value
        );

        res.json({
            success: true,
            message: "Membre mis à jour",
            data: { member },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * DELETE /api/community/groups/:id/members/:memberId
 */
async function removeMember(req, res, next) {
    try {
        const { error } = memberIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Paramètres invalides",
            });
        }

        const result = await communityService.removeMember(
            req.params.id,
            req.params.memberId
        );

        res.json({
            success: true,
            message: result.message,
        });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/community/groups/:id/messages
 */
async function listMessages(req, res, next) {
    try {
        const { error } = groupIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const limit = Math.min(parseInt(req.query.limit, 10) || 30, 100);
        const before = req.query.before ? new Date(req.query.before) : null;

        const messages = await communityService.listMessages(
            req.params.id,
            req.user._id,
            limit,
            before
        );

        res.json({ success: true, data: { messages } });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/community/groups/:id/messages
 */
async function sendMessage(req, res, next) {
    try {
        const { error } = groupIdSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const message = await communityService.createMessage(
            req.params.id,
            req.user._id,
            req.body.text,
            req.file || null
        );

        res.status(201).json({
            success: true,
            message: "Message envoye",
            data: { message },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * GET /api/community/users/search
 */
async function searchUsers(req, res, next) {
    try {
        const { error, value } = searchUsersSchema.validate(req.query, {
            stripUnknown: true,
        });
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Paramètres invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const users = await communityService.searchUsers(
            value.search,
            value.limit,
            req.user._id
        );

        res.json({ success: true, data: { users } });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/community/groups/:id/invites
 */
async function createInvite(req, res, next) {
    try {
        const { error: pError } = groupIdSchema.validate(req.params);
        if (pError) {
            return res.status(400).json({
                success: false,
                message: "ID de groupe invalide",
            });
        }

        const { error, value } = createInviteSchema.validate(req.body || {}, {
            stripUnknown: true,
        });
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Données invalides",
                errors: error.details.map((d) => d.message),
            });
        }

        const result = await communityService.createInvite(
            req.params.id,
            req.user._id,
            value
        );

        res.status(201).json({
            success: true,
            message: "Lien d'invitation créé",
            data: {
                invite: result.invite,
                group: result.group,
            },
        });
    } catch (err) {
        next(err);
    }
}

/**
 * POST /api/community/invites/:token/join
 */
async function joinByInvite(req, res, next) {
    try {
        const { error } = inviteTokenSchema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: "Token d'invitation invalide",
            });
        }

        const result = await communityService.joinByInvite(
            req.params.token,
            req.user._id
        );

        const statusCode = result.alreadyMember ? 200 : 201;
        res.status(statusCode).json({
            success: true,
            message: result.alreadyMember
                ? "Vous êtes déjà membre de ce groupe"
                : "Vous avez rejoint le groupe",
            data: {
                membership: result.membership,
                group: result.group,
                invite: result.invite,
                alreadyMember: result.alreadyMember,
            },
        });
    } catch (err) {
        next(err);
    }
}

module.exports = {
    createGroup,
    listPublicGroups,
    getGroup,
    joinGroup,
    getMyMembership,
    listMyMemberships,
    getMySubscription,
    leaveGroup,
    // Phase 5
    listRequests,
    listMembers,
    handleRequest,
    addMember,
    updateMember,
    removeMember,
    listMessages,
    sendMessage,
    searchUsers,
    createInvite,
    joinByInvite,
};
