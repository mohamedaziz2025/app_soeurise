import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_client.dart';

class ChatMessage {
  final String sender;
  final String text;
  final DateTime timestamp;

  ChatMessage({required this.sender, required this.text, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class JoinGroupResult {
  final bool success;
  final String status;
  final String message;
  final bool alreadyMember;

  const JoinGroupResult({
    required this.success,
    required this.status,
    required this.message,
    required this.alreadyMember,
  });

  bool get isActive => status == 'active';
}

class CommunityService {
  CommunityService._private();
  static final CommunityService instance = CommunityService._private();

  final _api = ApiClient.instance;
  final ValueNotifier<Set<String>> joined = ValueNotifier(<String>{});
  final ValueNotifier<Map<String, String>> membershipStatus =
      ValueNotifier(<String, String>{});
  final Map<String, ValueNotifier<List<ChatMessage>>> _messages = {};

  bool isMember(String communityId) => joined.value.contains(communityId);

  // ─── Backend API calls ───

  /// Fetch public groups from the backend.
  Future<List<Community>> fetchGroups({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      var path = '/community/groups/public?page=$page&limit=$limit';
      if (search != null && search.isNotEmpty) {
        path += '&search=${Uri.encodeComponent(search)}';
      }
      final res = await _api.get(path);
      if (res.success && res.data != null) {
        final groups = res.data!['groups'] as List? ?? [];
        return groups
            .map((g) => Community.fromJson(g as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Create a group via the backend.
  Future<Community?> createGroup({
    required String name,
    String description = '',
    bool isPublic = true,
    bool requiresSubscription = false,
  }) async {
    try {
      final res = await _api.post('/community/groups', {
        'name': name,
        'description': description,
        'isPublic': isPublic,
        'requiresSubscription': requiresSubscription,
      });
      if (res.success && res.data != null) {
        final group = res.data!['group'] as Map<String, dynamic>?;
        if (group != null) {
          return Community.fromJson(group);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Search users to add into a group.
  Future<List<User>> searchUsers({
    required String query,
    int limit = 10,
  }) async {
    try {
      final path =
          '/community/users/search?search=${Uri.encodeComponent(query)}&limit=$limit';
      final res = await _api.get(path);
      if (res.success && res.data != null) {
        final users = res.data!['users'] as List? ?? [];
        return users
            .map((u) => User.fromJson(u as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Add a member to a group (owner/moderator only).
  Future<bool> addMember({
    required String groupId,
    required String userId,
    String roleInGroup = 'member',
  }) async {
    try {
      final res = await _api.post('/community/groups/$groupId/members', {
        'userId': userId,
        'roleInGroup': roleInGroup,
      });
      return res.success;
    } catch (_) {
      return false;
    }
  }

  /// Create an invite link for a group.
  Future<Map<String, dynamic>?> createInvite({
    required String groupId,
    int? expiresInDays,
    int? maxUses,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (expiresInDays != null) body['expiresInDays'] = expiresInDays;
      if (maxUses != null) body['maxUses'] = maxUses;
      final res = await _api.post('/community/groups/$groupId/invites', body);
      if (res.success && res.data != null) {
        return res.data!['invite'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Join a group using an invite token.
  Future<bool> joinByInvite(String token) async {
    try {
      final res = await _api.post('/community/invites/$token/join', {});
      if (res.success && res.data != null) {
        final membership = res.data!['membership'] as Map<String, dynamic>?;
        final groupId = membership?['groupId']?.toString();
        if (groupId != null && groupId.isNotEmpty) {
          final s = Set<String>.from(joined.value);
          s.add(groupId);
          joined.value = s;
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Join a group via the backend.
  Future<JoinGroupResult> joinGroup(String groupId) async {
    try {
      final res = await _api.post('/community/groups/$groupId/join', {});
      if (res.success) {
        final membership = res.data?['membership'] as Map<String, dynamic>?;
        final status = membership?['status']?.toString() ?? 'none';
        final alreadyMember = res.data?['alreadyMember'] == true;

        if (status == 'active') {
          final s = Set<String>.from(joined.value);
          s.add(groupId);
          joined.value = s;
          _messages.putIfAbsent(
            groupId,
            () => ValueNotifier<List<ChatMessage>>([]),
          );
        }

        final statuses = Map<String, String>.from(membershipStatus.value);
        statuses[groupId] = status;
        membershipStatus.value = statuses;

        return JoinGroupResult(
          success: true,
          status: status,
          message: res.message ?? '',
          alreadyMember: alreadyMember,
        );
      }
      return JoinGroupResult(
        success: false,
        status: 'none',
        message: res.errorMessage,
        alreadyMember: false,
      );
    } catch (_) {
      return const JoinGroupResult(
        success: false,
        status: 'none',
        message: 'Impossible de rejoindre cette communauté',
        alreadyMember: false,
      );
    }
  }

  /// Check membership status for the current user.
  Future<String> getMembershipStatus(String groupId) async {
    try {
      final res = await _api.get('/community/groups/$groupId/membership/me');
      if (res.success && res.data != null) {
        final status = res.data!['status'] as String? ?? 'none';
        if (status == 'active') {
          final s = Set<String>.from(joined.value);
          s.add(groupId);
          joined.value = s;
        }
        final statuses = Map<String, String>.from(membershipStatus.value);
        statuses[groupId] = status;
        membershipStatus.value = statuses;
        return status;
      }
      return 'none';
    } catch (_) {
      return 'none';
    }
  }

  /// Load all memberships for current user.
  Future<void> loadMemberships() async {
    try {
      final res = await _api.get('/community/groups/memberships/me');
      if (res.success && res.data != null) {
        final list = res.data!['memberships'] as List? ?? [];
        final statuses = <String, String>{};
        final active = <String>{};
        for (final m in list) {
          final groupId = m['groupId']?.toString() ?? '';
          final status = m['status']?.toString() ?? 'none';
          if (groupId.isEmpty) continue;
          statuses[groupId] = status;
          if (status == 'active') active.add(groupId);
        }
        membershipStatus.value = statuses;
        joined.value = active;
      }
    } catch (_) {}
  }

  // ─── Local chat (no backend endpoint yet) ───

  void joinCommunity(String communityId) {
    final s = Set<String>.from(joined.value);
    s.add(communityId);
    joined.value = s;
    _messages.putIfAbsent(
      communityId,
      () => ValueNotifier<List<ChatMessage>>([]),
    );
  }

  ValueNotifier<List<ChatMessage>> messagesFor(String communityId) {
    return _messages.putIfAbsent(
      communityId,
      () => ValueNotifier<List<ChatMessage>>([]),
    );
  }

  void addMessage(String communityId, ChatMessage message) {
    final notifier = messagesFor(communityId);
    final updated = List<ChatMessage>.from(notifier.value)..add(message);
    notifier.value = updated;
  }

  /// Fetch group messages from the backend.
  Future<List<Map<String, dynamic>>> fetchMessages(String groupId,
      {int limit = 30}) async {
    try {
      final res = await _api.get('/community/groups/$groupId/messages?limit=$limit');
      if (res.success && res.data != null) {
        final list = res.data!['messages'] as List? ?? [];
        return list.map((m) => m as Map<String, dynamic>).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Send a group message (text + optional image).
  Future<Map<String, dynamic>?> sendMessage({
    required String groupId,
    String text = '',
    String? imagePath,
  }) async {
    try {
      if ((text.trim().isEmpty) && imagePath == null) return null;
      final fields = <String, String>{};
      if (text.trim().isNotEmpty) fields['text'] = text.trim();

      final res = await _api.multipartRequest(
        'POST',
        '/community/groups/$groupId/messages',
        fields: fields,
        fileField: imagePath != null ? 'image' : null,
        filePath: imagePath,
      );

      if (res.success && res.data != null) {
        return res.data!['message'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Leave a group.
  Future<bool> leaveGroup(String groupId) async {
    try {
      final res = await _api.post('/community/groups/$groupId/leave', {});
      if (res.success) {
        final s = Set<String>.from(joined.value);
        s.remove(groupId);
        joined.value = s;
        final statuses = Map<String, String>.from(membershipStatus.value);
        statuses[groupId] = 'none';
        membershipStatus.value = statuses;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// List members (admin/moderator only).
  Future<List<Map<String, dynamic>>> listMembers(String groupId) async {
    try {
      final res = await _api.get('/community/groups/$groupId/members');
      if (res.success && res.data != null) {
        final list = res.data!['members'] as List? ?? [];
        return list.map((m) => m as Map<String, dynamic>).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Update a group member (mute/ban/role) (admin/moderator only).
  Future<bool> updateMember({
    required String groupId,
    required String memberId,
    bool? isMuted,
    String? status,
    String? roleInGroup,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (isMuted != null) body['isMuted'] = isMuted;
      if (status != null) body['status'] = status;
      if (roleInGroup != null) body['roleInGroup'] = roleInGroup;
      final res = await _api.patch('/community/groups/$groupId/members/$memberId', body);
      return res.success;
    } catch (_) {
      return false;
    }
  }
}
