# Frontend Integration Guide - Social Features

## Quick Reference for Implementing Frontend UI

This guide shows how to integrate the backend API endpoints into the Flutter frontend.

## 1. Follow System Implementation

### Add Follow Button to User Profiles

**Service Method (add to user_service.dart):**
```dart
Future<bool> toggleFollow(String userId) async {
  try {
    final res = await _api.post('/users/$userId/follow', {});
    return res.success;
  } catch (_) {
    return false;
  }
}
```

**Widget:**
```dart
class FollowButton extends StatefulWidget {
  final String userId;
  final bool isFollowing;
  
  const FollowButton({
    required this.userId,
    required this.isFollowing,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  late bool _isFollowing;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowing;
  }

  Future<void> _toggleFollow() async {
    setState(() => _isLoading = true);
    final success = await UserService.instance.toggleFollow(widget.userId);
    if (success) {
      setState(() => _isFollowing = !_isFollowing);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _toggleFollow,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isFollowing
            ? AppColors.lightGrey
            : AppColors.primary,
      ),
      child: Text(_isFollowing ? 'Suivi' : 'Suivre'),
    );
  }
}
```

---

### Display Follow Requests Screen

**Service Method:**
```dart
Future<List<FollowRequest>> getFollowRequests() async {
  try {
    final res = await _api.get('/users/me/follow-requests');
    if (res.success && res.data != null) {
      final requests = res.data!['followRequests'] as List? ?? [];
      return requests
          .map((r) => FollowRequest.fromJson(r as Map<String, dynamic>))
          .toList();
    }
    return [];
  } catch (_) {
    return [];
  }
}

Future<bool> acceptFollowRequest(String requesterId) async {
  try {
    final res = await _api.post(
      '/users/me/follow-requests/$requesterId/accept',
      {}
    );
    return res.success;
  } catch (_) {
    return false;
  }
}

Future<bool> rejectFollowRequest(String requesterId) async {
  try {
    final res = await _api.post(
      '/users/me/follow-requests/$requesterId/reject',
      {}
    );
    return res.success;
  } catch (_) {
    return false;
  }
}
```

**Screen:**
```dart
class FollowRequestsScreen extends StatefulWidget {
  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  late Future<List<FollowRequest>> _requests;

  @override
  void initState() {
    super.initState();
    _requests = UserService.instance.getFollowRequests();
  }

  Future<void> _handleRequest(String requesterId, bool accept) async {
    final success = accept
        ? await UserService.instance.acceptFollowRequest(requesterId)
        : await UserService.instance.rejectFollowRequest(requesterId);
    
    if (success) {
      setState(() {
        _requests = UserService.instance.getFollowRequests();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Demandes de suivi')),
      body: FutureBuilder<List<FollowRequest>>(
        future: _requests,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          
          final requests = snapshot.data ?? [];
          
          if (requests.isEmpty) {
            return Center(
              child: Text('Aucune demande de suivi'),
            );
          }
          
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(req.from.avatarUrl),
                ),
                title: Text('${req.from.firstName} ${req.from.lastName}'),
                subtitle: Text('@${req.from.username}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: AppColors.primary),
                      onPressed: () => _handleRequest(req.from.id, true),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => _handleRequest(req.from.id, false),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

### Privacy Settings

**Service Method:**
```dart
Future<bool> updateProfilePrivacy(String privacy) async {
  // privacy = 'public' or 'private'
  try {
    final res = await _api.put('/users/me/privacy', {
      'privacy': privacy,
    });
    return res.success;
  } catch (_) {
    return false;
  }
}
```

**Widget:**
```dart
class PrivacySettings extends StatefulWidget {
  @override
  State<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings> {
  String _selectedPrivacy = 'public';

  Future<void> _savePrivacy() async {
    final success = await UserService.instance
        .updateProfilePrivacy(_selectedPrivacy);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paramètres de confidentialité mis à jour')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Confidentialité')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            RadioListTile<String>(
              title: Text('Public'),
              subtitle: Text('Tout le monde peut vous suivre'),
              value: 'public',
              groupValue: _selectedPrivacy,
              onChanged: (v) => setState(() => _selectedPrivacy = v ?? 'public'),
            ),
            RadioListTile<String>(
              title: Text('Privé'),
              subtitle: Text('Vous devez accepter les demandes de suivi'),
              value: 'private',
              groupValue: _selectedPrivacy,
              onChanged: (v) => setState(() => _selectedPrivacy = v ?? 'private'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _savePrivacy,
              child: Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 2. Comment & Reply Management

### Delete Comment

**Service Method:**
```dart
Future<bool> deleteComment(String postId, String commentId) async {
  try {
    final res = await _api.delete('/posts/$postId/comments/$commentId');
    return res.success;
  } catch (_) {
    return false;
  }
}
```

**Implementation:**
```dart
// In comment widget
PopupMenuButton(
  itemBuilder: (context) => [
    PopupMenuItem(
      child: Text('Supprimer'),
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirmer'),
            content: Text('Êtes-vous sûr de vouloir supprimer ce commentaire ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Supprimer'),
              ),
            ],
          ),
        );
        
        if (confirm == true) {
          final success = await PostsService.instance
              .deleteComment(postId, commentId);
          if (success) {
            // Refresh comments or remove from list
          }
        }
      },
    ),
  ],
)
```

---

### Hide/Show Comment

**Service Method:**
```dart
Future<bool> toggleHideComment(String postId, String commentId) async {
  try {
    final res = await _api.patch(
      '/posts/$postId/comments/$commentId/hide',
      {}
    );
    return res.success;
  } catch (_) {
    return false;
  }
}
```

---

### Like Reply

**Service Method:**
```dart
Future<bool> likeReply(String postId, String commentId, String replyId) async {
  try {
    final res = await _api.post(
      '/posts/$postId/comments/$commentId/replies/$replyId/like',
      {}
    );
    return res.success;
  } catch (_) {
    return false;
  }
}
```

**Widget:**
```dart
class ReplyLikeButton extends StatefulWidget {
  final String postId;
  final String commentId;
  final String replyId;
  final int initialLikes;
  
  const ReplyLikeButton({
    required this.postId,
    required this.commentId,
    required this.replyId,
    required this.initialLikes,
  });

  @override
  State<ReplyLikeButton> createState() => _ReplyLikeButtonState();
}

class _ReplyLikeButtonState extends State<ReplyLikeButton> {
  late int _likeCount;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.initialLikes;
  }

  Future<void> _toggleLike() async {
    final success = await PostsService.instance.likeReply(
      widget.postId,
      widget.commentId,
      widget.replyId,
    );
    
    if (success) {
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleLike,
      child: Row(
        children: [
          Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.grey,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            '$_likeCount',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
```

---

## 3. Image Upload Fix (If Needed)

**Verify sendMessage Implementation:**
```dart
Future<Map<String, dynamic>?> sendMessage({
  required String groupId,
  String text = '',
  String? imagePath,
}) async {
  try {
    if ((text.trim().isEmpty) && imagePath == null) return null;
    
    final fields = <String, String>{};
    if (text.trim().isNotEmpty) fields['text'] = text.trim();

    // IMPORTANT: Field name must be 'image' to match multer middleware
    final res = await _api.multipartRequest(
      'POST',
      '/community/groups/$groupId/messages',
      fields: fields,
      fileField: imagePath != null ? 'image' : null,  // Correct field name
      filePath: imagePath,
    );

    if (res.success && res.data != null) {
      return res.data!['message'] as Map<String, dynamic>?;
    }
    return null;
  } catch (e) {
    print('Send message error: $e');
    return null;
  }
}
```

---

## 4. Testing Endpoints

### Manual Testing with cURL

```bash
# 1. Follow user
curl -X POST http://localhost:3000/api/users/USER_ID/follow \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json"

# 2. Get follow requests
curl -X GET http://localhost:3000/api/users/me/follow-requests \
  -H "Authorization: Bearer TOKEN"

# 3. Accept follow request
curl -X POST http://localhost:3000/api/users/me/follow-requests/REQUESTER_ID/accept \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json"

# 4. Delete comment
curl -X DELETE http://localhost:3000/api/posts/POST_ID/comments/COMMENT_ID \
  -H "Authorization: Bearer TOKEN"

# 5. Like reply
curl -X POST http://localhost:3000/api/posts/POST_ID/comments/COMMENT_ID/replies/REPLY_ID/like \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json"

# 6. Update privacy
curl -X PUT http://localhost:3000/api/users/me/privacy \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"privacy": "private"}'
```

---

## 5. Models to Create/Update

**FollowRequest Model:**
```dart
class FollowRequest {
  final String id;
  final User from;
  final String status;  // 'pending', 'accepted', 'rejected'
  final DateTime requestedAt;

  FollowRequest({
    required this.id,
    required this.from,
    required this.status,
    required this.requestedAt,
  });

  factory FollowRequest.fromJson(Map<String, dynamic> json) {
    return FollowRequest(
      id: json['id'] as String,
      from: User.fromJson(json['from'] as Map<String, dynamic>),
      status: json['status'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
    );
  }
}
```

---

## Implementation Priority

1. **High Priority:**
   - Follow button on user profiles
   - Follow requests UI
   - Privacy settings screen
   - Comment delete button

2. **Medium Priority:**
   - Hide comment toggle
   - Like reply button
   - Reply delete button
   - Hide reply toggle

3. **Low Priority (Enhancement):**
   - Animations
   - Real-time updates
   - Optimistic updates
   - Caching

---

## Notes

- All endpoints require JWT authentication
- Use the `Authorization: Bearer <token>` header
- Handle loading states while making API calls
- Show error messages to users on failure
- Refresh data after successful operations
- Consider optimistic UI updates for better UX

---

Last Updated: January 2024
