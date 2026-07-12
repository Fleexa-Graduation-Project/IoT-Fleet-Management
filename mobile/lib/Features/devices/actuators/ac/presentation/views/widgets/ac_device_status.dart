import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/ac_pic.dart';
import 'package:flutter/material.dart';
import '../../../../../../../../core/utils/constants/app_colors.dart';
import '../../../../../../../../core/utils/constants/app_strings.dart';
import '../../../../../../../../core/utils/constants/styles.dart';
import '../../../../../../../../generated/l10n.dart';

class AcDeviceStatus extends StatelessWidget {
  const AcDeviceStatus({
    super.key,
    required this.selectedMode,
    required this.temperature,
  });

  final ACMode selectedMode;
  final int temperature;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AcPic(),
        // const SizedBox(height: 8),
        Text(
          '$temperature°',
          style: Styles.style36Medium,
        ),
        const SizedBox(height: 4),
        Text(
          switch (selectedMode) {
            ACMode.cooling => S.of(context).modeCooling,
            ACMode.heating => S.of(context).modeHeating,
            ACMode.dry => S.of(context).modeDry,
            ACMode.fanOnly => S.of(context).modeFanOnly,
          },
          style: Styles.style16Regular.copyWith(
            color: AppColors.coolGray,
          ),
        ),
      ],
    );
  }
}
