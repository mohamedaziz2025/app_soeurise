# Soeurise Social Features API Documentation

## Overview
This document describes all the social features implemented in the Soeurise backend API, including follow systems, comment/reply management, privacy controls, and more.

## Table of Contents
1. [Follow System](#follow-system)
2. [Privacy Management](#privacy-management)
3. [Comment Management](#comment-management)
4. [Reply Management](#reply-management)
5. [Message System](#message-system)
6. [Data Models](#data-models)

---

## Follow System

### 1. Toggle Follow
**Endpoint:** `POST /api/users/:id/follow`

**Description:** Follow or unfollow a user. For public profiles, follow is immediate. For private profiles, a follow request is sent.

**Request:**
```json
{
  "userId": "target_user_id"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "User followed successfully",
  "data": {
    "action": "followed",
    "targetUser": {
      "id": "user_id",
      "username": "username",
      "profilePrivacy": "public"
    }
  }
}
```

**Response (Private Profile):**
```json
{
  "success": true,
  "message": "Follow request sent",
  "data": {
    "action": "request_sent",
    "targetUser": {
      "id": "user_id",
      "username": "username",
      "profilePrivacy": "private"
    }
  }
}
```

**Response (Already Following):**
```json
{
  "success": true,
  "message": "User unfollowed successfully",
  "data": {
    "action": "unfollowed"
  }
}
```

**Status Codes:**
- 200: Success
- 401: Unauthorized
- 404: User not found
- 400: Cannot follow yourself

---

### 2. Get Follow Requests
**Endpoint:** `GET /api/users/me/follow-requests`

**Description:** Retrieve all pending follow requests for the authenticated user.

**Query Parameters:**
- `status` (optional): Filter by 'pending', 'accepted', or 'rejected'

**Response:**
```json
{
  "success": true,
  "data": {
    "followRequests": [
      {
        "id": "request_id",
        "from": {
          "id": "user_id",
          "username": "username",
          "firstName": "First",
          "lastName": "Last",
          "avatarUrl": "url"
        },
        "status": "pending",
        "requestedAt": "2024-01-15T10:30:00Z"
      }
    ],
    "total": 5,
    "pending": 3
  }
}
```

**Status Codes:**
- 200: Success
- 401: Unauthorized

---

### 3. Accept Follow Request
**Endpoint:** `POST /api/users/me/follow-requests/:requesterId/accept`

**Description:** Accept a follow request from another user. Automatically adds them to followers and adds you to their following.

**Response:**
```json
{
  "success": true,
  "message": "Follow request accepted",
  "data": {
    "follower": {
      "id": "user_id",
      "username": "username"
    }
  }
}
```

**Status Codes:**
- 200: Success
- 401: Unauthorized
- 404: Request not found
- 400: Request already processed

---

### 4. Reject Follow Request
**Endpoint:** `POST /api/users/me/follow-requests/:requesterId/reject`

**Description:** Reject a follow request from another user.

**Response:**
```json
{
  "success": true,
  "message": "Follow request rejected",
  "data": {
    "status": "rejected"
  }
}
```

**Status Codes:**
- 200: Success
- 401: Unauthorized
- 404: Request not found

---

## Privacy Management

### Update Profile Privacy
**Endpoint:** `PUT /api/users/me/privacy`

**Description:** Change your profile privacy setting to public (anyone can follow) or private (must accept requests).

**Request:**
```json
{
  "privacy": "private"
}
```

**Valid Values:**
- `"public"` - Anyone can follow without request
- `"private"` - All follows require acceptance

**Response:**
```json
{
  "success": true,
  "message": "Privacy setting updated",
  "data": {
    "profilePrivacy": "private"
  }
}
```

**Status Codes:**
- 200: Success
- 401: Unauthorized
- 400: Invalid privacy value

**Note:** When changing from public to private, existing followers remain but new follows will require acceptance.

---

## Comment Management

### 1. Delete Comment
**Endpoint:** `DELETE /api/posts/:id/comments/:commentId`

**Description:** Delete a comment. Only the comment author or post owner can delete.

**Authorization:**
- Comment author
- Post owner

**Response:**
```json
{
  "success": true,
  "message": "Comment deleted successfully"
}
```

**Status Codes:**
- 200: Success
- 401: Unauthorized
- 403: Forbidden (not author or post owner)
- 404: Comment or post not found

---

### 2. Hide/Show Comment
**Endpoint:** `PATCH /api/posts/:id/comments/:commentId/hide`

**Description:** Hide or show a comment. Hidden comments are not displayed to other users but remain in database.

**Authorization:**
- Comment author
- Post owner

**Response:**
```json
{
  "success": true,
  "message": "Comment hidden",
  "data": {
    "comment": {
      "id": "comment_id",
      "hidden": true
    }
  }
}
```

**Status Codes:**
- 200: Success
- 401: Unauthorized
- 403: Forbidden
- 404: Comment or post not found

---

### 3. Like Comment
**Endpoint:** `POST /api/posts/:id/comments/:commentId/like`

**Description:** Like or unlike a comment.

**Response:**
```json
{
  "success": true,
  "message": "Comment liked",
  "data": {
    "comment": {
      "id": "comment_id",
      "likes": ["user_id1", "user_id2"],
      "likeCount": 2
    }
  }
}
```

**Status Codes:**
- 200: Success
- 401: Unauthorized
- 404: Comment or post not found

---

## Reply Management

### 1. Create Reply
**Endpoint:** `POST /api/posts/:id/comments/:commentId/reply`

**Description:** Add a reply to a comment.

**Request:**
```json
{
  "content": "This is my reply"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Reply added",
  "data": {
    "reply": {
      "id": "reply_id",
      "author": {
        "id": "user_id",
        "username": "username"
      },
      "content": "This is my reply",
      "createdAt": "2024-01-15T10:30:00Z"
    }
  }
}
```

**Status Codes:**
- 201: Created
- 401: Unauthorized
- 404: Comment or post not found

---

### 2. Delete Reply
**Endpoint:** `DELETE /api/posts/:id/comments/:commentId/replies/:replyId`

**Description:** Delete a reply. Only the reply author or post owner can delete.

**Authorization:**
- Reply author
- Post owner

**Response:**
```json
{
  "success": true,
  "message": "Reply deleted successfully"
}
```

**Status Codes:**
- 200: Success
- 401: Unauthorized
- 403: Forbidden
- 404: Reply, comment, or post not found

---

### 3. Hide/Show Reply
**Endpoint:** `PATCH /api/posts/:id/comments/:commentId/replies/:replyId/hide`

**Description:** Hide or show a reply.

**Authorization:**
- Reply author
- Post owner

**Response:**
```json
{
  "success": true,
  "message": "Reply hidden",
  "data": {
    "reply": {
      "id": "reply_id",
      "hidden": true
    }
  }
}
```

**Status Codes:**
- 200: Success
- 401: Unauthorized
- 403: Forbidden
- 404: Reply, comment, or post not found

---

### 4. Like Reply
**Endpoint:** `POST /api/posts/:id/comments/:commentId/replies/:replyId/like`

**Description:** Like or unlike a reply.

**Response:**
```json
{
  "success": true,
  "message": "Reply liked",
  "data": {
    "reply": {
      "id": "reply_id",
      "likes": ["user_id1", "user_id2"],
      "likeCount": 2
    }
  }
}
```

**Status Codes:**
- 200: Success
- 401: Unauthorized
- 404: Reply, comment, or post not found

---

## Message System

### List Group Messages
**Endpoint:** `GET /api/community/groups/:id/messages`

**Description:** Retrieve group messages with sender information populated.

**Query Parameters:**
- `limit` (default: 30, max: 100): Number of messages to retrieve
- `before` (optional): ISO date string to fetch messages before this time

**Response:**
```json
{
  "success": true,
  "data": {
    "messages": [
      {
        "id": "message_id",
        "groupId": "group_id",
        "text": "Message content",
        "imageUrl": "/uploads/group-messages/image.jpg",
        "imageMime": "image/jpeg",
        "createdAt": "2024-01-15T10:30:00Z",
        "sender": {
          "id": "user_id",
          "firstName": "John",
          "lastName": "Doe",
          "username": "johndoe",
          "avatarUrl": "/uploads/avatars/avatar.jpg"
        }
      }
    ]
  }
}
```

**Status Codes:**
- 200: Success
- 401: Unauthorized
- 403: Not a group member
- 404: Group not found

**Note:** Sender information is automatically populated by the backend to display who sent each message.

---

### Send Group Message
**Endpoint:** `POST /api/community/groups/:id/messages`

**Description:** Send a text message or image to a group.

**Request (Text):**
```
Content-Type: multipart/form-data

Fields:
- text: "Message content"
```

**Request (With Image):**
```
Content-Type: multipart/form-data

Fields:
- text: "Check out this image"
- image: <binary file data>
```

**Supported Image Types:**
- image/jpeg
- image/png
- image/gif
- image/webp

**Response:**
```json
{
  "success": true,
  "message": "Message envoyé",
  "data": {
    "message": {
      "id": "message_id",
      "groupId": "group_id",
      "text": "Message content",
      "imageUrl": "/uploads/group-messages/image.jpg",
      "createdAt": "2024-01-15T10:30:00Z",
      "sender": {
        "id": "user_id",
        "username": "username"
      }
    }
  }
}
```

**Status Codes:**
- 201: Created
- 401: Unauthorized
- 403: Not a group member
- 400: Empty message
- 413: File too large

---

## Data Models

### User Model
```javascript
{
  _id: ObjectId,
  firstName: String,
  lastName: String,
  username: String (unique),
  email: String (unique),
  passwordHash: String,
  role: String (user|admin),
  isActive: Boolean,
  avatarUrl: String,
  
  // Social fields
  profilePrivacy: String (public|private),
  following: [ObjectId],           // Users I follow
  followers: [ObjectId],           // Users following me
  followRequests: [{
    from: ObjectId,               // User requesting to follow
    status: String (pending|accepted|rejected),
    requestedAt: Date
  }],
  
  createdAt: Date,
  updatedAt: Date
}
```

### Post Model
```javascript
{
  _id: ObjectId,
  author: ObjectId (ref User),
  content: String,
  image: String,
  communityId: ObjectId,
  
  // Engagement
  likesCount: Number,
  likedBy: [ObjectId],
  commentsCount: Number,
  
  comments: [{
    author: ObjectId,
    content: String,
    hidden: Boolean,
    likes: [ObjectId],
    createdAt: Date,
    replies: [{
      author: ObjectId,
      content: String,
      hidden: Boolean,
      likes: [ObjectId],
      createdAt: Date
    }]
  }],
  
  createdAt: Date,
  updatedAt: Date
}
```

### GroupMessage Model
```javascript
{
  _id: ObjectId,
  groupId: ObjectId (ref Group),
  senderId: ObjectId (ref User),    // Populated with user data
  text: String,
  imageUrl: String,
  imageMime: String,
  createdAt: Date,
  updatedAt: Date
}
```

---

## Error Handling

All errors return standardized responses:

```json
{
  "success": false,
  "message": "Error description",
  "errors": ["Detailed error 1", "Detailed error 2"]
}
```

**Common HTTP Status Codes:**
- 400: Bad Request (validation error)
- 401: Unauthorized (not authenticated)
- 403: Forbidden (not authorized)
- 404: Not Found
- 500: Internal Server Error

---

## Authentication

All social feature endpoints require authentication via JWT token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

The token is automatically validated by the `requireAuth` middleware.

---

## Rate Limiting

Consider implementing rate limiting for:
- Follow requests: 10 requests per hour per user
- Message sending: 30 messages per minute per group
- Comment creation: 20 comments per hour per user

---

## Future Enhancements

1. **Notification System:** Real-time notifications for follow requests, replies, likes
2. **Blocking System:** Users can block other users
3. **Muting:** Temporarily mute notifications from specific users
4. **Message Reactions:** Emoji reactions to messages
5. **Message Editing:** Edit sent messages (with history)
6. **Message Deletion:** Delete sent messages with soft delete
7. **Pinned Messages:** Group admins can pin important messages
8. **Message Threading:** Nested message threads
9. **Search:** Full-text search for messages and posts
10. **Mentions:** @ mentions with notifications

---

## Testing

### Test Follow System
```bash
# Follow public user
curl -X POST http://localhost:3000/api/users/:id/follow \
  -H "Authorization: Bearer <token>"

# Get follow requests
curl -X GET http://localhost:3000/api/users/me/follow-requests \
  -H "Authorization: Bearer <token>"

# Accept request
curl -X POST http://localhost:3000/api/users/me/follow-requests/:requesterId/accept \
  -H "Authorization: Bearer <token>"
```

### Test Comments
```bash
# Delete comment
curl -X DELETE http://localhost:3000/api/posts/:id/comments/:commentId \
  -H "Authorization: Bearer <token>"

# Hide comment
curl -X PATCH http://localhost:3000/api/posts/:id/comments/:commentId/hide \
  -H "Authorization: Bearer <token>"

# Like reply
curl -X POST http://localhost:3000/api/posts/:id/comments/:commentId/replies/:replyId/like \
  -H "Authorization: Bearer <token>"
```

---

## Version History

- **v1.0** (Jan 2024): Initial release
  - Follow system with public/private profiles
  - Comment and reply management
  - Sender display in group messages
  - Privacy controls

---

## Support

For issues or questions:
1. Check existing documentation
2. Review error messages in logs
3. Verify JWT token validity
4. Ensure user has required permissions
5. Contact development team

---

Last Updated: January 2024
