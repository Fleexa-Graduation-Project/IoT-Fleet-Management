import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomRefreshIndicator extends StatelessWidget {
  const CustomRefreshIndicator(
      {super.key, required this.child, required this.onRefresh});
  final Widget child;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        color: AppColors.darkMaroon,
        backgroundColor: AppColors.davysGray,
        onRefresh: onRefresh,
        child: child);
  }
}
