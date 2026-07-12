import 'package:fleexa/Features/on_boarding/data/on_boarding_model.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class BuildOnboardingPage extends StatelessWidget {
  const BuildOnboardingPage({super.key, required this.model, this.index = 1});
  final int index;
  final OnBoardingModel model;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.burgundy.withOpacity(0.2),
                      AppColors.darkMaroon.withOpacity(0.1),
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
              ),
              // The Circular Icon/SVG (Top Layer)
              SvgPicture.asset(
                model.image,
                height: 250,
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(model.title, style: Styles.style24SemiBold),
          const SizedBox(height: 12),
          Text(
            model.description,
            style:
                Styles.style18Regular.copyWith(color: AppColors.platinumGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
