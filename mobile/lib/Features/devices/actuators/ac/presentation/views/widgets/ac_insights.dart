import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/ac_insight_usage.dart';
import 'package:flutter/material.dart';

import '../../../../../../../../core/utils/constants/styles.dart';
import '../../../../../../../../generated/l10n.dart';

class AcInsights extends StatelessWidget {
  const AcInsights({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).labelInsights,
          style: Styles.style18Medium,
        ),
        const SizedBox(height: 20),
        const AcInsightUsage(),
      ],
    );
  }
}
