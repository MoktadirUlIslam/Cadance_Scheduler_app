// lib/Components/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/data_provider.dart';
import '../utilites/app_colors.dart';

class CustomAppBar extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool showNotificationBadge;
  final bool isLocked;
  final VoidCallback? onMenuPressed;

  const CustomAppBar({
    super.key,
    this.scaffoldKey,
    this.showNotificationBadge = true,
    this.isLocked = false,
    this.onMenuPressed,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0), // Changed from -0.3 to 0.3
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dataProvider = context.watch<DataProvider>();
    final username = dataProvider.username ?? 'User';
    final greeting = dataProvider.getGreeting();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          // Menu button for drawer
          _buildMenuButton(context, isDark),
          const Spacer(), // Add Spacer to push content to the right
          // User avatar and greeting with slide animation
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildUserInfo(username, greeting, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: widget.isLocked
          ? null
          : widget.onMenuPressed ?? () {
        if (widget.scaffoldKey != null) {
          widget.scaffoldKey!.currentState?.openDrawer();
        } else {
          Scaffold.of(context).openDrawer();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.menu_rounded,
          size: 20,
          color: widget.isLocked
              ? (isDark ? Colors.grey.shade600 : Colors.grey.shade400)
              : (isDark ? AppColors.darkInk : AppColors.ink),
        ),
      ),
    );
  }

  Widget _buildUserInfo(String username, String greeting, bool isDark) {
    return Row(
      children: [
        // Greeting and username - moved to left side of this Row
        Column(
          crossAxisAlignment: CrossAxisAlignment.end, // Align text to the right
          children: [
            // Greeting text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                greeting,
                key: ValueKey<String>(greeting),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkInkSoft : AppColors.inkSoft,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Username
            Text(
              username,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isDark ? AppColors.darkInk : AppColors.ink,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Avatar
        _buildAvatar(username),
      ],
    );
  }

  Widget _buildAvatar(String username) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primaryLight.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}