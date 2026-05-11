import 'package:flutter/material.dart';
import '../constants.dart';
import '../theme/glass_widgets.dart';
import '../widgets/responsive.dart';
import '../services/notification_service.dart';
import '../models/models.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    NotificationRealtimeService.instance.loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final sidePadding = Responsive.sidePadding(context, maxWidth: 720);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(sidePadding, 16, sidePadding, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                              Icons.arrow_back_rounded,
                              color: AppColors.textPrimary,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Notifications', style: AppTextStyles.headline2),
                      ],
                    ),
                    TextButton(
                      onPressed: () =>
                          NotificationRealtimeService.instance.markAllRead(),
                      child: Text(
                        'Tout lire',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ValueListenableBuilder<List<AppNotification>>(
              valueListenable: NotificationRealtimeService
                  .instance
                  .notifications,
              builder: (context, notifications, _) {
                if (notifications.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Aucune notification',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final n = notifications[index];
                        final icon = _iconForType(n.type);
                        final color = _colorForType(n.type);
                        return FadeSlideIn(
                          delay: Duration(milliseconds: index * 80),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () => NotificationRealtimeService
                                  .instance
                                  .markRead(n.id),
                              child: GlassCard(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: color.withAlpha(25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(icon, color: color, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n.title.isNotEmpty ? n.title : n.message,
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _timeAgo(n.createdAt),
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: n.isRead
                                            ? Colors.transparent
                                            : AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: notifications.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'post_like':
        return Icons.favorite_rounded;
      case 'post_comment':
        return Icons.comment_rounded;
      case 'group_join':
        return Icons.group_add_rounded;
      case 'event_new':
        return Icons.event_rounded;
      case 'masterclass_new':
        return Icons.school_rounded;
      case 'group_message':
        return Icons.chat_bubble_rounded;
      case 'private_message':
        return Icons.mail_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'post_like':
        return AppColors.primary;
      case 'post_comment':
        return const Color(0xFF64B5F6);
      case 'group_join':
        return AppColors.successColor;
      case 'event_new':
        return AppColors.warningColor;
      case 'masterclass_new':
        return const Color(0xFFBA68C8);
      case 'group_message':
        return AppColors.primaryDark;
      case 'private_message':
        return const Color(0xFF42A5F5);
      default:
        return AppColors.primary;
    }
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return "a l'instant";
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}
