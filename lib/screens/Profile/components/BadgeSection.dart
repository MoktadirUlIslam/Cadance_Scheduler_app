// lib/screens/Profile/components/BadgeSection.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/data_provider.dart';
import '../../../utilites/app_colors.dart';

class BadgeSection extends StatefulWidget {
  final bool isDarkMode;

  const BadgeSection({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<BadgeSection> createState() => _BadgeSectionState();
}

class _BadgeSectionState extends State<BadgeSection> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  List<Badge> _earnedBadges = [];
  List<Badge> _lockedBadges = [];
  int _totalPoints = 0;
  int _previousPoints = 0;
  bool _isLoading = true;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBadges();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadBadges() async {
    setState(() => _isLoading = true);

    try {
      final dataProvider = context.read<DataProvider>();

      final stats = await dataProvider.getActivityStats();
      final maxStreak = stats['maxStreak'] ?? 0;
      final currentStreak = stats['currentStreak'] ?? 0;
      final timerStreak = dataProvider.streak;
      final totalFocusMinutes = dataProvider.grandTotalFocusMinutes;

      final badgeCalculator = BadgeCalculator(
        maxStreak: maxStreak,
        currentStreak: currentStreak,
        timerStreak: timerStreak,
        totalFocusMinutes: totalFocusMinutes,
      );

      final result = badgeCalculator.calculateBadges();
      _previousPoints = 0;
      _earnedBadges = result.earnedBadges;
      _lockedBadges = result.lockedBadges;
      _totalPoints = result.totalPoints;
      _hasData = true;

      _entranceController.forward();
    } catch (e) {
      print('❌ Error loading badges: $e');
      _hasData = false;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openBadgeDetail(Badge badge, bool isEarned) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: _BadgeDetailDialog(
          badge: badge,
          isEarned: isEarned,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDarkMode
                  ? [AppColors.darkCard, AppColors.darkCard]
                  : [AppColors.card, AppColors.primaryLight.withOpacity(0.03)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isDarkMode ? AppColors.darkBorder : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildCompactStats(),
              const SizedBox(height: 12),
              if (_earnedBadges.isNotEmpty || _lockedBadges.isNotEmpty) ...[
                _buildBadgeCarousel(),
              ],
              if (_earnedBadges.isEmpty && _lockedBadges.isEmpty && !_hasData) ...[
                _buildEmptyState(),
              ],
              if (_earnedBadges.isEmpty && _lockedBadges.isEmpty && _hasData) ...[
                _buildNoBadgesState(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryLight, AppColors.accentLight],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Badges',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? AppColors.darkInk : AppColors.ink,
            ),
          ),
        ),
        _buildAnimatedPointsPill(),
      ],
    );
  }

  Widget _buildAnimatedPointsPill() {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: _previousPoints, end: _totalPoints),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      onEnd: () => _previousPoints = _totalPoints,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryLight, AppColors.accentLight],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.star_rounded, color: Colors.white, size: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactStats() {
    final totalBadges = _earnedBadges.length + _lockedBadges.length;
    final progress = totalBadges > 0 ? (_earnedBadges.length / totalBadges) : 0.0;

    return Row(
      children: [
        _buildMiniStat(
          _earnedBadges.length.toString(),
          'Earned',
          Icons.emoji_events_rounded,
          AppColors.primaryLight,
        ),
        const SizedBox(width: 8),
        _buildMiniStat(
          _lockedBadges.length.toString(),
          'Locked',
          Icons.lock_outline_rounded,
          widget.isDarkMode ? AppColors.darkInkSoft : Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Stack(
                      children: [
                        Container(
                          height: 3,
                          color: widget.isDarkMode
                              ? AppColors.darkBorder
                              : Colors.grey.shade200,
                        ),
                        FractionallySizedBox(
                          widthFactor: value.clamp(0.0, 1.0),
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primaryLight, AppColors.accentLight],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isDarkMode ? AppColors.darkBorder : Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? AppColors.darkInk : AppColors.ink,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  color: widget.isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCarousel() {
    final allBadges = [..._earnedBadges, ..._lockedBadges];

    return SizedBox(
      height: 128,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: allBadges.length,
        itemBuilder: (context, index) {
          final badge = allBadges[index];
          final isEarned = _earnedBadges.contains(badge);
          return _StaggeredBadgeItem(
            index: index,
            badge: badge,
            isEarned: isEarned,
            isDarkMode: widget.isDarkMode,
            onTap: () => _openBadgeDetail(badge, isEarned),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 20,
            color: widget.isDarkMode ? AppColors.darkInkSoft : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Text(
            'Start using the app to earn badges!',
            style: TextStyle(
              fontSize: 12,
              color: widget.isDarkMode ? AppColors.darkInkSoft : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBadgesState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 20,
            color: widget.isDarkMode ? AppColors.darkInkSoft : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Text(
            'Keep going! Badges coming soon!',
            style: TextStyle(
              fontSize: 12,
              color: widget.isDarkMode ? AppColors.darkInkSoft : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmerBlock(width: 28, height: 28, radius: 8),
              const SizedBox(width: 10),
              _shimmerBlock(width: 80, height: 16, radius: 4),
              const Spacer(),
              _shimmerBlock(width: 50, height: 22, radius: 12),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _shimmerBlock(height: 40, radius: 8),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _shimmerBlock(width: 70, height: 100, radius: 12),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBlock({double? width, required double height, required double radius}) {
    return _ShimmerBox(
      width: width,
      height: height,
      radius: radius,
      isDarkMode: widget.isDarkMode,
    );
  }
}

// Shimmer Box for loading state
class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  final bool isDarkMode;

  const _ShimmerBox({
    this.width,
    required this.height,
    required this.radius,
    required this.isDarkMode,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDarkMode ? AppColors.darkSurface : Colors.grey.shade200;
    final highlight = widget.isDarkMode ? AppColors.darkBorder : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1.5 + 3 * t, 0),
              end: Alignment(-0.5 + 3 * t, 0),
              colors: [base, highlight, base],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// Staggered Badge Item with Entrance Animation only
class _StaggeredBadgeItem extends StatefulWidget {
  final int index;
  final Badge badge;
  final bool isEarned;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _StaggeredBadgeItem({
    required this.index,
    required this.badge,
    required this.isEarned,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  State<_StaggeredBadgeItem> createState() => _StaggeredBadgeItemState();
}

class _StaggeredBadgeItemState extends State<_StaggeredBadgeItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: FractionalTranslation(
            translation: _slide.value,
            child: Transform.scale(scale: _scale.value, child: child),
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: _BadgeTile(
          badge: widget.badge,
          isEarned: widget.isEarned,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }
}

// Badge Tile - No continuous animations
class _BadgeTile extends StatelessWidget {
  final Badge badge;
  final bool isEarned;
  final bool isDarkMode;

  const _BadgeTile({
    required this.badge,
    required this.isEarned,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 82,
      height: 118,
      decoration: BoxDecoration(
        gradient: isEarned
            ? LinearGradient(
          colors: [
            badge.color.withOpacity(0.18),
            badge.color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: isEarned
            ? null
            : isDarkMode
            ? AppColors.darkSurface
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEarned
              ? badge.color.withOpacity(0.5)
              : isDarkMode
              ? AppColors.darkBorder
              : Colors.grey.shade200,
          width: isEarned ? 1.6 : 1,
        ),
        boxShadow: isEarned
            ? [
          BoxShadow(
            color: badge.color.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ]
            : null,
      ),
      child: Stack(
        children: [
          // Badge content
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEarned ? badge.color.withOpacity(0.12) : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      badge.icon,
                      style: TextStyle(
                        fontSize: isEarned ? 24 : 20,
                        color: isEarned
                            ? null
                            : (isDarkMode ? AppColors.darkInkSoft : Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  badge.name,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isEarned ? FontWeight.w700 : FontWeight.w400,
                    color: isEarned
                        ? (isDarkMode ? AppColors.darkInk : AppColors.ink)
                        : (isDarkMode ? AppColors.darkInkSoft : Colors.grey.shade500),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isEarned && badge.points > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: badge.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '+${badge.points}',
                      style: TextStyle(
                        fontSize: 7,
                        color: badge.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (!isEarned && badge.requirement != null)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppColors.darkSurface : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge.requirement!,
                      style: TextStyle(
                        fontSize: 6.5,
                        color: isDarkMode ? AppColors.darkInkSoft : Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Lock overlay
          if (!isEarned)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkBg : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 10,
                  color: isDarkMode ? AppColors.darkInkSoft : Colors.grey.shade400,
                ),
              ),
            ),
          // Earned check badge
          if (isEarned)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: badge.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: badge.color.withOpacity(0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, size: 8, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// Badge Detail Dialog - Centered
class _BadgeDetailDialog extends StatelessWidget {
  final Badge badge;
  final bool isEarned;
  final bool isDarkMode;

  const _BadgeDetailDialog({
    required this.badge,
    required this.isEarned,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close,
                  color: isDarkMode ? AppColors.darkInkSoft : Colors.grey.shade500,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(height: 8),

            // Badge Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isEarned
                    ? LinearGradient(
                  colors: [badge.color.withOpacity(0.25), badge.color.withOpacity(0.05)],
                )
                    : null,
                color: isEarned
                    ? null
                    : (isDarkMode ? AppColors.darkSurface : Colors.grey.shade100),
                border: Border.all(
                  color: isEarned ? badge.color : Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: isEarned
                    ? [BoxShadow(color: badge.color.withOpacity(0.3), blurRadius: 20)]
                    : null,
              ),
              child: Center(
                child: Text(badge.icon, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),

            // Badge Name
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.darkInk : AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),

            // Badge Description
            Text(
              isEarned
                  ? '🎉 Unlocked! You earned ${badge.points} points for this achievement.'
                  : (badge.requirement != null
                  ? '🔒 Reach ${badge.requirement} to unlock this badge.'
                  : 'Keep going to unlock this badge.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Got it button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEarned ? badge.color : AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Badge Model
class Badge {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final int points;
  final String? requirement;

  Badge({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.points = 0,
    this.requirement,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Badge &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Badge Calculator
class BadgeCalculator {
  final int maxStreak;
  final int currentStreak;
  final int timerStreak;
  final int totalFocusMinutes;

  BadgeCalculator({
    required this.maxStreak,
    required this.currentStreak,
    required this.timerStreak,
    required this.totalFocusMinutes,
  });

  BadgeResult calculateBadges() {
    final earned = <Badge>[];
    final locked = <Badge>[];
    int totalPoints = 0;

    final streakBadges = _getStreakBadges();
    for (var badge in streakBadges) {
      if (maxStreak >= badge.threshold) {
        earned.add(badge.badge);
        totalPoints += badge.badge.points;
      } else {
        locked.add(badge.badge);
      }
    }

    final timerStreakBadges = _getTimerStreakBadges();
    for (var badge in timerStreakBadges) {
      if (timerStreak >= badge.threshold) {
        earned.add(badge.badge);
        totalPoints += badge.badge.points;
      } else {
        locked.add(badge.badge);
      }
    }

    final focusBadges = _getFocusTimeBadges();
    for (var badge in focusBadges) {
      if (totalFocusMinutes >= badge.threshold) {
        earned.add(badge.badge);
        totalPoints += badge.badge.points;
      } else {
        locked.add(badge.badge);
      }
    }

    final uniqueEarned = earned.toSet().toList();
    final uniqueLocked = locked
        .where((b) => !uniqueEarned.any((e) => e.id == b.id))
        .toSet()
        .toList();

    return BadgeResult(
      earnedBadges: uniqueEarned,
      lockedBadges: uniqueLocked,
      totalPoints: totalPoints,
    );
  }

  List<StreakBadgeConfig> _getStreakBadges() {
    return [
      StreakBadgeConfig(threshold: 15, badge: Badge(id: 'streak_silver', name: 'Silver Streak', icon: '🥈', color: Colors.grey.shade400, points: 20, requirement: '15 days')),
      StreakBadgeConfig(threshold: 30, badge: Badge(id: 'streak_platinum', name: 'Platinum', icon: '💎', color: Colors.teal.shade300, points: 25, requirement: '30 days')),
      StreakBadgeConfig(threshold: 45, badge: Badge(id: 'streak_gold', name: 'Gold', icon: '🥇', color: Colors.amber.shade600, points: 25, requirement: '45 days')),
      StreakBadgeConfig(threshold: 60, badge: Badge(id: 'streak_diamond_v', name: 'Diamond V', icon: '💠', color: Colors.cyan.shade400, points: 60, requirement: '60 days')),
      StreakBadgeConfig(threshold: 75, badge: Badge(id: 'streak_diamond_iv', name: 'Diamond IV', icon: '💎', color: Colors.cyan.shade500, points: 60, requirement: '75 days')),
      StreakBadgeConfig(threshold: 90, badge: Badge(id: 'streak_diamond_iii', name: 'Diamond III', icon: '💎', color: Colors.cyan.shade600, points: 100, requirement: '90 days')),
      StreakBadgeConfig(threshold: 100, badge: Badge(id: 'streak_diamond_ii', name: 'Diamond II', icon: '👑', color: Colors.cyan.shade700, points: 200, requirement: '100 days')),
    ];
  }

  List<StreakBadgeConfig> _getTimerStreakBadges() {
    return [
      StreakBadgeConfig(threshold: 15, badge: Badge(id: 'timer_streak_15', name: 'Focus 15', icon: '🔥', color: Colors.orange.shade400, points: 20, requirement: '15 days')),
      StreakBadgeConfig(threshold: 30, badge: Badge(id: 'timer_streak_30', name: 'Focus 30', icon: '🔥', color: Colors.orange.shade500, points: 25, requirement: '30 days')),
      StreakBadgeConfig(threshold: 45, badge: Badge(id: 'timer_streak_45', name: 'Focus 45', icon: '🔥', color: Colors.orange.shade600, points: 25, requirement: '45 days')),
      StreakBadgeConfig(threshold: 60, badge: Badge(id: 'timer_streak_60', name: 'Focus 60', icon: '🔥', color: Colors.orange.shade700, points: 60, requirement: '60 days')),
      StreakBadgeConfig(threshold: 75, badge: Badge(id: 'timer_streak_75', name: 'Focus 75', icon: '🔥', color: Colors.orange.shade800, points: 60, requirement: '75 days')),
      StreakBadgeConfig(threshold: 90, badge: Badge(id: 'timer_streak_90', name: 'Focus 90', icon: '🔥', color: Colors.orange.shade900, points: 100, requirement: '90 days')),
      StreakBadgeConfig(threshold: 100, badge: Badge(id: 'timer_streak_100', name: 'Focus 100', icon: '⭐', color: Colors.amber.shade700, points: 200, requirement: '100 days')),
    ];
  }

  List<StreakBadgeConfig> _getFocusTimeBadges() {
    return [
      StreakBadgeConfig(threshold: 120, badge: Badge(id: 'focus_120', name: '2H Focus', icon: '⏱️', color: Colors.blue.shade400, points: 120, requirement: '120 min')),
      StreakBadgeConfig(threshold: 220, badge: Badge(id: 'focus_220', name: '3.6H Focus', icon: '⏱️', color: Colors.blue.shade500, points: 220, requirement: '220 min')),
      StreakBadgeConfig(threshold: 360, badge: Badge(id: 'focus_360', name: '6H Focus', icon: '⏱️', color: Colors.blue.shade600, points: 360, requirement: '360 min')),
      StreakBadgeConfig(threshold: 600, badge: Badge(id: 'focus_600', name: '10H Focus', icon: '⏱️', color: Colors.blue.shade700, points: 600, requirement: '600 min')),
      StreakBadgeConfig(threshold: 1440, badge: Badge(id: 'focus_1440', name: '24H Focus', icon: '⏱️', color: Colors.blue.shade800, points: 1440, requirement: '1440 min')),
    ];
  }
}

class StreakBadgeConfig {
  final int threshold;
  final Badge badge;
  StreakBadgeConfig({required this.threshold, required this.badge});
}

class BadgeResult {
  final List<Badge> earnedBadges;
  final List<Badge> lockedBadges;
  final int totalPoints;
  BadgeResult({required this.earnedBadges, required this.lockedBadges, required this.totalPoints});
}