import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/related_device_card.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';
import '../../../../../../../../generated/l10n.dart';

class RelatedDeviceSection extends StatelessWidget {
  const RelatedDeviceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).labelRelatedDevices,
          style: Styles.style18Medium,
        ),
        const SizedBox(height: 20),
        const RelatedDeviceCard(),
      ],
    );
  }
}
