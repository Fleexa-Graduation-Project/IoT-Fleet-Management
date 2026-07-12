import 'package:fleexa/Features/settings/data/models/support_data.dart';
import 'package:fleexa/generated/l10n.dart';

import 'package:fleexa/Features/settings/data/models/support_topic.dart';
import 'package:fleexa/Features/settings/presentation/views/support_detail_view.dart';
import 'package:fleexa/Features/settings/presentation/views/widgets/about_support_action_card.dart';
import 'package:fleexa/Features/settings/presentation/views/widgets/about_support_app_card.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class AboutAndSupportView extends StatelessWidget {
  const AboutAndSupportView({super.key});

  void _openDetailsPage(BuildContext context, SupportTopic topic) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupportDetailView(topic: topic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(S.of(context).aboutSupport, style: Styles.style20Medium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AboutSupportAppCard(),
                const SizedBox(height: 32),
                Text(S.of(context).howCanWeHelp, style: Styles.style20SemiBold),
                const SizedBox(height: 24),
                AboutSupportActionCard(
                  title: S.of(context).privacyPolicy,
                  icon: Icons.privacy_tip_outlined,
                  onTap: () => _openDetailsPage(context, SupportData.privacyPolicy),
                ),
                const SizedBox(height: 16),
                AboutSupportActionCard(
                  title: S.of(context).contactSupport,
                  subtitle: S.of(context).supportfleexaapp,
                  icon: Icons.support_agent_rounded,
                  onTap: () => _openDetailsPage(context, SupportData.contactSupport),
                ),
                const SizedBox(height: 16),
                AboutSupportActionCard(
                  title: S.of(context).reportAProblem,
                  icon: Icons.bug_report_outlined,
                  onTap: () => _openDetailsPage(context, SupportData.reportProblem),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}