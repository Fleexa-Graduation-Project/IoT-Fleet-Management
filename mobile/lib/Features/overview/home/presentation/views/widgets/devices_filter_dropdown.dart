import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/utils/constants/app_colors.dart';
import '../../../../../../core/utils/constants/app_strings.dart';
import '../../../../../../generated/l10n.dart';

class DevicesFilterDropdown extends StatelessWidget {
  const DevicesFilterDropdown({
    super.key,
    required this.currentFilter,
    required this.onChanged,
  });

  final DeviceFilter currentFilter;
  final Function(DeviceFilter) onChanged;

  String _getFilterText(BuildContext context, DeviceFilter filter) {
    switch (filter) {
      case DeviceFilter.all:
        return S.of(context).homeAllDevices;
      case DeviceFilter.sensors:
        return S.of(context).homeSensors;
      case DeviceFilter.actuators:
        return S.of(context).homeActuators;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = DeviceFilter.values;

    return PopupMenuButton<DeviceFilter>(
      initialValue: currentFilter,
      onSelected: onChanged,
      color: AppColors.charcoalBlack,
      shadowColor: AppColors.black,
      elevation: 4,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.charcoalBlack,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getFilterText(context, currentFilter),
              style: Styles.style12Medium,
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.white,
              size: 20,
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        return filters.map((filter) {
          return PopupMenuItem<DeviceFilter>(
            value: filter,
            child: Text(
              _getFilterText(context, filter),
              style: Styles.style12Medium,
            ),
          );
        }).toList();
      },
    );
  }
}
