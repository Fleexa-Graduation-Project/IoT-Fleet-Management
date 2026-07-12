import 'package:fleexa/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/manager/auth_cubit.dart';
import '../../../auth/presentation/manager/auth_state.dart';
import 'widgets/splash_body.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  bool _isAnimationDone = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().checkAppStart();
  }

  void _handleNavigation(AuthState state) {
    if (!_isAnimationDone ||
        state is AuthInitial ||
        state is AuthCheckInProgress) {
      return;
    }

    if (state is FirstTimeUser) {
      GoRouter.of(context).pushReplacementNamed(AppRouter.onBoarding);
    } else if (state is Unauthenticated) {
      GoRouter.of(context).pushReplacementNamed(AppRouter.signIn);
    } else if (state is Authenticated) {
      GoRouter.of(context).pushReplacementNamed(AppRouter.mainOverview);
    } else {
      GoRouter.of(context).pushReplacementNamed(AppRouter.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          _handleNavigation(state);
        },
        child: SplashBody(
          onAnimationComplete: () {
            setState(() {
              _isAnimationDone = true;
            });
            _handleNavigation(context.read<AuthCubit>().state);
          },
        ),
      ),
    );
  }
}
