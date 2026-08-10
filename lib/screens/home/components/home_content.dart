// lib/screens/home/home_content.dart

import 'package:flutter/material.dart';
import 'package:pomodoro/screens/home/components/stats_row.dart';
import 'package:pomodoro/screens/home/components/upcoming_tasks_list.dart';
import 'package:provider/provider.dart';
import '../../../core/data_provider.dart';
import '../../../widgets/section_header.dart';
import '../../Event_Maneger/providers/event_provider.dart';
import 'FocusQuality.dart';
import 'StreaksBadges.dart';
import 'TaskManagerStatsRow.dart';
import 'date_time_header.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Create fade animation - use a simple animation since we're not in a StatefulWidget
    // This is a placeholder - the actual animation will be handled by the parent
    final animation = const AlwaysStoppedAnimation(1.0);

    return Consumer2<DataProvider, EventProvider>(
      builder: (context, dataProvider, eventProvider, child) {
        final bottomPadding = MediaQuery.of(context).padding.bottom + 100;

        // Calculate stats once
        final stats = _calculateStats(dataProvider, eventProvider);

        return CustomScrollView(
          slivers: [
            // Date & Time Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: DateTimeHeader(
                  fadeAnimation: animation,
                ),
              ),
            ),

            // Stats Section
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: StatsRow(
                      totalFocusMinutes: stats.totalFocusMinutes,
                      totalCompletedTasks: stats.totalCompleted,
                      totalFocusSessions: stats.totalFocusSessions,
                      streak: stats.streak,
                      fadeAnimation: animation,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: TaskManagerStatsRow(
                      dataProvider: dataProvider,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  _buildDivider(isDarkMode),
                ],
              ),
            ),

            // Today's Tasks & Events
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: TodayTasksAndEvents(
                      isDarkMode: isDarkMode,
                      fadeAnimation: animation, // ✅ PASS THE PARAMETER
                    ),
                  ),
                  _buildDivider(isDarkMode),
                ],
              ),
            ),

            // Focus Quality Metrics
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: SectionHeader(
                      title: '⏱️ Focus Quality Metrics',
                      action: null,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: FocusQuality(
                      dataProvider: dataProvider,
                      isDarkMode: isDarkMode,
                      fadeAnimation: animation,
                    ),
                  ),
                  _buildDivider(isDarkMode),
                ],
              ),
            ),

            // Streaks & Badges
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: SectionHeader(
                      title: '🏆 Streaks & Badges',
                      action: null,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: StreaksBadges(
                      dataProvider: dataProvider,
                      isDarkMode: isDarkMode,
                      fadeAnimation: animation,
                    ),
                  ),
                  _buildDivider(isDarkMode),
                ],
              ),
            ),

            // Bottom Spacer
            SliverToBoxAdapter(
              child: SizedBox(height: bottomPadding),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Divider(
        color: isDarkMode
            ? Colors.white.withOpacity(0.08)
            : Colors.grey.shade300,
        thickness: 1,
        height: 20,
        indent: 16,
        endIndent: 16,
      ),
    );
  }

  _StatsData _calculateStats(DataProvider dataProvider, EventProvider eventProvider) {
    final allSessions = dataProvider.sessionHistory;
    final completedFocusSessions = allSessions
        .where((session) => session['isCompleted'] == true)
        .length;
    final pastEventCount = eventProvider.getAllEvents()
        .where((e) => e.isPast)
        .length;

    return _StatsData(
      totalFocusMinutes: dataProvider.grandTotalFocusMinutes,
      totalCompleted: completedFocusSessions + pastEventCount,
      totalFocusSessions: dataProvider.grandTotalTaskCount,
      streak: dataProvider.streak,
    );
  }
}

class _StatsData {
  final int totalFocusMinutes;
  final int totalCompleted;
  final int totalFocusSessions;
  final int streak;

  _StatsData({
    required this.totalFocusMinutes,
    required this.totalCompleted,
    required this.totalFocusSessions,
    required this.streak,
  });
}