import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../theme/glass_widgets.dart';
import '../services/community_service.dart';
import '../widgets/responsive.dart';
import 'group_members_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final String communityId;
  final String communityName;

  const GroupChatScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  late final ValueNotifier<List<ChatMessage>> messages;
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    messages = CommunityService.instance.messagesFor(widget.communityId);
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final list = await CommunityService.instance.fetchMessages(widget.communityId);
    if (!mounted) return;
    final mapped = list.map((m) {
      final sender = m['sender'] as Map<String, dynamic>?;
      final senderName = sender == null
          ? 'Utilisateur'
          : (sender['firstName'] != null || sender['lastName'] != null)
              ? '${sender['firstName'] ?? ''} ${sender['lastName'] ?? ''}'.trim()
              : (sender['username'] ?? 'Utilisateur');
      final text = (m['text'] ?? '').toString();
      final imageUrl = (m['imageUrl'] ?? '').toString();
      final display = imageUrl.isNotEmpty ? '[Image] $text' : text;
      return ChatMessage(
        sender: senderName.isNotEmpty ? senderName : 'Utilisateur',
        text: display,
        timestamp: m['createdAt'] != null
            ? DateTime.tryParse(m['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
    }).toList();
    messages.value = mapped;
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _sendText(text);
  }

  Future<void> _sendText(String text) async {
    if (_isSending) return;
    setState(() => _isSending = true);
    final result = await CommunityService.instance.sendMessage(
      groupId: widget.communityId,
      text: text,
    );
    if (!mounted) return;
    setState(() => _isSending = false);
    if (result != null) {
      CommunityService.instance.addMessage(
        widget.communityId,
        ChatMessage(sender: 'Vous', text: text),
      );
      _controller.clear();
    }
  }

  Future<void> _sendImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    if (_isSending) return;
    setState(() => _isSending = true);
    final result = await CommunityService.instance.sendMessage(
      groupId: widget.communityId,
      imagePath: picked.path,
    );
    if (!mounted) return;
    setState(() => _isSending = false);
    if (result != null) {
      CommunityService.instance.addMessage(
        widget.communityId,
        ChatMessage(sender: 'Vous', text: '[Image]'),
      );
    }
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter le groupe'),
        content: Text('Êtes-vous sûr de vouloir quitter "${widget.communityName}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await CommunityService.instance.leaveGroup(widget.communityId);
              if (mounted) {
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vous avez quitté "${widget.communityName}"'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la tentative de quitter le groupe'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Quitter',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Glass app bar
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12,
              left: 8,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(50),
                  ),
                  child: Center(
                    child: Text(
                      widget.communityName[0].toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.communityName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'En ligne',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white.withAlpha(180),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupMembersScreen(
                          groupId: widget.communityId,
                          groupName: widget.communityName,
                          isAdmin: false, // TODO: Get from group data
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.people_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'leave') {
                      _showLeaveConfirmation();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'leave',
                      child: Text(
                        'Quitter le groupe',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ValueListenableBuilder<List<ChatMessage>>(
              valueListenable: messages,
              builder: (context, msgs, _) {
                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: AppColors.primary.withAlpha(100),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun message',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Soyez la première à écrire !',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final m = msgs[index];
                    final isMe = m.sender == 'Vous';
                    return FadeSlideIn(
                      delay: Duration(milliseconds: index * 50),
                      offset: Offset(isMe ? 20 : -20, 0),
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: Responsive.messageMaxWidth(context),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: isMe
                                ? AppColors.primaryGradient
                                : null,
                            color: isMe ? null : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isMe
                                        ? AppColors.primary
                                        : Colors.black)
                                    .withAlpha(15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    m.sender,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              if (m.text.startsWith('[Image]')) ...[
                                const Text(
                                  'Image envoyee',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Ouvrir dans le fil',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ] else
                                Text(
                                  m.text,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: isMe
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '${m.timestamp.hour.toString().padLeft(2, '0')}:${m.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: isMe
                                      ? Colors.white70
                                      : AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Ecrire un message...',
                      hintStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: AppColors.beigeDark.withAlpha(60),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: AppColors.beigeDark.withAlpha(60),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendImage,
                    icon: const Icon(Icons.image_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(50),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
