import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/utils/constants/app_colors.dart';
import '../../../core/utils/constants/styles.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.darkGray,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,

        // Theme customization
        backgroundColor: AppColors.charcoalBlack,
        selectedItemColor: AppColors.crimsonRed,
        unselectedItemColor: AppColors.lightGray,
        selectedLabelStyle: Styles.style12Medium,
        unselectedLabelStyle: Styles.style12Medium,
        showUnselectedLabels: true,

        type: BottomNavigationBarType.fixed,

        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset('assets/icons/home_tab_off.svg'),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset('assets/icons/home_tab_on.svg'),
            ),
            label: S.of(context).home,
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset('assets/icons/system_tab_off.svg'),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset('assets/icons/system_tab_on.svg'),
            ),
            label: S.of(context).system,
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset('assets/icons/settings_tab_off.svg'),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset('assets/icons/settings_tab_on.svg'),
            ),
            label: S.of(context).settings,
          ),
        ],
      ),
    );
  }
}
