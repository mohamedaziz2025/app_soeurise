import 'package:flutter/material.dart';
import '../constants.dart';
import '../theme/glass_widgets.dart';
import '../models/models.dart';
import '../widgets/content_image.dart';
import '../services/event_service.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Event> events = [];
  bool _isLoading = true;
  final Set<String> _registered = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final fetched = await EventService.instance.fetchEvents();
      if (mounted) {
        setState(() {
          events = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: FadeSlideIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Événements', style: AppTextStyles.headline1),
                      const SizedBox(height: 4),
                      Text(
                        'Ne manquez aucun événement',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
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
            else if (events.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    "Aucun événement à venir",
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = events[index];
                    final isRegistered = _registered.contains(event.id);
                    return FadeSlideIn(
                      delay: Duration(milliseconds: index * 150),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: GlassCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image with date chip
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(
                                          AppBorderRadius.lg),
                                      topRight: Radius.circular(
                                          AppBorderRadius.lg),
                                    ),
                                    child: ContentImage(
                                      imageUrl: event.imageUrl,
                                      height: 180,
                                    ),
                                  ),
                                  // Date chip
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withAlpha(80),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '${event.dateTime.day}',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            _monthName(event.dateTime.month),
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Type badge
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(220),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            event.type == 'online'
                                                ? Icons.videocam_rounded
                                                : Icons.location_on_rounded,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            event.type == 'online'
                                                ? 'En ligne'
                                                : 'Présentiel',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style:
                                          AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                          color: AppColors.textLight,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          event.location,
                                          style: AppTextStyles.bodySmall,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 16,
                                          color: AppColors.textLight,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${event.dateTime.hour}:00',
                                          style: AppTextStyles.bodySmall,
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    GlassButton(
                                      label: isRegistered
                                          ? 'Inscrit ✓'
                                          : 'S\'inscrire',
                                      icon: isRegistered
                                          ? Icons.check_circle_rounded
                                          : Icons.arrow_forward_rounded,
                                      gradient: isRegistered
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF81C784),
                                                Color(0xFF66BB6A),
                                              ],
                                            )
                                          : null,
                                      onPressed: () {
                                        setState(() {
                                          if (isRegistered) {
                                            _registered.remove(event.id);
                                          } else {
                                            _registered.add(event.id);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: events.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'JAN', 'FÉV', 'MAR', 'AVR', 'MAI', 'JUN',
      'JUL', 'AOÛ', 'SEP', 'OCT', 'NOV', 'DÉC',
    ];
    return months[month - 1];
  }
}
