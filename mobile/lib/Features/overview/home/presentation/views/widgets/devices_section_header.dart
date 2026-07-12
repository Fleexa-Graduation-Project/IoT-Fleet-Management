import 'package:flutter/material.dart';

import '../../../../../../core/utils/constants/app_strings.dart';
import '../../../../../../core/utils/constants/styles.dart';
import '../../../../../../generated/l10n.dart';
import 'devices_filter_dropdown.dart';

class DevicesSectionHeader extends StatelessWidget {
  const DevicesSectionHeader({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  final DeviceFilter currentFilter;
  final ValueChanged<DeviceFilter?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          S.of(context).homeMyDevices,
          style: Styles.style18Medium,
        ),
        const Spacer(),
        DevicesFilterDropdown(
          currentFilter: currentFilter,
          onChanged: onFilterChanged,
        ),
      ],
    );
  }
}
