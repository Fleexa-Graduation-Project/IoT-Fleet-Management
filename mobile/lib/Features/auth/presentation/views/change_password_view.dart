import 'package:fleexa/Features/auth/presentation/manager/auth_cubit.dart';
import 'package:fleexa/Features/auth/presentation/views/widgets/custom_button.dart';
import 'package:fleexa/Features/auth/presentation/views/widgets/custom_text_form_field.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/constants/app_colors.dart';
import '../manager/auth_state.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});
  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: Text(S.of(context).settingsChangePassword),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            context.pop();
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
                            const SizedBox(height: 80),
                            CustomTextFormField(
                              controller: _currentPasswordController,
                              prefixIcon: Icons.lock_outline,
                              hintText: S.of(context).currentPassword,
                              obscureText: true,
                            ),
                            const SizedBox(height: 24),
                            CustomTextFormField(
                              controller: _newPasswordController,
                              prefixIcon: Icons.lock_outline,
                              hintText: S.of(context).CreateNewPassword,
                              obscureText: true,
                            ),
                            const SizedBox(height: 24),
                            CustomTextFormField(
                              controller: _confirmPasswordController,
                              prefixIcon: Icons.lock_outline,
                              hintText: S.of(context).confirmNewPassword,
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
                            const SizedBox(height: 12),
                            const Spacer(),
                            CustomButton(
                              text: S.of(context).settingsChangePassword,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<AuthCubit>().changePassword(
                                        currentPassword:
                                            _currentPasswordController.text,
                                        newPassword:
                                            _newPasswordController.text,
                                        confirmPassword:
                                            _confirmPasswordController.text,
                                      );
                                }
                              },
                            ),
                            const SizedBox(height: 80),
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
