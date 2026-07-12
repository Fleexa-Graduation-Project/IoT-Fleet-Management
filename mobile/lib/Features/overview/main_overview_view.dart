import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fleexa/Features/devices/actuators/ac/presentation/manager/ac_control_cubit.dart';
import 'package:fleexa/Features/overview/home/presentation/manager/devices_cubit.dart';
import 'package:fleexa/Features/overview/home/presentation/manager/devices_state.dart';
import 'package:fleexa/Features/overview/home/presentation/views/home_view.dart';
import 'package:fleexa/Features/overview/system_overview/data/repos/system_overview_repository.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/manager/Energy_cubit/energy_cubit.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/manager/alerts_chart_cubit/alerts_chart_cubit.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/manager/system_overview_cubit/system_overview_cubit.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/views/system_overview_view.dart';
import 'package:fleexa/Features/settings/presentation/views/settings_view.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart';
import 'package:fleexa/core/setup/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../devices/actuators/door_lock/presentation/manager/door_lock_cubit.dart';
import 'system_overview/presentation/manager/system_overview_cubit/system_overview_state.dart';
import 'widgets/custom_bottom_nav_bar.dart';

class MainOverviewView extends StatefulWidget {
  const MainOverviewView({super.key});

  @override
  State<MainOverviewView> createState() => _MainOverviewViewState();
}

class _MainOverviewViewState extends State<MainOverviewView> {
  final PageController _pageController = PageController();
  final GlobalKey _hotspotKey = GlobalKey();

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupNetworkListener();
    getIt<DevicesCubit>().fetchDevices();
  }

  void _setupNetworkListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      // if connection is back
      if (!results.contains(ConnectivityResult.none)) {
        // use the hotspot context to trigger data refresh in the relevant cubits
        final currentContext = _hotspotKey.currentContext;

        if (currentContext != null && currentContext.mounted) {
          // 1. Check the Homepage screen.
          final devicesState = currentContext.read<DevicesCubit>().state;
          if (devicesState is DevicesError &&
              devicesState.errorType == ErrorType.network) {
            currentContext.read<DevicesCubit>().fetchDevices();
          }

          // 2. Check the System Overview screen.
          final systemState = currentContext.read<SystemOverviewCubit>().state;
          if (systemState is SystemOverviewFailure &&
              systemState.errorType == ErrorType.network) {
            currentContext
                .read<SystemOverviewCubit>()
                .getOverview(period: TimeRange.lastWeek.apiValue);
            currentContext
                .read<AlertsChartCubit>()
                .getAlertsChart(period: TimeRange.lastWeek.apiValue);
            currentContext
                .read<EnergyCubit>()
                .getEnergy(period: TimeRange.lastWeek.apiValue);
          }
        }
      }
    });
  }

  final List<Widget> _screens = const [
    HomeView(),
    SystemOverviewView(),
    SettingsView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              SystemOverviewCubit(getIt<SystemOverviewRepository>())
                ..getOverview(period: TimeRange.lastWeek.apiValue),
        ),
        BlocProvider(
          create: (context) =>
              AlertsChartCubit(getIt<SystemOverviewRepository>())
                ..getAlertsChart(period: TimeRange.lastWeek.apiValue),
        ),
        BlocProvider(
            create: (context) => EnergyCubit(getIt<SystemOverviewRepository>())
              ..getEnergy(period: TimeRange.lastWeek.apiValue)),
        BlocProvider.value(
          value: getIt<DevicesCubit>(),
        ),
        BlocProvider.value(
          value: getIt<DoorLockCubit>(),
        ),
        BlocProvider.value(
          value: getIt<AcControlCubit>(),
        ),
      ],
      child: Theme(
        data: Theme.of(context).copyWith(
          cardColor: AppColors.dimGray,
          dialogBackgroundColor: AppColors.dimGray,
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.wineRed,
                secondary: AppColors.white,
              ),
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: AppColors.white,
                displayColor: AppColors.white,
              ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.coolGray,
            ),
          ),
        ),
        child: Scaffold(
          key: _hotspotKey,
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: _screens,
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
