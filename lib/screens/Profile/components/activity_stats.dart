// lib/screens/Profile/components/contribution_graph.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/data_provider.dart';
import '../../../utilites/app_colors.dart';

class ContributionGraph extends StatefulWidget {
  final bool isDarkMode;

  const ContributionGraph({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<ContributionGraph> createState() => _ContributionGraphState();
}

class _ContributionGraphState extends State<ContributionGraph> {
  Map<String, int> _dailyActivity = {};
  DateTime _currentMonth = DateTime.now();
  bool _isLoading = true;
  int _totalActivities = 0;
  int _totalDays = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final dataProvider = context.read<DataProvider>();
      final stats = await dataProvider.getActivityStats();
      final dailyDetails = Map<String, dynamic>.from(stats['dailyDetails'] ?? {});

      // Build daily activity map
      _dailyActivity = {};
      _totalActivities = stats['totalActivities'] ?? 0;
      _totalDays = stats['totalActiveDays'] ?? 0;

      dailyDetails.forEach((key, value) {
        _dailyActivity[key] = value['count'] ?? 0;
      });

      print('✅ Loaded ${_dailyActivity.length} days of activity data');
    } catch (e) {
      print('❌ Error loading contribution data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }

    final daysInMonth = _getDaysInMonth(_currentMonth);
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday - 1; // 0 = Monday, 6 = Sunday
    final monthName = DateFormat('MMMM yyyy').format(_currentMonth);

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
          // Header
          Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 18,
                color: AppColors.primaryLight,
              ),
              const SizedBox(width: 8),
              Text(
                'Activites',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? AppColors.darkInk : AppColors.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_totalDays days',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Month Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: Icon(
                  Icons.chevron_left,
                  color: widget.isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 24,
              ),
              Text(
                monthName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isDarkMode ? AppColors.darkInk : AppColors.ink,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: Icon(
                  Icons.chevron_right,
                  color: widget.isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Day headers (Mon, Tue, Wed, etc.)
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((day) => Expanded(
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: widget.isDarkMode
                      ? AppColors.darkInkSoft
                      : AppColors.inkSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 4),

          // Contribution grid - Using fixed size to avoid NaN
          SizedBox(
            height: 160, // Fixed height for 6 rows
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1.1,
              ),
              itemCount: 42, // 6 rows x 7 days
              itemBuilder: (context, index) {
                final day = index - firstWeekday + 1;
                final date = DateTime(_currentMonth.year, _currentMonth.month, day);
                final dateKey = _formatDateKey(date);
                final count = _dailyActivity[dateKey] ?? 0;
                final isValidDay = day >= 1 && day <= daysInMonth;

                return Container(
                  decoration: BoxDecoration(
                    color: isValidDay ? _getColorForCount(count) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: isValidDay && count > 0
                        ? Border.all(
                      color: _getColorForCount(count).withOpacity(0.5),
                      width: 0.5,
                    )
                        : null,
                  ),
                  child: Center(
                    child: isValidDay && count > 0
                        ? Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 8,
                        color: count > 3
                            ? Colors.white
                            : widget.isDarkMode
                            ? AppColors.darkInk
                            : AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Legend
          _buildLegend(),
          const SizedBox(height: 4),

          // Stats
          _buildStats(),
        ],
      ),
    );
  }

  Color _getColorForCount(int count) {
    if (count == 0) {
      return widget.isDarkMode
          ? AppColors.darkSurface
          : Colors.grey.shade100;
    }
    if (count <= 2) {
      return widget.isDarkMode
          ? AppColors.primaryLight.withOpacity(0.3)
          : AppColors.primaryLight.withOpacity(0.2);
    }
    if (count <= 5) {
      return widget.isDarkMode
          ? AppColors.primaryLight.withOpacity(0.6)
          : AppColors.primaryLight.withOpacity(0.5);
    }
    if (count <= 10) {
      return widget.isDarkMode
          ? AppColors.primaryLight.withOpacity(0.8)
          : AppColors.primaryLight.withOpacity(0.75);
    }
    return AppColors.primaryLight;
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Less',
          style: TextStyle(
            fontSize: 10,
            color: widget.isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
          ),
        ),
        const SizedBox(width: 4),
        _buildLegendItem(0),
        _buildLegendItem(1),
        _buildLegendItem(3),
        _buildLegendItem(6),
        _buildLegendItem(11),
        const SizedBox(width: 4),
        Text(
          'More',
          style: TextStyle(
            fontSize: 10,
            color: widget.isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: _getColorForCount(count),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: widget.isDarkMode
              ? AppColors.darkBorder.withOpacity(0.3)
              : Colors.grey.shade300,
          width: 0.5,
        ),
      ),
    );
  }

  Widget _buildStats() {
    // Calculate average safely
    final avg = _dailyActivity.isEmpty
        ? 0.0
        : (_totalActivities / _dailyActivity.length);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatChip(
          'Total',
          _totalActivities.toString(),
          Icons.trending_up,
        ),
        const SizedBox(width: 16),
        _buildStatChip(
          'Days',
          _dailyActivity.length.toString(),
          Icons.calendar_today,
        ),
        const SizedBox(width: 16),
        _buildStatChip(
          'Avg',
          avg.toStringAsFixed(1),
          Icons.show_chart,
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDarkMode ? AppColors.darkBorder : Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.primaryLight,
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10,
              color: widget.isDarkMode ? AppColors.darkInkSoft : AppColors.inkSoft,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? AppColors.darkInk : AppColors.ink,
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
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? AppColors.darkSurface : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 120,
                height: 18,
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? AppColors.darkSurface : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.isDarkMode ? AppColors.darkSurface : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1.1,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? AppColors.darkSurface : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}