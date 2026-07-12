import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashBody extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const SplashBody({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  State<SplashBody> createState() => _SplashBodyState();
}

class _SplashBodyState extends State<SplashBody> {
  bool _startAnimation = false;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _startSplashSequence();
  }

  void _startSplashSequence() {
    // Remove Native Splash & Start Text Expansion
    Future.delayed(const Duration(milliseconds: 500), () {
      FlutterNativeSplash.remove();
      if (mounted) {
        setState(() {
          _startAnimation = true;
        });
      }
    });

    // Start Fading Out
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _opacity = 0.0;
        });
      }
    });

    // Notify Parent that the entire animation sequence is fully complete
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        widget.onAnimationComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          opacity: _opacity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SvgPicture.asset(
                'assets/images/letter_logo.svg',
                width: 52,
                height: 52,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                width: _startAnimation ? 105 : 0,
                height: 32,
                child: ClipRRect(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SvgPicture.asset(
                      'assets/images/full_logo.svg',
                      width: 105,
                      height: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
