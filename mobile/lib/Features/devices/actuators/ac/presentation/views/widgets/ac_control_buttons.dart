import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/custom_power_switch.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

class AcControlButtons extends StatelessWidget {
  const AcControlButtons({
    super.key,
    required this.isManual,
    this.onPowerToggle,
    this.isOn = true,
    required this.onIncreaseTemp,
    required this.onDecreaseTemp,
  });

  final bool isManual;
  final bool isOn;
  final ValueChanged<bool>? onPowerToggle;
  final VoidCallback onIncreaseTemp;
  final VoidCallback onDecreaseTemp;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onDecreaseTemp,
          icon: Container(
            decoration: const BoxDecoration(
              color: AppColors.dimGray,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(14),
            child: const Icon(Icons.remove, size: 24, color: Colors.white),
          ),
        ),
        if (isManual) CustomPowerSwitch(isOn: isOn, onToggle: onPowerToggle),
        IconButton(
          onPressed: onIncreaseTemp,
          icon: Container(
            decoration: const BoxDecoration(
              color: AppColors.dimGray,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(14),
            child: const Icon(Icons.add, size: 24, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
