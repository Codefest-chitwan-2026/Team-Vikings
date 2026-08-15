import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/recipient_listing_model.dart';

class RecipientListingCard extends StatefulWidget {
  const RecipientListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.showAreaInSubtitle = true,
  });

  final RecipientListing listing;
  final VoidCallback onTap;
  final bool showAreaInSubtitle;

  @override
  State<RecipientListingCard> createState() => _RecipientListingCardState();
}

class _RecipientListingCardState extends State<RecipientListingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.listing.isNew) {
      // Pulses 3 times, then settles at rest — not an infinite flash.
      _pulseController.repeat(reverse: true, min: 0, max: 1, period: const Duration(milliseconds: 700));
      Future.delayed(const Duration(milliseconds: 2100), () {
        if (mounted) _pulseController.stop();
        if (mounted) _pulseController.value = 0;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final badgeColor =
    listing.isFree ? AppColors.primaryEmerald : AppColors.secondary;
    final badgeBg =
    listing.isFree ? const Color(0xFFE4F6E9) : const Color(0xFFFBE9E7);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Container(
                    height: 92,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: listing.headerGradient,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      listing.headerLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (listing.isNew)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryEmerald,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            listing.cardBadgeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.showAreaInSubtitle ? listing.subtitle : listing.browseSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        listing.isFree
                            ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryEmerald,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Claim',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                            : Text(
                          listing.priceLabel ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          '${listing.minutesLeft} min left',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}