import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({super.key, required this.child, this.isActuator = true});
  final bool isActuator;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
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
      child: child,
    );
  }
}
