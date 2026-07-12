import 'package:flutter/material.dart';
import 'package:fleexa/generated/l10n.dart';
import '../models/support_topic.dart';

class SupportData {
  static SupportTopic _privacyPolicy() => SupportTopic(
        title: S.current.privacyPolicy,
        headerIcon: Icons.shield_outlined,
        description: S.current.weAreCommittedToEnsuring,
        sections: [
          TopicSection(
            title: S.current.dataCollection,
            icon: Icons.data_usage,
            summary: S.current.weCollectMinimalInfoNeeded,
            points: [
              'Basic profile information (display name and email).',
              'Device telemetry for your smart home dashboard.',
            ],
          ),
          TopicSection(
            title: S.current.usagePurpose,
            icon: Icons.visibility_outlined,
            summary: S.current.yourDataProvidesStableLive,
            points: [
              'Display live home status and device insights.',
              'Send warning and critical alerts securely.',
            ],
          ),
          TopicSection(
            title: S.current.yourControl,
            icon: Icons.person_outline,
            summary: S.current.youManageYourSettingsAnd,
            points: [
              'Adjust alerts and notifications anytime.',
              'Request complete account deletion securely.',
            ],
          ),
        ],
      );

  static SupportTopic _contactSupport() => SupportTopic(
        title: S.current.contactSupport,
        headerIcon: Icons.headset_mic_outlined,
        description: S.current.needAssistanceWithYourApp,
        sections: [
          TopicSection(
            title: S.current.emailUs,
            icon: Icons.email_outlined,
            summary: S.current.reachOutDirectlyAtSupportfleexaapp,
            points: [
              'Use your registered account email for verification.',
              'Submit one issue per message for faster help.',
            ],
          ),
          TopicSection(
            title: S.current.whatToInclude,
            icon: Icons.info_outline,
            summary: S.current.provideDetailsToSpeedUp,
            points: [
              'Mention the specific device or page causing the issue.',
              'Describe what happened versus what you expected.',
            ],
          ),
          TopicSection(
            title: S.current.responseTimes,
            icon: Icons.schedule,
            summary: S.current.weAimToReplyWithin,
            points: [
              'Critical security issues are prioritized instantly.',
              'General inquiries are handled during business hours.',
            ],
          ),
        ],
      );

  static SupportTopic _reportProblem() => SupportTopic(
        title: S.current.reportAProblem,
        headerIcon: Icons.build_outlined,
        description: S.current.helpUsImproveFleexaProviding,
        sections: [
          TopicSection(
            title: S.current.precheckSteps,
            icon: Icons.wifi_protected_setup,
            summary: S.current.verifyBasicsBeforeSendingA,
            points: [
              'Ensure your internet connection is stable.',
              'Check if your app is updated to the latest version.',
            ],
          ),
          TopicSection(
            title: S.current.beSpecific,
            icon: Icons.edit_note,
            summary: S.current.clearReproductionStepsFixBugs,
            points: [
              'Write step-by-step instructions to trigger the bug.',
              'Attach screenshots or screen recordings if possible.',
            ],
          ),
          TopicSection(
            title: S.current.urgentIssues,
            icon: Icons.warning_amber_rounded,
            summary: S.current.securityAndHardwareDropsAre,
            points: [
              'Report missing security alerts immediately.',
              'Report if door locks or AC commands fail to execute.',
            ],
          ),
        ],
      );

  static SupportTopic get privacyPolicy => _privacyPolicy();
  static SupportTopic get contactSupport => _contactSupport();
  static SupportTopic get reportProblem => _reportProblem();
}
