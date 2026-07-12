import 'package:fleexa/Features/devices/actuators/door_lock/presentation/views/widgets/custom_row_details.dart';
import 'package:fleexa/Features/devices/shared/presentation/manager/device_details_cubit.dart';
import 'package:fleexa/core/widgets/custom_container.dart';
import 'package:fleexa/core/widgets/skelton.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../generated/l10n.dart';
import '../../../../../shared/presentation/manager/device_details_state.dart';

class DoorLockInsight extends StatefulWidget {
  const DoorLockInsight({super.key});

  @override
  State<DoorLockInsight> createState() => _DoorLockInsightState();
}

class _DoorLockInsightState extends State<DoorLockInsight> {
  bool isExpanded = false;
  bool isPressed = false;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceDetailsCubit, DeviceDetailsState>(
      builder: (context, state) {
        if (state is! DeviceDetailsLoaded) {
          return const Skelton(
            height: 72,
            width: double.infinity,
          );
        }
        final double normalDuration = state.device.normalUnlockDuration;

        final double avgDuration =
            (state.device.payload['average_unlock'] ?? 0).toDouble();

        final String status =
            state.device.payload['unlock_duration_status'] ?? '...';
        final Color statusColor = status.toUpperCase() == 'NORMAL'
            ? AppColors.emeraldGreen
            : AppColors.crimsonRed;

        final String statusText = status.toUpperCase() == 'NORMAL'
            ? S.of(context).statusNormal
            : S.of(context).statusAboveNormal;

        return GestureDetector(
          onTapDown: (_) {
            setState(() {
              isPressed = true;
            });
          },
          onTapUp: (_) {
            setState(() {
              isPressed = false;
              isExpanded = !isExpanded;
            });
          },
          onTapCancel: () {
            setState(() {
              isPressed = false;
            });
          },
          child: AnimatedScale(
            scale: isPressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: CustomContainer(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.fastOutSlowIn,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: const Icon(
                            Icons.keyboard_arrow_right_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                S.of(context).unlockDuration,
                                style: Styles.style16Medium
                                    .copyWith(color: Colors.white),
                              ),
                              Text(
                                statusText,
                                style: Styles.style14Medium
                                    .copyWith(color: statusColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      layoutBuilder: (Widget? currentChild,
                          List<Widget> previousChildren) {
                        return Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: <Widget>[
                            ...previousChildren.map((child) => Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: child,
                                )),
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.1),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: isExpanded
                          ? Column(
                              key: const ValueKey(true),
                              children: [
                                const SizedBox(height: 20),
                                CustomRowDetails(
                                  title: S.of(context).statusNormal,
                                  value: S
                                      .of(context)
                                      .timeMin(normalDuration.toInt()),
                                  valueColor: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                CustomRowDetails(
                                  title: S.of(context).avgUnlockDuration,
                                  value: S
                                      .of(context)
                                      .timeMin(avgDuration.toInt()),
                                  valueColor: statusColor,
                                ),
                              ],
                            )
                          : const SizedBox(key: ValueKey(false)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
