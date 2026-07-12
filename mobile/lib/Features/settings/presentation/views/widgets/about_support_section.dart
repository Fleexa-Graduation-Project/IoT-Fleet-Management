import 'package:fleexa/Features/settings/data/models/support_topic.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AboutSupportSection extends StatelessWidget {
  const AboutSupportSection({
    super.key,
    required this.section,
  });

  final TopicSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoalBlack,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          iconColor: AppColors.white,
          collapsedIconColor: AppColors.coolGray,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.darkGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              section.icon,
              color: AppColors.white,
              size: 20,
            ),
          ),
          title: Text(section.title, style: Styles.style16Medium),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              section.summary,
              style: Styles.style14Regular.copyWith(
                color: AppColors.coolGray,
                height: 1.3,
              ),
            ),
          ),
          children: [
            const SizedBox(height: 8),
            ...section.points.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.darkGray,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: Styles.style12Medium.copyWith(
                              color: AppColors.white80,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: Styles.style14Regular.copyWith(
                              color: AppColors.white80,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
