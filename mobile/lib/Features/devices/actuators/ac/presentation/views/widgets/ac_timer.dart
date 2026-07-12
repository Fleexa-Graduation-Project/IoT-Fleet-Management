import 'dart:async';

import 'package:fleexa/Features/devices/actuators/ac/presentation/manager/ac_control_cubit.dart';
import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/ac_timer_options.dart';
import 'package:fleexa/Features/devices/actuators/ac/presentation/views/widgets/ac_timer_settings_button.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../core/utils/constants/app_strings.dart';
import '../../../../../../../core/services/push_notification_service.dart';
import '../../../../../../../core/setup/service_locator.dart';
import '../../manager/ac_control_state.dart';
import 'custom_timer_picker.dart';

class AcTimer extends StatefulWidget {
  const AcTimer({super.key});

  @override
  State<AcTimer> createState() => _AcTimerState();
}

class _AcTimerState extends State<AcTimer> {
  int? selectedHours;
  int selectedMin = 0;
  Timer? _countdownTimer;

  int remainingHours = 0;
  int remainingMinutes = 0;
  int remainingSeconds = 0;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startLocalCountdown(double? endTimestamp) {
    _countdownTimer?.cancel();

    if (endTimestamp == null) {
      setState(() {
        remainingHours = 0;
        remainingMinutes = 0;
        remainingSeconds = 0;
        selectedHours = null;
      });
      return;
    }

    void updateRemainingTime() {
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = endTimestamp - now;

      if (diff > 0) {
        final int totalSeconds = (diff / 1000).floor();
        setState(() {
          remainingHours = (diff / (1000 * 60 * 60)).floor();
          remainingMinutes = ((diff / (1000 * 60)) % 60).floor();
          remainingSeconds = totalSeconds % 60;

          // if the user opned the screen and the timer was already running.
          if (selectedHours == null && remainingMinutes == 0) {
            selectedHours = remainingHours;
          }
        });
      } else {
        // timer has ended
        _countdownTimer?.cancel();
        setState(() {
          remainingHours = 0;
          remainingMinutes = 0;
          remainingSeconds = 0;
          selectedHours = null;
        });
      }
    }

    updateRemainingTime(); // first call to set the initial state
    _countdownTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => updateRemainingTime());
  }

  String _formatTimer() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    if (remainingHours > 0) {
      return '${twoDigits(remainingHours)}:${twoDigits(remainingMinutes)}:${twoDigits(remainingSeconds)}';
    } else {
      return '${twoDigits(remainingMinutes)}:${twoDigits(remainingSeconds)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AcControlCubit, AcControlState>(
      listener: (context, state) {
        if (state is AcControlUpdated) {
          // every time we get an update from the cubit we check if the timer end timestamp has changed.
          _startLocalCountdown(state.timerEndTimestamp);

          // if the timer has ended or the AC is turned off, we cancel the notification.
          if (state.timerEndTimestamp == null || !state.powerOn) {
            getIt<PushNotificationService>().cancelACTimerNotification();
          }
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).timer,
                  style: Styles.style18Medium,
                ),
                const Spacer(),
                Text(
                  // show the remaining time.
                  remainingHours > 0 ||
                          remainingMinutes > 0 ||
                          remainingSeconds > 0
                      ? _formatTimer()
                      : "No active timer",
                  style:
                      Styles.style14Medium.copyWith(color: AppColors.coolGray),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                AcTimerSettingsButton(
                  onTap: () {
                    final acCubit = context.read<AcControlCubit>();

                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (dialogContext) {
                        return Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: CustomTimerPicker(
                            mode: PickerMode.duration,
                            initialDuration: Duration(
                              hours: selectedHours ?? 0,
                              minutes: selectedMin,
                            ),
                            onTimerSet: (Duration duration) {
                              acCubit.setTimer(
                                  duration.inHours, duration.inMinutes % 60);

                              setState(() {
                                selectedHours = duration.inHours;
                                selectedMin = duration.inMinutes % 60;
                              });

                              final totalMinutes = (duration.inHours * 60) +
                                  (duration.inMinutes % 60);
                              if (totalMinutes > 0) {
                                getIt<PushNotificationService>()
                                    .showACTimerNotification(
                                  durationInMinutes: totalMinutes,
                                  deviceId: acCubit.deviceId,
                                );
                              } else {
                                getIt<PushNotificationService>()
                                    .cancelACTimerNotification();
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
                Expanded(
                  child: AcTimerOptions(
                    selectedOption: selectedHours,
                    selectedMin: selectedMin,
                    onOptionChanged: (int hours) {
                      setState(() {
                        if (selectedHours == hours) {
                          // user cancelled the timer.
                          selectedHours = null;
                          selectedMin = 0;
                          context.read<AcControlCubit>().setTimer(0, 0);

                          // cancel the notification if the user cancels the timer.
                          getIt<PushNotificationService>()
                              .cancelACTimerNotification();
                        } else {
                          // if user chose a new timer.
                          selectedHours = hours;
                          selectedMin = 0;
                          context.read<AcControlCubit>().setTimer(hours, 0);

                          // show the notification for the timer.
                          getIt<PushNotificationService>()
                              .showACTimerNotification(
                            durationInMinutes: hours * 60,
                            deviceId: context.read<AcControlCubit>().deviceId,
                          );
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
