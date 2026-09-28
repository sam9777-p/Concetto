import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/event_item.dart';
import '../../../services/event_likes_service.dart';

class EventLikeButton extends ConsumerStatefulWidget {
  final EventItem event;
  final bool isLarge;

  const EventLikeButton({
    super.key,
    required this.event,
    this.isLarge = false,
  });

  @override
  ConsumerState<EventLikeButton> createState() => _EventLikeButtonState();
}

class _EventLikeButtonState extends ConsumerState<EventLikeButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animController.forward().then((_) => _animController.reverse());
    ref.read(eventLikesProvider.notifier).toggleLike(widget.event);
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider to react to changes immediately
    ref.watch(eventLikesProvider);
    final notifier = ref.read(eventLikesProvider.notifier);

    final isLiked = notifier.isEventLiked(widget.event.id);
    final count = notifier.getEffectiveLikes(widget.event);

    final iconSize = widget.isLarge ? 20.0 : 15.0;
    final fontSize = widget.isLarge ? 11.5 : 9.5;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isLiked
                ? const Color(0xFFFF1744).withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.2),
            width: isLiked ? 1.0 : 0.6,
          ),
          boxShadow: isLiked
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF1744).withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: iconSize,
                color: isLiked ? const Color(0xFFFF1744) : Colors.white70,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: GoogleFonts.rajdhani(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: isLiked ? const Color(0xFFFF5252) : Colors.white,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
