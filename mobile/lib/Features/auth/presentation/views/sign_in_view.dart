import 'package:fleexa/Features/auth/presentation/manager/auth_cubit.dart';
import 'package:fleexa/Features/auth/presentation/views/widgets/account_action_text.dart';
import 'package:fleexa/Features/auth/presentation/views/widgets/custom_button.dart';
import 'package:fleexa/Features/auth/presentation/views/widgets/custom_text_form_field.dart';
import 'package:fleexa/Features/auth/presentation/views/widgets/or_divider.dart';
import 'package:fleexa/core/router/app_router.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/constants/app_colors.dart';
import '../manager/auth_state.dart';

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back_ios),
        //   onPressed: () => Navigator.pop(context),
        // ),
        title: Padding(
          padding: const EdgeInsetsGeometry.only(top: 20),
          child: Text(S.of(context).authSignInTitle),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            GoRouter.of(context).pushReplacementNamed(AppRouter.mainOverview);
            AppSnackbar.show(
              context,
              type: SnackBarType.success,
              message: state.message,
            );
          } else if (state is AuthError) {
            AppSnackbar.show(
              context,
              type: SnackBarType.fail,
              message: state.error,
            );
          }
        },
        builder: (context, state) {
          return ModalProgressHUD(
            inAsyncCall: state is AuthLoading,
            blur: 0.5,
            color: Colors.black.withOpacity(0.3),
            progressIndicator:
                const CircularProgressIndicator(color: AppColors.wineRed),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              S.of(context).authWelcomeBack,
                              style: Styles.style14Medium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                            CustomTextFormField(
                              controller: _emailController,
                              prefixIcon: Icons.email_outlined,
                              hintText: S.of(context).fieldEmail,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 24),
                            CustomTextFormField(
                              controller: _passwordController,
                              prefixIcon: Icons.lock_outline,
                              hintText: S.of(context).fieldPassword,
                              textInputAction: TextInputAction.done,
                              keyboardType: TextInputType.text,
                              obscureText: true,
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                child: Text(
                                  S.of(context).authForgotPassword,
                                  style: Styles.style14Regular,
                                ),
                                onPressed: () {
                                  GoRouter.of(context)
                                      .pushNamed(AppRouter.resetPassword);
                                },
                              ),
                            ),
                            const Spacer(),
                            CustomButton(
                              text: S.of(context).authSignInTitle,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<AuthCubit>().signIn(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text,
                                      );
                                }
                              },
                            ),
                            const SizedBox(height: 32),
                            const OrDivider(),
                            const SizedBox(height: 32),
                            AccountActionText(
                              normalText:
                                  "${S.of(context).authNoAccountQuestion} ",
                              actionText: S.of(context).authSignUpTitle,
                              onTap: () {
                                context.goNamed(AppRouter.signUp);
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
