class AlertModel {
  final String deviceId;
  final String deviceType;
  final String title;
  final DateTime time;
  final String description;
  final String severity;
  final String alertId;
  final bool isRead;

  AlertModel({
    required this.deviceId,
    required this.deviceType,
    required this.title,
    required this.time,
    required this.description,
    required this.severity,
    this.alertId = '',
    this.isRead = false,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    // log("RAW ALERT DATA: $json");
    final payload = json['payload'] is Map<String, dynamic>
        ? json['payload'] as Map<String, dynamic>
        : {};

    // 1. Extract Type & Severity
    final String type = json['type'] ?? payload['type'] ?? '';
    final String rawSeverity =
        json['severity'] ?? payload['severity'] ?? 'WARNING';

    final String severityText = rawSeverity.isNotEmpty
        ? '${rawSeverity[0].toUpperCase()}${rawSeverity.substring(1).toLowerCase()}'
        : 'Warning';

    // 2. Edit Time format
    DateTime parsedTime = DateTime.now();
    final rawTimestamp = json['timestamp'];
    if (rawTimestamp != null) {
      if (rawTimestamp is String) {
        String timeString = rawTimestamp;

        if (!timeString.endsWith('Z')) timeString += 'Z';

        parsedTime = DateTime.tryParse(timeString)?.toLocal() ?? DateTime.now();
      } else if (rawTimestamp is int) {
        parsedTime =
            DateTime.fromMillisecondsSinceEpoch(rawTimestamp * 1000).toLocal();
      }
    }

    // 3. Fetch raw text to extract values using Regex
    String rawTitle = json['title'] ?? payload['title'] ?? '';
    String rawDesc = json['description'] ??
        json['body'] ??
        payload['description'] ??
        payload['body'] ??
        '';
    String fullRawText = '$rawTitle $rawDesc'.toLowerCase();

    // 4. Force Unified Title & Description
    String parsedTitle = '';
    String parsedDesc = '';

    if (type.contains('gas') || fullRawText.contains('gas')) {
      parsedTitle = '$severityText Gas Alert';

      dynamic gasLevel = payload['gas_level'] ?? payload['ppm'];

      // If null, dynamically find ANY key that ends with '_ppm'
      if (gasLevel == null) {
        final dynamicPpmKey = payload.keys.firstWhere(
          (key) => key is String && key.endsWith('_ppm'),
          orElse: () => '',
        );

        if (dynamicPpmKey.toString().isNotEmpty) {
          gasLevel = payload[dynamicPpmKey];
        }
      }
      if (gasLevel == null) {
        // Extract decimal or whole number from text (e.g., "739.1")
        final RegExp regExp = RegExp(r'(\d+(\.\d+)?)');
        final match = regExp.firstMatch(fullRawText);
        if (match != null) {
          gasLevel = match.group(1);
        }
      }

      if (gasLevel != null) {
        double level = double.tryParse(gasLevel.toString()) ?? 0.0;
        parsedDesc = 'Gas Level: ${level.toStringAsFixed(1)} PPM';
      } else {
        parsedDesc = 'Gas Level: Critical PPM';
      }
    } else if (type.contains('door') || fullRawText.contains('door')) {
      parsedTitle = '$severityText Door Alert';

      // Extract number of minutes
      final RegExp regExp = RegExp(r'(\d+)\s*(min|m)');
      final match = regExp.firstMatch(fullRawText);
      String minutes = '15'; // Default fallback

      if (match != null) {
        minutes = match.group(1)!;
      } else {
        // Fallback regex to find any number in the description
        final RegExp fallbackRegExp = RegExp(r'(\d+)');
        final fallbackMatch = fallbackRegExp.firstMatch(rawDesc);
        if (fallbackMatch != null) {
          minutes = fallbackMatch.group(1)!;
        }
      }

      parsedDesc = 'Door left unlocked for $minutes minutes';
      // 3. AC Timer Alerts Formatting
    } else if (type.contains('ac') ||
        fullRawText.contains('timer finished') ||
        rawSeverity.toUpperCase() == 'INFO') {
      parsedTitle = 'AC Timer Finished';

      // Extract the number of minutes if available
      final RegExp regExp = RegExp(r'for\s+(\d+)\s+minutes');
      final match = regExp.firstMatch(fullRawText);

      if (match != null) {
        String minutes = match.group(1)!;
        parsedDesc =
            'AC turned off after running for $minutes minutes, as scheduled.';
      } else {
        parsedDesc =
            'AC has been turned off automatically — the timer finished.';
      }

      // 4. Fallback for other alerts
    } else {
      parsedTitle = '$severityText System Alert';
      parsedDesc = rawDesc.isNotEmpty ? rawDesc : 'System anomaly detected';
    }

    return AlertModel(
      deviceId: json['device_id'] ?? '',
      deviceType: type,
      title: parsedTitle,
      time: parsedTime,
      description: parsedDesc,
      severity: json['severity'] ?? 'WARNING',
      alertId: json['alert_id'] ?? '',
      isRead: json['is_read'] ?? false,
    );
  }
}
