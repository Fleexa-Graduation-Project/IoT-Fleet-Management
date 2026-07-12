import 'package:fleexa/Features/auth/presentation/manager/auth_cubit.dart';
import 'package:fleexa/Features/auth/presentation/manager/auth_state.dart';
import 'package:fleexa/Features/auth/presentation/views/widgets/custom_button.dart';
import 'package:fleexa/Features/auth/presentation/views/widgets/custom_text_form_field.dart';
import 'package:fleexa/Features/settings/presentation/views/widgets/confirm_dialog.dart';
import 'package:fleexa/core/router/app_router.dart';
import 'package:fleexa/core/widgets/app_snackbar.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:go_router/go_router.dart';

class DeleteAccountView extends StatefulWidget {
  const DeleteAccountView({super.key});
  @override
  State<DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<DeleteAccountView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.white,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(S.of(context).deleteAccount),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          S.of(context).enterYourPasswordToDelete,
                          style: Styles.style14Medium
                              .copyWith(color: AppColors.coolGray),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        CustomTextFormField(
                          controller: _currentPasswordController,
                          prefixIcon: Icons.lock_outline,
                          hintText: S.of(context).currentPassword,
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),
                        const Spacer(),
                        CustomButton(
                          text: "Delete",
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => ConfirmDialog(
                                  dialogType: DialogType.deleteAccount,
                                  onConfirm: () async {
                                    // 1. Pop the dialog safely
                                    if (dialogContext.canPop()) {
                                      dialogContext.pop();
                                    }

                                    // 2. Call the cubit to delete the account
                                    final authCubit = context.read<AuthCubit>();
                                    bool isDeleted =
                                        await authCubit.deleteAccount(
                                            _currentPasswordController.text);

                                    // 3. Ensure the screen is still mounted
                                    if (!context.mounted) return;

                                    if (isDeleted) {
                                      // Show success message
                                      AppSnackbar.show(
                                        context,
                                        type: SnackBarType.success,
                                        message:
                                            "Your account has been successfully deleted. We're sorry to see you go!",
                                      );

                                      // Route back to sign in
                                      context.goNamed(AppRouter.signIn);
                                    } else {
                                      // Handle failure and show the exact error message from the cubit
                                      final state = authCubit.state;
                                      String errorMessage =
                                          "Incorrect password or network error.";
                                      if (state is AuthError) {
                                        errorMessage = state.error;
                                      }

                                      AppSnackbar.show(
                                        context,
                                        type: SnackBarType.fail,
                                        message: errorMessage,
                                      );
                                    }
                                  },
                                ),
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
        ));
  }
}
