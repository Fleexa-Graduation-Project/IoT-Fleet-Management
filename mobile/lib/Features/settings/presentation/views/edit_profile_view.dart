import 'package:fleexa/Features/auth/presentation/views/widgets/custom_button.dart';
import 'package:fleexa/Features/settings/presentation/views/widgets/edit_field.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController =
      TextEditingController(text: "John Doe");
  final TextEditingController emailController =
      TextEditingController(text: "youssif244@gmail.com");

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(S.of(context).editProfile, style: Styles.style20Medium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    EditField(
                      label: S.of(context).fieldUsername,
                      controller: nameController,
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 24),
                    EditField(
                      label: S.of(context).fieldEmail,
                      controller: emailController,
                      icon: Icons.email_outlined,
                      enabled: false,
                    ),
                    const Spacer(),
                    const SizedBox(height: 20),
                    CustomButton(
                        text: S.of(context).saveChanges, onPressed: () {}),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
