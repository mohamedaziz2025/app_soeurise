import 'package:flutter/material.dart';
import '../constants.dart';
import '../theme/glass_widgets.dart';
import '../models/models.dart';
import '../services/community_service.dart';
import '../widgets/responsive.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Community> communities = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _joiningIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadCommunities();
    _loadMemberships();
  }
  Future<void> _loadMemberships() async {
    try {
      await CommunityService.instance.loadMemberships();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetched = await CommunityService.instance.fetchGroups(
        search: search,
        limit: 50,
      );
      if (mounted) {
        setState(() {
          communities = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des groupes';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleJoin(Community c) async {
    if (_joiningIds.contains(c.id)) return;
    setState(() => _joiningIds.add(c.id));
    final result = await CommunityService.instance.joinGroup(c.id);
    if (!mounted) return;
    setState(() => _joiningIds.remove(c.id));
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isNotEmpty
                ? result.message
                : 'Demande envoyée à ${c.name}!',
          ),
          backgroundColor: AppColors.successColor,
        ),
      );
      setState(() {}); // Trigger rebuild to show joined status

      if (result.isActive) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupChatScreen(
              communityId: c.id,
              communityName: c.name,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message.isNotEmpty
              ? result.message
              : 'Impossible de rejoindre cette communauté'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _openCreateGroup() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
    if (created == true) {
      await _loadCommunities();
    }
  }

  String _extractInviteToken(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return trimmed;
  }

  Future<void> _showJoinByLinkSheet() async {
    final controller = TextEditingController();
    bool isJoining = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rejoindre via lien',
                      style: AppTextStyles.headline3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Collez un lien ou un code d\'invitation pour rejoindre une communaute.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Lien ou code d\'invitation',
                        hintStyle: AppTextStyles.bodySmall,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                          borderSide: BorderSide(
                            color: AppColors.primary.withAlpha(80),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: isJoining
                            ? null
                            : () async {
                                final token = _extractInviteToken(controller.text);
                                if (token.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Veuillez entrer un lien ou un code valide'),
                                      backgroundColor: AppColors.errorColor,
                                    ),
                                  );
                                  return;
                                }
                                setModalState(() => isJoining = true);
                                final success =
                                    await CommunityService.instance.joinByInvite(token);
                                setModalState(() => isJoining = false);
                                if (!context.mounted) return;
                                if (success) {
                                  Navigator.pop(context);
                                  if (mounted) {
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Vous avez rejoint la communaute'),
                                        backgroundColor: AppColors.successColor,
                                      ),
                                    );
                                    _loadCommunities();
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Lien d\'invitation invalide'),
                                      backgroundColor: AppColors.errorColor,
                                    ),
                                  );
                                }
                              },
                        icon: isJoining
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.link_rounded, size: 18),
                        label: Text(
                          isJoining ? 'En cours...' : 'Rejoindre',
                          style: AppTextStyles.button.copyWith(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sidePadding = Responsive.sidePadding(context, maxWidth: 720);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateGroup,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(sidePadding, 16, sidePadding, 0),
                child: FadeSlideIn(
                  child: Text(
                    'Communautés',
                    style: AppTextStyles.headline1,
                  ),
                ),
              ),
            ),

            // Search
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(sidePadding, 16, sidePadding, 16),
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (value) => _loadCommunities(search: value),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textLight, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _loadCommunities();
                          },
                        ),
                        hintText: 'Rechercher des communautés',
                        hintStyle: AppTextStyles.bodyMedium,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: OutlinedButton.icon(
                    onPressed: _showJoinByLinkSheet,
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: Text(
                      'Rejoindre via lien',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withAlpha(90)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              )
            else if (communities.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Aucune communauté trouvée',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                  ),
                ),
              )
            else ...[
              // Featured communities
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: sidePadding),
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: Text(
                          'En vedette ✨',
                          style: AppTextStyles.headline3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: sidePadding),
                        scrollDirection: Axis.horizontal,
                        itemCount: communities.length > 5 ? 5 : communities.length,
                        itemBuilder: (context, index) {
                          final c = communities[index];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 200 + (index * 50)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: _buildFeaturedCard(c),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // All communities header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(sidePadding, 24, sidePadding, 12),
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      'Toutes les communautés',
                      style: AppTextStyles.headline3,
                    ),
                  ),
                ),
              ),

              // Vertial List
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final c = communities[index];
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 350 + (index * 50)),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCommunityListItem(context, c),
                        ),
                      );
                    },
                    childCount: communities.length,
                  ),
                ),
              ),
            ],
            
            // Bottom padding for nav bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(Community c) {
    return ValueListenableBuilder<Map<String, String>>(
      valueListenable: CommunityService.instance.membershipStatus,
      builder: (context, statusMap, child) {
        final status = statusMap[c.id] ?? 'none';
        final isMember = status == 'active';
        final isPending = status == 'pending';
        final isJoining = _joiningIds.contains(c.id);

        return Container(
          width: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryLight.withAlpha(200),
                AppColors.primary.withAlpha(220),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(50),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background abstract shapes
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(30),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            c.name,
                            style: AppTextStyles.headline4.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(80),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.people_outline_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${c.members}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: isJoining || isPending
                          ? null
                          : () {
                              if (isMember) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GroupChatScreen(
                                      communityId: c.id,
                                      communityName: c.name,
                                    ),
                                  ),
                                );
                              } else {
                                _handleJoin(c);
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          isJoining
                              ? 'En cours...'
                              : (isMember
                                  ? 'Ouvrir'
                                  : isPending
                                      ? 'En attente'
                                      : 'Rejoindre'),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommunityListItem(BuildContext context, Community c) {
    return ValueListenableBuilder<Map<String, String>>(
      valueListenable: CommunityService.instance.membershipStatus,
      builder: (context, statusMap, child) {
        final status = statusMap[c.id] ?? 'none';
        final isMember = status == 'active';
        final isPending = status == 'pending';
        final isJoining = _joiningIds.contains(c.id);

        return GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _buildCommunityIcon(c),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: AppTextStyles.headline4.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
                  isMember
                  ? OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GroupChatScreen(
                                communityId: c.id,
                                communityName: c.name,
                              ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'Accéder',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                      : OutlinedButton(
                        onPressed: isJoining || isPending
                          ? null
                          : () => _handleJoin(c),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withAlpha(100),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: isJoining
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : Text(
                              isPending ? 'En attente' : 'Rejoindre',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
            ],
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'S';
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase())
        .join();
    if (initials.isEmpty) return 'S';
    if (initials.length > 2) return initials.substring(0, 2);
    return initials;
  }

  Widget _buildInitialsFallback(String initials) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityIcon(Community c) {
    const double size = 48;
    final initials = _getInitials(c.name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(30),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: c.imageUrl.isNotEmpty
            ? Image.network(
                c.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildInitialsFallback(initials),
              )
            : _buildInitialsFallback(initials),
      ),
    );
  }
}
