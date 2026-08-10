// lib/screens/home/components/productivity_insights.dart

import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';
import '../../../core/data_provider.dart';

class ProductivityInsights extends StatelessWidget {
  final DataProvider dataProvider;
  final bool isDarkMode;
  final Animation<double> fadeAnimation;

  const ProductivityInsights({
    super.key,
    required this.dataProvider,
    required this.isDarkMode,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final totalSessions = dataProvider.grandTotalTaskCount;
    final totalMinutes = dataProvider.grandTotalFocusMinutes;
    final streak = dataProvider.streak;
    final history = dataProvider.history;

    // Calculate average daily focus
    final activeDays = history.where((stat) => stat.totalFocusMinutes > 0).length;
    final avgDailyMinutes = activeDays > 0 ? totalMinutes / activeDays : 0;

    // Calculate best day
    final bestDay = history.isNotEmpty
        ? history.reduce((a, b) => a.totalFocusMinutes > b.totalFocusMinutes ? a : b)
        : null;

    // Calculate completion rate
    final completedSessions = dataProvider.sessionHistory
        .where((s) => s['isCompleted'] == true)
        .length;
    final completionRate = totalSessions > 0
        ? (completedSessions / totalSessions) * 100
        : 0;

    final insights = [
      _InsightItem(
        icon: Icons.trending_up,
        color: Colors.green,
        title: 'Avg. Daily Focus',
        value: '${avgDailyMinutes.round()} min',
        subtitle: 'Average daily focus time',
      ),
      _InsightItem(
        icon: Icons.stars,
        color: Colors.amber,
        title: 'Best Day',
        value: bestDay != null ? '${bestDay.totalFocusMinutes} min' : '0 min',
        subtitle: bestDay != null
            ? '${_formatDate(bestDay.date)}'
            : 'No data available',
      ),
      _InsightItem(
        icon: Icons.check_circle,
        color: Colors.blue,
        title: 'Completion Rate',
        value: '${completionRate.round()}%',
        subtitle: 'Sessions completed',
      ),
      _InsightItem(
        icon: Icons.local_fire_department,
        color: Colors.orange,
        title: 'Current Streak',
        value: '$streak days',
        subtitle: 'Keep it going! 🔥',
      ),
    ];

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
          children: [
            // Overall stats summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryLight.withOpacity(0.1),
                    AppColors.primaryLight.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    'Total Focus',
                    '${totalMinutes ~/ 60}h ${totalMinutes % 60}m',
                    Icons.timer,
                    AppColors.primaryLight,
                  ),
                  _buildSummaryItem(
                    'Sessions',
                    '$totalSessions',
                    Icons.play_circle,
                    AppColors.accentLight,
                  ),
                  _buildSummaryItem(
                    'Active Days',
                    '$activeDays',
                    Icons.calendar_today,
                    AppColors.purple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Insights grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.4,
              ),
              itemCount: insights.length,
              itemBuilder: (context, index) {
                final insight = insights[index];
                return _InsightCard(
                  insight: insight,
                  isDarkMode: isDarkMode,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.darkInk : AppColors.ink,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _InsightItem {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;

  _InsightItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });
}

class _InsightCard extends StatelessWidget {
  final _InsightItem insight;
  final bool isDarkMode;

  const _InsightCard({
    required this.insight,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                insight.icon,
                size: 16,
                color: insight.color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            insight.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.darkInk : AppColors.ink,
            ),
          ),
          Text(
            insight.subtitle,
            style: TextStyle(
              fontSize: 9,
              color: isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}