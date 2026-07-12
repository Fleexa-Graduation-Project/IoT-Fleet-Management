import 'package:fleexa/Features/settings/data/models/support_topic.dart';
import 'package:fleexa/Features/settings/presentation/views/widgets/about_support_section.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';


class SupportDetailView extends StatelessWidget {
  const SupportDetailView({super.key, required this.topic});

  final SupportTopic topic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(topic.title, style: Styles.style20Medium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ...topic.sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AboutSupportSection(section: section),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}