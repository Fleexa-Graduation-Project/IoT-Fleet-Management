import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../../overview/home/presentation/views/widgets/custom_switch.dart';

class UpperContainerContent extends StatelessWidget {
  const UpperContainerContent({
    super.key,
    required this.isLocked,
    required this.onToggle,
  });

  final bool isLocked;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          isLocked ? 'assets/icons/lock.svg' : 'assets/icons/unlock.svg',
          width: 18,
          height: 18,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 12),
        Text(
          isLocked
              ? S.of(context).doorLockedStatus
              : S.of(context).doorUnlockedStatus,
          style: Styles.style14Medium.copyWith(
            color: AppColors.white,
          ),
        ),
        const Spacer(),
        CustomSwitch(
          isOn: isLocked,
          onToggle: onToggle,
        )
      ],
    );
  }
}
