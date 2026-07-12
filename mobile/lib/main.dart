import 'package:fleexa/Features/auth/presentation/manager/auth_cubit.dart';
import 'package:fleexa/Features/settings/presentation/manager/notification_settings_cubit.dart';
import 'package:fleexa/core/cubits/localization_cubit.dart';
import 'package:fleexa/core/router/app_router.dart';
import 'package:fleexa/core/setup/service_locator.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'Features/overview/notifications/data/repos/notifications_repository.dart';
import 'Features/overview/notifications/presentation/manager/notifications_cubit.dart';
import 'core/setup/app_initializer.dart';
import 'core/utils/theme/app_theme.dart';

void main() async {
  await AppInitializer.init();
  runApp(const Fleexa());
}

class Fleexa extends StatelessWidget {
  const Fleexa({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocalizationCubit>(
          create: (context) => LocalizationCubit(),
        ),
        BlocProvider(
          create: (context) =>
              NotificationsCubit(getIt<NotificationsRepository>())
                ..loadNotifications(),
        ),
        BlocProvider.value(
          value: getIt<NotificationSettingsCubit>()..loadSettings(),
        ),
        BlocProvider.value(
          value: getIt<AuthCubit>(),
        ),
      ],
      child: BlocBuilder<LocalizationCubit, Locale>(
        builder: (context, locale) {
          return ScreenUtilInit(
            designSize: const Size(430, 1060),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp.router(
                locale: locale,
                localizationsDelegates: const [
                  S.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: S.delegate.supportedLocales,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.darkTheme,
                routerConfig: AppRouter.router,
              );
            },
          );
        },
      ),
    );
  }
}
