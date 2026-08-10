// lib/screens/home/components/focus_quality.dart

import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';
import '../../../core/data_provider.dart';

class FocusQuality extends StatelessWidget {
  final DataProvider dataProvider;
  final bool isDarkMode;
  final Animation<double> fadeAnimation;

  const FocusQuality({
    super.key,
    required this.dataProvider,
    required this.isDarkMode,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    // Get REAL data from DataProvider
    final totalFocusMinutes = dataProvider.grandTotalFocusMinutes;
    final streak = dataProvider.streak;
    final longestStreak = dataProvider.longestStreak;
    final totalTasks = dataProvider.totalTasksDone;
    final totalCompleted = dataProvider.totalClassesDone +
        dataProvider.totalAssignmentsDone +
        dataProvider.totalLabReportsDone +
        dataProvider.totalExamsDone +
        dataProvider.totalOthersDone;

    // Calculate SMART metrics
    final completionRate = totalTasks > 0
        ? ((totalCompleted / totalTasks) * 100).round()
        : 0;

    // 1️⃣ FOCUS EFFICIENCY SCORE - How well you convert time into completed tasks
    final focusEfficiency = _calculateFocusEfficiency(totalFocusMinutes, totalCompleted);

    // 2️⃣ CONSISTENCY SCORE - How consistent you are (with decay)
    final consistencyScore = _calculateConsistency(streak, longestStreak);

    // 3️⃣ BALANCE SCORE - Work-Life balance indicator (with rest factor)
    final balanceScore = _calculateBalance(totalFocusMinutes, totalTasks, streak);

    // 4️⃣ PRODUCTIVITY SCORE - Overall performance
    final productivityScore = ((focusEfficiency * 0.4) +
        (consistencyScore * 0.3) +
        (balanceScore * 0.3)).round();

    // Get motivational message
    final message = _getMotivationalMessage(
      productivityScore,
      streak,
      completionRate,
      totalFocusMinutes,
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCard : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDarkMode ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Overall Score
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryLight,
                        AppColors.primaryLight.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Productivity Score',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
                        ),
                      ),
                      Text(
                        '$productivityScore%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? AppColors.darkInk : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getScoreColor(productivityScore).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getScoreColor(productivityScore).withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    _getScoreLabel(productivityScore),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getScoreColor(productivityScore),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4 Metric Cards in 2x2 Grid
            Row(
              children: [
                _buildMetricCard(
                  icon: Icons.speed,
                  value: '$focusEfficiency%',
                  label: 'Focus Efficiency',
                  subtitle: '${totalFocusMinutes} min total',
                  color: Colors.blue,
                  iconBg: Colors.blue.withOpacity(0.1),
                ),
                const SizedBox(width: 8),
                _buildMetricCard(
                  icon: Icons.trending_up,
                  value: '$consistencyScore%',
                  label: 'Consistency',
                  subtitle: '$streak day streak',
                  color: Colors.green,
                  iconBg: Colors.green.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMetricCard(
                  icon: Icons.balance,
                  value: '$balanceScore%',
                  label: 'Life Balance',
                  subtitle: '${totalTasks} tasks total',
                  color: Colors.purple,
                  iconBg: Colors.purple.withOpacity(0.1),
                ),
                const SizedBox(width: 8),
                _buildMetricCard(
                  icon: Icons.assignment_turned_in,
                  value: '$completionRate%',
                  label: 'Task Completion',
                  subtitle: '$totalCompleted/$totalTasks done',
                  color: Colors.orange,
                  iconBg: Colors.orange.withOpacity(0.1),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Motivational Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getScoreColor(productivityScore).withOpacity(0.08),
                    _getScoreColor(productivityScore).withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getScoreColor(productivityScore).withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _getEmoji(productivityScore),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? AppColors.darkInk : AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== CALCULATION METHODS ====================

  /// 1. Focus Efficiency: How well you convert time into completed tasks
  /// Uses a reasonable range (20-35 min per task) for optimal efficiency.
  int _calculateFocusEfficiency(int totalMinutes, int totalCompleted) {
    if (totalMinutes == 0 || totalCompleted == 0) return 0;

    final avgTimePerTask = totalMinutes / totalCompleted;

    // Ideal range: 20–35 minutes per task
    if (avgTimePerTask >= 20 && avgTimePerTask <= 35) {
      // Within ideal range → high score (85–95%)
      return 90 + ((35 - avgTimePerTask) / 15 * 5).round();
    } else if (avgTimePerTask < 20) {
      // Too fast → maybe rushed, score based on proportion
      final score = 50 + (avgTimePerTask / 20) * 30;
      return score.toInt().clamp(0, 100);
    } else {
      // Too slow → possible overthinking, score decays
      final score = 85 - ((avgTimePerTask - 35) / 25 * 40);
      return score.toInt().clamp(0, 100);
    }
  }

  /// 2. Consistency Score: Reflects both current streak and historical peak.
  /// Includes decay when current streak falls below longest.
  int _calculateConsistency(int currentStreak, int longestStreak) {
    if (currentStreak == 0) return 0;

    // Base score: up to 70 points based on current streak (capped at 30 days)
    double baseScore = (currentStreak / 30).clamp(0.0, 1.0) * 70;

    // Decay factor: if current streak is below best, apply penalty
    double decay = 1.0;
    if (longestStreak > currentStreak) {
      final ratio = currentStreak / longestStreak;
      decay = 0.5 + (ratio * 0.5); // from 50% to 100% based on ratio
    }

    // Bonus for exceptional long streaks (encourages maintaining)
    double bonus = 0.0;
    if (currentStreak >= 60) bonus = 10;
    else if (currentStreak >= 30) bonus = 5;

    final score = (baseScore * decay + bonus).round().clamp(0, 100);
    return score;
  }

  /// 3. Balance Score: Considers task rhythm, total time, and rest.
  int _calculateBalance(int totalMinutes, int totalTasks, int streak) {
    if (totalMinutes == 0 || totalTasks == 0) return 0;

    final avgTimePerTask = totalMinutes / totalTasks;

    // 1. Rhythm score: how well task times fit ideal range (20-35 min)
    double rhythmScore = 0.0;
    if (avgTimePerTask >= 20 && avgTimePerTask <= 35) {
      rhythmScore = 70.0;
    } else if (avgTimePerTask < 20) {
      rhythmScore = (avgTimePerTask / 20) * 70;
    } else {
      rhythmScore = 70.0 * (1 - ((avgTimePerTask - 35) / 60).clamp(0.0, 1.0));
    }

    // 2. Input score: penalize excessive total time (over 8 hours/day equivalent)
    // Using totalMinutes as total across all history - we approximate with totalTasks * avg
    final totalHours = totalMinutes / 60;
    double inputScore = 20.0;
    if (totalHours > 8) {
      inputScore = 20.0 * (1 - ((totalHours - 8) / 12).clamp(0.0, 1.0));
    }

    // 3. Rest score: encourage breaks and not overworking
    double restScore = 10.0;
    if (streak > 7) {
      // Penalize long streaks without breaks
      restScore = 10.0 * (1 - ((streak - 7) / 30).clamp(0.0, 1.0));
    }

    return (rhythmScore + inputScore + restScore).round().clamp(0, 100);
  }

  // ==================== UI HELPERS ====================

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required String subtitle,
    required Color color,
    required Color iconBg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.03)
              : Colors.grey.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 14,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.darkInk : AppColors.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 7,
                color: isDarkMode
                    ? AppColors.darkInkSoft.withOpacity(0.5)
                    : AppColors.inkSoft.withOpacity(0.5),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return '🌟 Excellent';
    if (score >= 60) return '💪 Good';
    if (score >= 40) return '📈 Improving';
    return '🎯 Needs Focus';
  }

  String _getEmoji(int score) {
    if (score >= 80) return '🌟';
    if (score >= 60) return '💪';
    if (score >= 40) return '📈';
    return '🎯';
  }

  String _getMotivationalMessage(int score, int streak, int completion, int minutes) {
    if (score >= 80) {
      if (streak >= 30) {
        return "🏆 Unstoppable! You're in the top 1% of focused individuals. Your consistency is legendary!";
      } else if (streak >= 14) {
        return "🔥 Amazing work! You've built a powerful habit. Keep this momentum going!";
      } else if (streak >= 7) {
        return "⭐ You're on fire! A 7-day streak is a huge achievement. You're building discipline!";
      }
      return "🌟 Outstanding! You're mastering focus. Your productivity is at elite levels!";
    } else if (score >= 60) {
      if (streak >= 7) {
        return "💪 Great consistency! You're building a powerful routine. Keep pushing forward!";
      } else if (completion >= 70) {
        return "🎯 You're completing most of your tasks! Try to maintain daily momentum.";
      }
      return "📈 You're on the right track! Small improvements each day lead to big results.";
    } else if (score >= 40) {
      if (streak == 0) {
        return "🚀 Start today! Complete one focus session to begin your streak. You've got this!";
      } else if (completion < 50) {
        return "🎯 Focus on completing what you start. Even 1 task completed is progress!";
      }
      return "📊 You're building momentum! Consistency is key - show up every day.";
    } else {
      if (minutes == 0) {
        return "🚀 Your journey starts now! Complete your first focus session today.";
      }
      return "💪 Every expert was once a beginner. Start small, dream big! You can do this!";
    }
  }
}