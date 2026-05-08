const GroupMember = require("../modules/community/models/GroupMember");

/**
 * Middleware: requireGroupMember
 * Vérifie que l'utilisateur est membre actif du groupe.
 * L'admin global (req.user.role === "admin") a tous les droits.
 * Le groupId est lu depuis req.params.id
 */
function requireGroupMember() {
    return async (req, res, next) => {
        try {
            if (req.user.role === "admin") {
                return next();
            }

            const groupId = req.params.id;
            if (!groupId) {
                return res.status(400).json({
                    success: false,
                    message: "ID de groupe manquant",
                });
            }

            const member = await GroupMember.findOne({
                groupId,
                userId: req.user._id,
                status: "active",
            });

            if (!member) {
                return res.status(403).json({
                    success: false,
                    message: "Vous n'êtes pas membre actif de ce groupe",
                });
            }

            req.groupMember = member;
            next();
        } catch (err) {
            return res.status(500).json({
                success: false,
                message: "Erreur de vérification des permissions",
            });
        }
    };
}

module.exports = { requireGroupMember };
