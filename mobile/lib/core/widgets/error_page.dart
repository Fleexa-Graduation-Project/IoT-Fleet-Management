import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Features/auth/presentation/views/widgets/custom_button.dart';
import '../utils/constants/app_colors.dart';
import '../utils/constants/styles.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.onRetry, required this.type});

  final ErrorType type;
  final VoidCallback onRetry;

  String get errorTitle {
    switch (type) {
      case ErrorType.network:
        return "Ooops!";
      case ErrorType.server:
        return "Server Error";
      case ErrorType.unknown:
        return "Something Went Wrong";
    }
  }

  String get errorDescription {
    switch (type) {
      case ErrorType.network:
        return "We can't reach your smart home right now. Please\ncheck your Wi-Fi or mobile data and try again.";
      case ErrorType.server:
        return "Our servers are taking a short break. We are working on it!";
      case ErrorType.unknown:
        return "Something went wrong. Please try again.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/no_internet.svg',
            height: 260,
          ),
          const SizedBox(height: 12),
          Text(
            errorTitle,
            style: Styles.style24Medium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            errorDescription,
            style: Styles.style14Regular.copyWith(
              color: AppColors.coolGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 180,
            child: CustomButton(
              text: "Try Again",
              onPressed: onRetry,
              textStyle: Styles.style16Medium.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
