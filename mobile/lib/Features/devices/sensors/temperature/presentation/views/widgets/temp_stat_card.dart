import 'package:fleexa/Features/devices/sensors/temperature/data/models/temp_stat_model.dart';
import 'package:fleexa/core/widgets/custom_container.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class TempStatCard extends StatelessWidget {
  final TempStatModel tempStatModel;

  const TempStatCard({
    super.key,
    required this.tempStatModel,
  });

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            tempStatModel.iconPath,
          ),
          const SizedBox(height: 8),
          Text(
            tempStatModel.title,
            style: Styles.style18Regular,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            tempStatModel.value,
            style: Styles.style16Medium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
