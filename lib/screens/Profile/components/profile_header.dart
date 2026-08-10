import 'package:flutter/material.dart';
import '../../../core/data_provider.dart';
import '../../../utilites/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final DataProvider dataProvider;
  final bool isDarkMode;

  const ProfileHeader({
    super.key,
    required this.dataProvider,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryLight, AppColors.accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: Text(
                dataProvider.username?.isNotEmpty == true
                    ? dataProvider.username![0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dataProvider.username ?? 'User',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dataProvider.email ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}