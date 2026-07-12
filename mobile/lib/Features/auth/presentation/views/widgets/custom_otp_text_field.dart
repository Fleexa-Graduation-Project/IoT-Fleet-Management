import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomOtpTextField extends StatelessWidget {
  final void Function(String) onSubmit;
  final void Function(String)? onCodeChanged;

  const CustomOtpTextField({
    super.key,
    required this.onSubmit,
    this.onCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return OtpTextField(
      autoFocus: true,
      numberOfFields: 6,
      enabledBorderColor: AppColors.coolGray,
      focusedBorderColor: AppColors.burgundy,
      showFieldAsBox: true,
      fieldWidth: 48.w, 
      borderRadius: BorderRadius.circular(12.r),
      textStyle: Styles.style20Medium,
      keyboardType: TextInputType.number,
      onCodeChanged: onCodeChanged,
      onSubmit: onSubmit,
    );
  }
}