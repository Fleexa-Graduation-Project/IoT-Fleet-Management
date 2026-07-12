import 'package:fleexa/Features/overview/home/presentation/views/widgets/custom_switch.dart';
import 'package:fleexa/Features/overview/home/presentation/views/widgets/device_card_content.dart';
import 'package:fleexa/Features/overview/home/presentation/views/widgets/device_card_header.dart';
import 'package:fleexa/Features/overview/home/presentation/views/widgets/sensor_device_card_footer.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' hide DeviceType;
import 'package:go_router/go_router.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.title,
    required this.subtext,
    required this.icon,
    required this.statusColor,
    required this.type,
    required this.pageRouteName,
    this.valueLabel,
    this.valueIcon,
    this.isOn = false,
    this.onToggle,
  });

  final String title;
  final String subtext;
  final String icon;
  final Color statusColor;
  final DeviceType type;
  final String pageRouteName;

  // Sensor specific
  final String? valueLabel;
  final String? valueIcon;

  // Switch specific
  final bool isOn;
  final ValueChanged<bool>? onToggle;

  // Important Conditions
  bool get isActuator => DeviceType.actuator == type;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        GoRouter.of(context).pushNamed(pageRouteName);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: isActuator
              ? const LinearGradient(
                  colors: [
                    AppColors.darkEspresso,
                    AppColors.darkBurgundy,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActuator ? null : AppColors.charcoalBlack,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon & Status dot
            DeviceCardHeader(
                icon: icon, statusColor: statusColor, isActuator: isActuator),
            const SizedBox(height: 12),

            // Title and subtext
            DeviceCardContent(title: title, subtext: subtext),
            const Spacer(),

            // Value label or Switch
            if (isActuator)
              Align(
                alignment: Alignment.bottomLeft,
                child: CustomSwitch(isOn: isOn, onToggle: onToggle),
              )
            else if (!isActuator && valueLabel != null && valueIcon != null)
              Align(
                alignment: Alignment.bottomLeft,
                child: SensorDeviceCardFooter(
                  valueLabel: valueLabel,
                  valueIcon: valueIcon,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
