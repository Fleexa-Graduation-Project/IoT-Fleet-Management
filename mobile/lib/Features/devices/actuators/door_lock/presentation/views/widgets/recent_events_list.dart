import 'dart:developer';

import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/generated/l10n.dart';

import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';

class RecentEventsList extends StatelessWidget {
  const RecentEventsList({super.key, required this.events});

  final List<dynamic> events;

  String _formatLocalTime(DateTime time) {
    int hour = time.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          S.of(context).noRecentActivities,
          style: Styles.style14Medium.copyWith(color: AppColors.coolGray),
        ),
      );
    }
    return Column(
      children: List.generate(events.length, (index) {
        final eventData = events[index];
        final String eventName = eventData['event'] ?? 'Unknown Event';
        String eventTime = eventData['time'] ?? '--:--';

        log(error: eventData.toString(), 'Event Data');

        // Convert UTC time to local time and format it
        if (eventData['timestamp'] != null) {
          try {
            String rawDate = eventData['timestamp'].toString();

            // we add 'Z' at the end to indicate it's in UTC if it's not already there
            if (!rawDate.endsWith('Z')) {
              rawDate += 'Z';
            }

            // 1. read the UTC time from the server
            DateTime utcTime = DateTime.parse(rawDate);
            // 2. convert it to the local time
            DateTime localTime = utcTime.toLocal();
            // 3. show it
            eventTime = _formatLocalTime(localTime);
          } catch (e) {
            // if parsing fails, we just show the raw time string
            log(error: e.toString(), 'Time Parsing Error');
          }
        }

        final bool isLast = index == events.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: Row(
            children: [
              Text(
                eventName,
                style: Styles.style14Medium.copyWith(color: AppColors.white),
              ),
              const Spacer(),
              Text(
                eventTime,
                style: Styles.style14Medium.copyWith(color: AppColors.white),
              ),
            ],
          ),
        );
      }),
    );
  }
}
