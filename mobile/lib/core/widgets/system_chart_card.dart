import 'package:flutter/material.dart';

import 'custom_container.dart';
import '../utils/constants/app_colors.dart';
import '../utils/constants/styles.dart';

class SystemChartCard extends StatelessWidget {
  const SystemChartCard({
    super.key,
    required this.title,
    required this.insight,
    required this.timeFilter,
    this.cardHeight = 240,
  });

  final String title;
  final Widget insight;
  final Widget timeFilter;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Styles.style12Medium.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const Spacer(),
                timeFilter,
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: cardHeight,
              width: double.infinity,
              child: insight,
            ),
          ],
        ),
      ),
    );
  }
}
