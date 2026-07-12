import 'package:fleexa/Features/on_boarding/data/on_boarding_model.dart';
import 'package:fleexa/generated/l10n.dart';

import 'package:fleexa/Features/on_boarding/presentation/views/widgets/build_onboarding_page.dart';
import 'package:fleexa/Features/on_boarding/presentation/views/widgets/get_started_button.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/assets.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/router/app_router.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final controller = PageController();
  bool isLastPage = false;
  int currentPage = 0;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 80,
        // Show Back arrow only if not on the first page
        leading: currentPage != 0
            ? IconButton(
                onPressed: () => controller.previousPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.platinumGray),
              )
            : const SizedBox(),
        actions: [
          // Hide Skip button if on the last page
          if (!isLastPage)
            TextButton(
              onPressed: () {
                GoRouter.of(context).goNamed(AppRouter.signIn);
              },
              child: Text(S.of(context).skip, style: Styles.style16Regular),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: controller,
                onPageChanged: (index) {
                  setState(() {
                    isLastPage = index == 2;
                    currentPage = index;
                  });
                },
                children: [
                  BuildOnboardingPage(
                    model: OnBoardingModel(
                      image: AppAssets.iconsCloud,
                      title: S.of(context).smartControl,
                      description: S.of(context).runYourIotSimulationWithout,
                      controller: controller,
                    ),
                    index: 0,
                  ),
                  BuildOnboardingPage(
                    model: OnBoardingModel(
                      image: AppAssets.iconsChart,
                      title: S.of(context).realtimeMonitoring,
                      description: S.of(context).trackYourSensorDataInstantly,
                      controller: controller,
                    ),
                  ),
                  BuildOnboardingPage(
                    model: OnBoardingModel(
                      image: AppAssets.iconsWifi,
                      title: S.of(context).instantAlerts,
                      description:
                          S.of(context).getNotifiedImmediatelyWhenThresholds,
                      controller: controller,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: isLastPage
                  ? const GetStartedButton()
                  : SmoothPageIndicator(
                      controller: controller,
                      count: 3,
                      effect: ExpandingDotsEffect(
                        dotHeight: 10,
                        dotWidth: 10,
                        expansionFactor: 4,
                        spacing: 8,
                        dotColor: AppColors.platinumGray.withOpacity(0.3),
                        activeDotColor: AppColors.wineRed,
                      ),
                    ),
            ),
            const SizedBox(
              height: 100,
            )
          ],
        ),
      ),
    );
  }
}
