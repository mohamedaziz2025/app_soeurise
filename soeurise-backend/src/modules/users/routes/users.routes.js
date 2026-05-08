const router = require("express").Router();
const { requireAuth } = require("../../../middlewares/auth");
const { uploadAvatar } = require("../../../middlewares/uploadAvatar");
const usersController = require("../controllers/users.controller");

// Toutes les routes nécessitent auth
router.use(requireAuth);

// GET /api/users/me — profil connecté
router.get("/me", usersController.getMe);

// PUT /api/users/me — modifier profil (firstName, lastName, username, email)
router.put("/me", usersController.updateMe);

// PUT /api/users/me/avatar — upload/remplacer avatar
router.put("/me/avatar", uploadAvatar.single("avatar"), usersController.updateAvatar);

// DELETE /api/users/me/avatar — supprimer avatar
router.delete("/me/avatar", usersController.deleteAvatar);

// PUT /api/users/me/privacy — update privacy setting (public|private)
router.put("/me/privacy", usersController.updateProfilePrivacy);

// GET /api/users/me/follow-requests — list pending follow requests
router.get("/me/follow-requests", usersController.getFollowRequests);

// POST /api/users/me/follow-requests/:requesterId/accept — accept follow request
router.post("/me/follow-requests/:requesterId/accept", usersController.acceptFollowRequest);

// POST /api/users/me/follow-requests/:requesterId/reject — reject follow request
router.post("/me/follow-requests/:requesterId/reject", usersController.rejectFollowRequest);

// POST /api/users/:id/follow — toggle follow/unfollow a user
router.post("/:id/follow", usersController.toggleFollow);

module.exports = router;
