import 'dart:io';
import '../models/models.dart';
import 'api_client.dart';

class PostService {
  static final PostService instance = PostService._internal();
  PostService._internal();

  /// Fetch global feed or community feed
  Future<List<Post>> fetchFeed({String? communityId, int page = 1, int limit = 20}) async {
    try {
      String query = '?page=$page&limit=$limit';
      if (communityId != null) {
        query += '&communityId=$communityId';
      }

      final response = await ApiClient.instance.get('/posts$query');
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data;
        return data.map((json) => Post.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching feed: $e');
      return [];
    }
  }

  /// Fetch subscription feed (posts from followed users only)
  Future<List<Post>> fetchSubscriptionFeed({int page = 1, int limit = 20}) async {
    try {
      final response = await ApiClient.instance.get('/posts/subscriptions?page=$page&limit=$limit');
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data;
        return data.map((json) => Post.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching subscription feed: $e');
      return [];
    }
  }

  /// Create a new post
  Future<Post?> createPost({
    required String content,
    String? communityId,
    File? imageFile,
  }) async {
    try {
      final fields = {
        'content': content,
        if (communityId != null) 'communityId': communityId,
      };

      final response = await ApiClient.instance.multipartPost(
        '/posts',
        fields: fields,
        file: imageFile,
        fileField: 'image',
      );

      if (response.success && response.data != null) {
        return Post.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  /// Update an existing post
  Future<Post?> updatePost({
    required String postId,
    required String content,
    File? imageFile,
  }) async {
    try {
      final fields = {
        'content': content,
      };

      final response = await ApiClient.instance.multipartRequest(
        'PUT',
        '/posts/$postId',
        fields: fields,
        fileField: imageFile != null ? 'image' : null,
        filePath: imageFile?.path,
      );

      if (response.success && response.data != null) {
        return Post.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error updating post: $e');
      return null;
    }
  }

  /// Toggle Like
  Future<bool> toggleLike(String postId) async {
    try {
      final response = await ApiClient.instance.post('/posts/$postId/like');
      return response.success;
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  /// Share post
  Future<bool> sharePost(String postId) async {
    try {
      final response = await ApiClient.instance.post('/posts/$postId/share');
      return response.success;
    } catch (e) {
      print('Error sharing post: $e');
      return false;
    }
  }

  /// Repost a post
  Future<Post?> repostPost(String postId) async {
    try {
      final response = await ApiClient.instance.post('/posts/$postId/repost');
      if (response.success && response.data != null) {
        return Post.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error reposting post: $e');
      return null;
    }
  }

  /// Fetch comments for a post
  Future<List<Comment>> fetchComments(String postId) async {
    try {
      final response = await ApiClient.instance.get('/posts/$postId/comments');
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data;
        return data.map((json) => Comment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  /// Add a comment to a post
  Future<Comment?> addComment(String postId, String content) async {
    try {
      final response = await ApiClient.instance.post('/posts/$postId/comments', {
        'content': content,
      });
      if (response.success && response.data != null) {
        return Comment.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  /// Reply to a comment
  Future<Comment?> replyToComment(String postId, String commentId, String content) async {
    try {
      final response = await ApiClient.instance.post(
        '/posts/$postId/comments/$commentId/reply',
        {'content': content},
      );
      if (response.success && response.data != null) {
        return Comment.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error replying to comment: $e');
      return null;
    }
  }

  /// Like/unlike a comment
  Future<bool> likeComment(String postId, String commentId) async {
    try {
      final response = await ApiClient.instance.post(
        '/posts/$postId/comments/$commentId/like',
      );
      return response.success;
    } catch (e) {
      print('Error liking comment: $e');
      return false;
    }
  }

  /// Delete a comment
  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      final response = await ApiClient.instance.delete('/posts/$postId/comments/$commentId');
      return response.success;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  /// Toggle hide/show a comment
  Future<bool> toggleHideComment(String postId, String commentId) async {
    try {
      final response = await ApiClient.instance.patch(
        '/posts/$postId/comments/$commentId/hide',
        {},
      );
      return response.success;
    } catch (e) {
      print('Error toggling hide comment: $e');
      return false;
    }
  }

  /// Delete a reply to a comment
  Future<bool> deleteReply(String postId, String commentId, String replyId) async {
    try {
      final response = await ApiClient.instance.delete(
        '/posts/$postId/comments/$commentId/replies/$replyId',
      );
      return response.success;
    } catch (e) {
      print('Error deleting reply: $e');
      return false;
    }
  }

  /// Toggle hide/show a reply
  Future<bool> toggleHideReply(String postId, String commentId, String replyId) async {
    try {
      final response = await ApiClient.instance.patch(
        '/posts/$postId/comments/$commentId/replies/$replyId/hide',
        {},
      );
      return response.success;
    } catch (e) {
      print('Error toggling hide reply: $e');
      return false;
    }
  }

  /// Like/unlike a reply
  Future<bool> likeReply(String postId, String commentId, String replyId) async {
    try {
      final response = await ApiClient.instance.post(
        '/posts/$postId/comments/$commentId/replies/$replyId/like',
      );
      return response.success;
    } catch (e) {
      print('Error liking reply: $e');
      return false;
    }
  }

  /// Follow/unfollow a user
  Future<bool> toggleFollow(String userId) async {
    try {
      final response = await ApiClient.instance.post('/users/$userId/follow');
      return response.success;
    } catch (e) {
      print('Error toggling follow: $e');
      return false;
    }
  }
}
