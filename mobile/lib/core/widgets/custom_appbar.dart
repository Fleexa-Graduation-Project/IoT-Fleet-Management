import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../generated/l10n.dart';
import 'info_button.dart';

class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppbar({
    super.key,
    required this.title,
    this.detailsPage,
    this.showBackButton = true,
    this.infoButton = false,
    this.readAllButton = false,
    this.onReadAll,
  });

  final String? detailsPage;
  final String title;
  final bool showBackButton;
  final bool infoButton;
  final bool readAllButton;
  final VoidCallback? onReadAll;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: Styles.style20Medium,
      ),
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.white,
              ),
            )
          : null,
      actions: [
        if (detailsPage != null)
          IconButton(
            onPressed: () {
              GoRouter.of(context).pushNamed(detailsPage!);
            },
            icon: SvgPicture.asset('assets/icons/details_page.svg'),
          ),
        if (infoButton) const InfoButton(),
        if (readAllButton && onReadAll != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: onReadAll,
              tooltip: S.of(context).markAsRead,
              icon: const Icon(
                Icons.done_all_rounded,
                size: 24,
                color: AppColors.white,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
