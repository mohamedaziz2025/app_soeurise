import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../constants.dart';
import '../theme/glass_widgets.dart';
import '../models/models.dart';
import '../widgets/user_avatar.dart';
import '../services/post_service.dart';
import '../services/profile_service.dart';
import '../widgets/responsive.dart';

class PostCreationScreen extends StatefulWidget {
  final ValueChanged<Post>? onPostCreated;
  final ValueChanged<Post>? onPostUpdated;
  final Post? postToEdit;

  const PostCreationScreen({
    super.key,
    this.onPostCreated,
    this.onPostUpdated,
    this.postToEdit,
  });

  @override
  State<PostCreationScreen> createState() => _PostCreationScreenState();
}

class _PostCreationScreenState extends State<PostCreationScreen> {
  final textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  bool _isPublishing = false;
  String? _existingImageUrl;

  bool get _isEditing => widget.postToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      textController.text = widget.postToEdit!.content;
      _existingImageUrl = widget.postToEdit!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (!mounted) return;
      if (pickedFile != null) {
        setState(() => selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _submitPost() async {
    final content = textController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer du texte')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    Post? resultPost;
    if (_isEditing) {
      resultPost = await PostService.instance.updatePost(
        postId: widget.postToEdit!.id,
        content: content,
        imageFile: selectedImage,
      );
    } else {
      resultPost = await PostService.instance.createPost(
        content: content,
        imageFile: selectedImage,
      );
    }

    if (mounted) {
      setState(() => _isPublishing = false);
      if (resultPost != null) {
        if (_isEditing) {
          widget.onPostUpdated?.call(resultPost);
          Navigator.pop(context, resultPost);
        } else {
          widget.onPostCreated?.call(resultPost);
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Erreur lors de la modification du post'
                : 'Erreur lors de la création du post'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sidePadding = Responsive.sidePadding(context, maxWidth: 720);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: sidePadding,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(180),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.accentGradient.createShader(bounds),
                      child: Text(
                        _isEditing
                            ? 'Modifier la publication'
                            : 'Nouvelle publication',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GlassButton(
                      label: _isEditing ? 'Enregistrer' : 'Publier',
                      isLoading: _isPublishing,
                      width: 100,
                      onPressed: _submitPost,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: sidePadding,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      // User info
                      FadeSlideIn(
                        child: ValueListenableBuilder<Profile>(
                          valueListenable: ProfileService.instance.profile,
                          builder: (context, profile, _) {
                            return Row(
                              children: [
                                UserAvatar(
                                  imageUrl: profile.profileImageUrl.isNotEmpty
                                      ? profile.profileImageUrl
                                      : null,
                                  username: profile.fullName,
                                  radius: 24,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.fullName,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '@${profile.username}',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Text field
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: GlassCard(
                          padding: const EdgeInsets.all(4),
                          child: TextField(
                            controller: textController,
                            maxLines: 8,
                            style: AppTextStyles.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'Qu\'avez-vous en tête ? ✨',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textLight,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ),

                      // Selected image
                      if (selectedImage != null) ...[
                        const SizedBox(height: 16),
                        FadeSlideIn(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    AppBorderRadius.lg),
                                child: Image.file(
                                  selectedImage!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => selectedImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(120),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_existingImageUrl != null &&
                          _existingImageUrl!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        FadeSlideIn(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                AppBorderRadius.lg),
                            child: Image.network(
                              _existingImageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(200),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.beigeDark.withAlpha(40),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      _actionButton(
                        Icons.image_rounded,
                        'Photo',
                        _pickImage,
                      ),
                      const SizedBox(width: 12),
                      _actionButton(
                        Icons.emoji_emotions_outlined,
                        'Emoji',
                        () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(AppBorderRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
