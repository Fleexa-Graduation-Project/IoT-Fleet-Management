import 'package:fleexa/Features/auth/presentation/manager/auth_cubit.dart';
import 'package:fleexa/Features/auth/presentation/views/widgets/account_action_text.dart';
import 'package:fleexa/Features/auth/presentation/views/widgets/custom_button.dart';
import 'package:fleexa/Features/auth/presentation/views/widgets/custom_otp_text_field.dart';
import 'package:fleexa/core/router/app_router.dart';
import 'package:fleexa/core/widgets/app_snackbar.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Added ScreenUtil
import 'package:go_router/go_router.dart';

import '../manager/auth_state.dart';

class VerifyCodeView extends StatefulWidget {
  const VerifyCodeView({super.key});

  @override
  State<VerifyCodeView> createState() => _VerifyCodeViewState();
}

class _VerifyCodeViewState extends State<VerifyCodeView> {
  String _enteredCode = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthCodeSaved) {
            GoRouter.of(context).pushNamed(AppRouter.changePasswordWithEmail);
          }
        },
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w), // Responsive padding
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      SizedBox(height: 32.h), // Responsive height
                      Text(
                        S.of(context).verifyCode,
                        style: Styles.style28Medium,
                      ),
                      SizedBox(height: 12.h), // Responsive height
                      Text.rich(
                        TextSpan(
                          text: S.of(context).pleaseEnterTheOTP(""),
                          style: Styles.style14Regular,
                          children: [
                            TextSpan(
                              text: context.read<AuthCubit>().email, // Corrected syntax
                              style: Styles.style14Regular.copyWith(
                                color: AppColors.burgundy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 52.h), // Responsive height
                      CustomOtpTextField(
                        onCodeChanged: (code) {
                          _enteredCode = code;
                        },
                        onSubmit: (verificationCode) {
                          setState(() {
                            _enteredCode = verificationCode;
                          });
                          context.read<AuthCubit>().saveOtpCode(_enteredCode);
                        },
                      ),
                      SizedBox(height: 28.h), // Responsive height
                      AccountActionText(
                        normalText: S.of(context).didntReceiveOTP,
                        actionText: S.of(context).resendOTP,
                        onTap: () {
                          context.goNamed(AppRouter.resetPassword);
                        },
                      ),
                      const Spacer(),
                      CustomButton(
                        text: S.of(context).verifyCode,
                        onPressed: () {
                          if (_enteredCode.length == 6) {
                            context.read<AuthCubit>().saveOtpCode(_enteredCode);
                          } else {
                            AppSnackbar.show(
                              context,
                              type: SnackBarType.fail,
                              message: "Please enter the full OTP code.",
                            );
                          }
                        },
                      ),
                      SizedBox(height: 80.h), // Responsive height
                    ],
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