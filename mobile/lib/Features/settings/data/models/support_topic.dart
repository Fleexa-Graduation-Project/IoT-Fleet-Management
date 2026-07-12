import 'package:flutter/material.dart';

class SupportTopic {
  final String title;
  final IconData headerIcon;
  final String description;
  final List<TopicSection> sections;

  SupportTopic({
    required this.title,
    required this.headerIcon,
    required this.description,
    required this.sections,
  });
}

class TopicSection {
  final String title;
  final IconData icon;
  final String summary;
  final List<String> points;

  TopicSection({
    required this.title,
    required this.icon,
    required this.summary,
    required this.points,
  });
}