const express = require("express");
const router = express.Router();

const { requireAuth } = require("../../../middlewares/auth");
const { uploadPostImage } = require("../../../middlewares/uploadPostImage");
const postsController = require("../controllers/posts.controller");

// Toutes les routes posts nécessitent d'être connecté
router.use(requireAuth);

// GET /api/posts - Récupérer le fil d'actualité global ou par communauté
router.get("/", postsController.getFeed);

// GET /api/posts/subscriptions - Fil d'actualité des abonnements
router.get("/subscriptions", postsController.getSubscriptionFeed);

// POST /api/posts - Créer un nouveau post
router.post("/", uploadPostImage.single("image"), postsController.createPost);

// PUT /api/posts/:id - Modifier un post
router.put("/:id", uploadPostImage.single("image"), postsController.updatePost);

// POST /api/posts/:id/like - Liker/Unliker un post
router.post("/:id/like", postsController.toggleLike);

// POST /api/posts/:id/share - Partager un post
router.post("/:id/share", postsController.sharePost);

// POST /api/posts/:id/repost - Republier un post
router.post("/:id/repost", postsController.repostPost);

// GET /api/posts/:id/comments - Récupérer les commentaires d'un post
router.get("/:id/comments", postsController.getComments);

// POST /api/posts/:id/comments - Ajouter un commentaire
router.post("/:id/comments", postsController.addComment);

// DELETE /api/posts/:id/comments/:commentId - Supprimer un commentaire
router.delete("/:id/comments/:commentId", postsController.deleteComment);

// PATCH /api/posts/:id/comments/:commentId/hide - Masquer/afficher un commentaire
router.patch("/:id/comments/:commentId/hide", postsController.toggleHideComment);

// POST /api/posts/:id/comments/:commentId/like - Liker un commentaire
router.post("/:id/comments/:commentId/like", postsController.likeComment);

// POST /api/posts/:id/comments/:commentId/reply - Répondre à un commentaire
router.post("/:id/comments/:commentId/reply", postsController.replyToComment);

// DELETE /api/posts/:id/comments/:commentId/replies/:replyId - Supprimer une réponse
router.delete("/:id/comments/:commentId/replies/:replyId", postsController.deleteReply);

// PATCH /api/posts/:id/comments/:commentId/replies/:replyId/hide - Masquer/afficher une réponse
router.patch("/:id/comments/:commentId/replies/:replyId/hide", postsController.toggleHideReply);

// POST /api/posts/:id/comments/:commentId/replies/:replyId/like - Liker une réponse
router.post("/:id/comments/:commentId/replies/:replyId/like", postsController.likeReply);

module.exports = router;
