/// Responsive shell widget that provides Bottom Navigation on mobile
/// and Navigation Rail on tablet/desktop
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../utils/responsive_utils.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

class ResponsiveShell extends StatelessWidget {
  final Widget child;

  const ResponsiveShell({super.key, required this.child});

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    for (int i = 0; i < AppDestination.values.length; i++) {
      if (location == AppDestination.values[i].path) {
        return i;
      }
      // Check for nested routes
      if (location.startsWith(AppDestination.values[i].path) &&
          AppDestination.values[i].path != '/') {
        return i;
      }
    }
    return 0; // Default to dashboard
  }

  void _onDestinationSelected(BuildContext context, int index) {
    final destination = AppDestination.values[index];
    context.go(destination.path);
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    final currentIndex = _getCurrentIndex(context);

    return switch (deviceType) {
      DeviceType.mobile => _MobileLayout(
        currentIndex: currentIndex,
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
        child: child,
      ),
      DeviceType.tablet => _TabletLayout(
        currentIndex: currentIndex,
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
        child: child,
      ),
      DeviceType.desktop => _DesktopLayout(
        currentIndex: currentIndex,
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
        child: child,
      ),
    };
  }
}

/// Mobile layout with bottom navigation bar
class _MobileLayout extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const _MobileLayout({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingSm,
              vertical: AppConstants.spacingXs,
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: AppColors.primary.withValues(alpha: 0.1),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: AppDestination.values.map((dest) {
                return NavigationDestination(
                  icon: Icon(dest.icon),
                  selectedIcon: Icon(
                    dest.selectedIcon,
                    color: AppColors.primary,
                  ),
                  label: dest.label,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tablet layout with navigation rail (icons only)
class _TabletLayout extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const _TabletLayout({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(5, 0),
                ),
              ],
            ),
            child: NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              backgroundColor: Colors.transparent,
              labelType: NavigationRailLabelType.all,
              indicatorColor: AppColors.primary.withValues(alpha: 0.1),
              leading: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingLg,
                ),
                child: _AppLogo(compact: true),
              ),
              destinations: AppDestination.values.map((dest) {
                return NavigationRailDestination(
                  icon: Icon(dest.icon),
                  selectedIcon: Icon(
                    dest.selectedIcon,
                    color: AppColors.primary,
                  ),
                  label: Text(dest.label),
                );
              }).toList(),
            ),
          ),
          // Content
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Desktop layout with expanded navigation rail
class _DesktopLayout extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const _DesktopLayout({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Expanded Navigation Drawer
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(5, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Logo
                Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingLg),
                  child: _AppLogo(compact: false),
                ),
                const Divider(),
                // Navigation items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.spacingMd,
                    ),
                    itemCount: AppDestination.values.length,
                    itemBuilder: (context, index) {
                      final dest = AppDestination.values[index];
                      final isSelected = index == currentIndex;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingMd,
                          vertical: AppConstants.spacingXs,
                        ),
                        child: Material(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMd,
                          ),
                          child: InkWell(
                            onTap: () => onDestinationSelected(index),
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusMd,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spacingMd,
                                vertical: AppConstants.spacingSm + 4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? dest.selectedIcon : dest.icon,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.neutral500,
                                  ),
                                  const SizedBox(width: AppConstants.spacingMd),
                                  Text(
                                    dest.label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.neutral700,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// App logo widget
class _AppLogo extends StatelessWidget {
  final bool compact;

  const _AppLogo({required this.compact});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        child: const Center(
          child: Text(
            'A',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: const Center(
            child: Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Akuntansi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral900,
              ),
            ),
            Text(
              'App',
              style: TextStyle(fontSize: 12, color: AppColors.neutral500),
            ),
          ],
        ),
      ],
    );
  }
}
