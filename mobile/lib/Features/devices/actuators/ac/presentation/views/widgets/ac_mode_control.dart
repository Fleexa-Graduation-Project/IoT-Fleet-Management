import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../../../../core/utils/constants/app_strings.dart';
import '../../../../../../../../generated/l10n.dart';
import '../../../data/mode_data.dart';

class AcModeControl extends StatelessWidget {
  const AcModeControl({
    super.key,
    required this.acMode,
    required this.onToggle,
  });

  final ACMode acMode;
  final ValueChanged<ACMode>? onToggle;

  @override
  Widget build(BuildContext context) {
    final List<ModeData> modes = [
      ModeData(
        mode: ACMode.heating,
        label: S.of(context).modeHeating,
        iconPath: 'assets/icons/ac_heating.svg',
      ),
      ModeData(
        mode: ACMode.cooling,
        label: S.of(context).modeCooling,
        iconPath: 'assets/icons/ac_cooling.svg',
      ),
      ModeData(
        mode: ACMode.dry,
        label: S.of(context).modeDry,
        iconPath: 'assets/icons/ac_dry.svg',
      ),
      ModeData(
        mode: ACMode.fanOnly,
        label: S.of(context).modeFanOnly,
        iconPath: 'assets/icons/ac_airwaves.svg',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).mode,
          style: Styles.style18Medium,
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: modes.map((modeData) {
              final bool isSelected = modeData.mode == acMode;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onToggle?.call(modeData.mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.wineRed : Colors.transparent,
                      borderRadius: BorderRadius.circular(30.r),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.wineRed : AppColors.dimGray,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          modeData.iconPath,
                          width: 20,
                          height: 20,
                          color:
                              isSelected ? AppColors.white : AppColors.ashGray,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          modeData.label,
                          style: Styles.style14Regular.copyWith(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.ashGray,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
