import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/community_service.dart';
import '../services/profile_service.dart';
import '../theme/glass_widgets.dart';
import '../widgets/responsive.dart';

class GroupMembersScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isAdmin;

  const GroupMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.isAdmin,
  });

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  late Future<List<Map<String, dynamic>>> _membersFuture;
  final _communityService = CommunityService.instance;
  final _profileService = ProfileService.instance;

  @override
  void initState() {
    super.initState();
    _membersFuture = _communityService.listMembers(widget.groupId);
  }

  Future<void> _toggleMute(String memberId, bool currentMuted) async {
    final success = await _communityService.updateMember(
      groupId: widget.groupId,
      memberId: memberId,
      isMuted: !currentMuted,
    );
    if (success) {
      setState(() {
        _membersFuture = _communityService.listMembers(widget.groupId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !currentMuted ? 'Membre rendu muet' : 'Membre rappelé',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(String memberId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer le membre'),
        content: const Text('Êtes-vous sûr de vouloir retirer ce membre ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Retirer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _communityService.updateMember(
        groupId: widget.groupId,
        memberId: memberId,
        status: 'removed',
      );
      if (success) {
        setState(() {
          _membersFuture = _communityService.listMembers(widget.groupId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Membre retiré'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Membres - ${widget.groupName}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur lors du chargement des membres',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }

          final members = snapshot.data ?? [];
          if (members.isEmpty) {
            return Center(
              child: Text(
                'Aucun membre',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final memberId = member['_id'] as String? ?? '';
              final username = member['username'] as String? ?? 'Utilisateur';
              final firstName = member['firstName'] as String? ?? '';
              final lastName = member['lastName'] as String? ?? '';
              final role = member['roleInGroup'] as String? ?? 'member';
              final isMuted = member['isMuted'] as bool? ?? false;
              final avatar = member['avatar'] as String? ?? '';
              final currentUserId = _profileService.profile.value.id;
              final isCurrentUser = memberId == currentUserId;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withAlpha(20),
                    backgroundImage: avatar.isNotEmpty
                        ? NetworkImage(avatar)
                        : null,
                    child: avatar.isEmpty
                        ? Text(
                            username[0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    firstName.isNotEmpty || lastName.isNotEmpty
                        ? '$firstName $lastName'.trim()
                        : username,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@$username',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: [
                          Chip(
                            label: Text(
                              role == 'admin' ? 'Admin' : 'Membre',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: role == 'admin'
                                ? Colors.red
                                : AppColors.primary,
                            padding: EdgeInsets.zero,
                          ),
                          if (isMuted)
                            const Chip(
                              label: Text(
                                'Muet',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.zero,
                            ),
                          if (isCurrentUser)
                            const Chip(
                              label: Text(
                                'Vous',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: !widget.isAdmin || isCurrentUser
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'mute') {
                              _toggleMute(memberId, isMuted);
                            } else if (value == 'remove') {
                              _removeMember(memberId);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<String>(
                              value: 'mute',
                              child: Text(
                                isMuted
                                    ? 'Rappeler ce membre'
                                    : 'Rendre ce membre muet',
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'remove',
                              child: Text(
                                'Retirer ce membre',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
