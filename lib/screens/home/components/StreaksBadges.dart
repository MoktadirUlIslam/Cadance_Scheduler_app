// lib/screens/home/components/streaks_badges.dart

import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';
import '../../../core/data_provider.dart';

class StreaksBadges extends StatelessWidget {
  final DataProvider dataProvider;
  final bool isDarkMode;
  final Animation<double> fadeAnimation;

  const StreaksBadges({
    super.key,
    required this.dataProvider,
    required this.isDarkMode,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final sessions = dataProvider.sessionHistory;
    final totalSessions = sessions.length;
    final totalMinutes = dataProvider.grandTotalFocusMinutes;
    final streak = dataProvider.streak;
    final longestStreak = dataProvider.longestStreak;

    // Use the maximum of streak and longestStreak for display
    final effectiveLongestStreak = longestStreak > streak ? longestStreak : streak;

    // Calculate badges
    final badges = _calculateBadges(
      totalSessions: totalSessions,
      totalMinutes: totalMinutes,
      streak: streak,
      longestStreak: effectiveLongestStreak,
    );

    final unlockedCount = badges.where((b) => b.unlocked).length;
    final totalCount = badges.length;

    // Calculate rows needed (6 per row)
    final rowsNeeded = (badges.length / 6).ceil();

    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCard : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDarkMode ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact streak header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🔥 $streak Day Streak',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'Best: ${effectiveLongestStreak > 0 ? "$effectiveLongestStreak days" : "Start your streak!"} • $unlockedCount/$totalCount badges',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                if (streak >= 7)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      streak >= 30 ? '🔥🔥🔥' : '🔥🔥',
                      style: const TextStyle(fontSize: 9),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Compact badges grid - 6 per row with fixed height
            SizedBox(
              height: rowsNeeded * 58.0,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 0.9,
                ),
                itemCount: badges.length,
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  return _CompactBadgeCard(
                    badge: badge,
                    isDarkMode: isDarkMode,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BadgeModel> _calculateBadges({
    required int totalSessions,
    required int totalMinutes,
    required int streak,
    required int longestStreak,
  }) {
    final badges = <BadgeModel>[];

    // ─── SESSION BADGES ───
    badges.add(BadgeModel(
      icon: Icons.play_circle,
      label: 'Start',
      value: '🎯',
      color: Colors.green,
      unlocked: totalSessions >= 1,
      progress: totalSessions >= 1 ? 1.0 : totalSessions / 1,
    ));

    badges.add(BadgeModel(
      icon: Icons.emoji_events,
      label: '10',
      value: '🎯',
      color: Colors.blue,
      unlocked: totalSessions >= 10,
      progress: totalSessions >= 10 ? 1.0 : totalSessions / 10,
    ));

    badges.add(BadgeModel(
      icon: Icons.stars,
      label: '25',
      value: '⭐',
      color: Colors.purple,
      unlocked: totalSessions >= 25,
      progress: totalSessions >= 25 ? 1.0 : totalSessions / 25,
    ));

    badges.add(BadgeModel(
      icon: Icons.workspace_premium,
      label: '50',
      value: '🏆',
      color: Colors.amber,
      unlocked: totalSessions >= 50,
      progress: totalSessions >= 50 ? 1.0 : totalSessions / 50,
    ));

    badges.add(BadgeModel(
      icon: Icons.emoji_events,
      label: '100',
      value: '👑',
      color: Colors.amber[700] ?? Colors.amber,
      unlocked: totalSessions >= 100,
      progress: totalSessions >= 100 ? 1.0 : totalSessions / 100,
    ));

    // ─── TIME BADGES ───
    badges.add(BadgeModel(
      icon: Icons.timer,
      label: '1H',
      value: '⏱️',
      color: Colors.teal,
      unlocked: totalMinutes >= 60,
      progress: totalMinutes >= 60 ? 1.0 : totalMinutes / 60,
    ));

    badges.add(BadgeModel(
      icon: Icons.timer,
      label: '10H',
      value: '⏰',
      color: Colors.indigo,
      unlocked: totalMinutes >= 600,
      progress: totalMinutes >= 600 ? 1.0 : totalMinutes / 600,
    ));

    badges.add(BadgeModel(
      icon: Icons.timer,
      label: '50H',
      value: '🕐',
      color: Colors.deepPurple,
      unlocked: totalMinutes >= 3000,
      progress: totalMinutes >= 3000 ? 1.0 : totalMinutes / 3000,
    ));

    badges.add(BadgeModel(
      icon: Icons.timer,
      label: '100H',
      value: '⌛',
      color: Colors.pink,
      unlocked: totalMinutes >= 6000,
      progress: totalMinutes >= 6000 ? 1.0 : totalMinutes / 6000,
    ));

    // ─── STREAK BADGES ───
    badges.add(BadgeModel(
      icon: Icons.local_fire_department,
      label: '3D',
      value: '🔥',
      color: Colors.orange,
      unlocked: longestStreak >= 3,
      progress: longestStreak >= 3 ? 1.0 : longestStreak / 3,
    ));

    badges.add(BadgeModel(
      icon: Icons.local_fire_department,
      label: '7D',
      value: '🔥🔥',
      color: Colors.deepOrange,
      unlocked: longestStreak >= 7,
      progress: longestStreak >= 7 ? 1.0 : longestStreak / 7,
    ));

    badges.add(BadgeModel(
      icon: Icons.local_fire_department,
      label: '14D',
      value: '🔥🔥🔥',
      color: Colors.red,
      unlocked: longestStreak >= 14,
      progress: longestStreak >= 14 ? 1.0 : longestStreak / 14,
    ));

    badges.add(BadgeModel(
      icon: Icons.local_fire_department,
      label: '30D',
      value: '⚡',
      color: Colors.red.shade900,
      unlocked: longestStreak >= 30,
      progress: longestStreak >= 30 ? 1.0 : longestStreak / 30,
    ));

    badges.add(BadgeModel(
      icon: Icons.local_fire_department,
      label: '60D',
      value: '🌟',
      color: Colors.amber.shade900,
      unlocked: longestStreak >= 60,
      progress: longestStreak >= 60 ? 1.0 : longestStreak / 60,
    ));

    // ─── SPECIAL BADGES ───
    badges.add(BadgeModel(
      icon: Icons.rocket,
      label: 'Rocket',
      value: '🚀',
      color: Colors.cyan,
      unlocked: totalSessions >= 5 && longestStreak >= 5,
      progress: ((totalSessions >= 5 ? 1.0 : totalSessions / 5) +
          (longestStreak >= 5 ? 1.0 : longestStreak / 5)) / 2,
    ));

    badges.add(BadgeModel(
      icon: Icons.directions_run,
      label: 'Marathon',
      value: '🏃',
      color: Colors.lime,
      unlocked: totalSessions >= 30 && longestStreak >= 7,
      progress: ((totalSessions >= 30 ? 1.0 : totalSessions / 30) +
          (longestStreak >= 7 ? 1.0 : longestStreak / 7)) / 2,
    ));

    badges.add(BadgeModel(
      icon: Icons.star,
      label: 'Master',
      value: '⭐',
      color: Colors.amber[700] ?? Colors.amber,
      unlocked: totalSessions >= 100 && longestStreak >= 30,
      progress: ((totalSessions >= 100 ? 1.0 : totalSessions / 100) +
          (longestStreak >= 30 ? 1.0 : longestStreak / 30)) / 2,
    ));

    badges.add(BadgeModel(
      icon: Icons.auto_awesome,
      label: 'Legend',
      value: '🏆',
      color: Colors.purple,
      unlocked: totalSessions >= 500 && longestStreak >= 100,
      progress: ((totalSessions >= 500 ? 1.0 : totalSessions / 500) +
          (longestStreak >= 100 ? 1.0 : longestStreak / 100)) / 2,
    ));

    return badges;
  }
}

class BadgeModel {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool unlocked;
  final double progress;

  BadgeModel({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.unlocked,
    this.progress = 0.0,
  });
}

class _CompactBadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final bool isDarkMode;

  const _CompactBadgeCard({
    required this.badge,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(badge.unlocked ? 0.08 : 0.03)
            : Colors.grey.withOpacity(badge.unlocked ? 0.08 : 0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badge.unlocked
              ? badge.color.withOpacity(0.25)
              : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
          width: badge.unlocked ? 1.0 : 0.5,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock icon for locked badges - using Container instead of Positioned
              if (!badge.unlocked)
                Container(
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(top: 2, right: 2),
                  child: Icon(
                    Icons.lock_outline,
                    size: 7,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: badge.unlocked
                      ? badge.color.withOpacity(0.1)
                      : (isDarkMode ? Colors.white.withOpacity(0.02) : Colors.grey.withOpacity(0.02)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  badge.icon,
                  size: 14,
                  color: badge.unlocked ? badge.color : Colors.grey.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                badge.value,
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: badge.unlocked
                      ? (isDarkMode ? Colors.white : Colors.black87)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              Text(
                badge.label,
                style: TextStyle(
                  fontSize: 5.5,
                  color: badge.unlocked
                      ? (isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft)
                      : Colors.grey.withOpacity(0.3),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          // Progress indicator - Positioned is now properly inside Stack
          if (!badge.unlocked && badge.progress > 0 && badge.progress < 1)
            Positioned(
              bottom: 2,
              left: 3,
              right: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: LinearProgressIndicator(
                  value: badge.progress.clamp(0.0, 1.0),
                  backgroundColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                  color: badge.color.withOpacity(0.5),
                  minHeight: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}