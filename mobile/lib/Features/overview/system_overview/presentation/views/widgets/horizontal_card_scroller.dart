import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HorizontalCardScroller extends StatefulWidget {
  const HorizontalCardScroller({
    super.key,
    required this.cards,
    this.height = 400,
  });

  final List<Widget> cards;
  final double height;

  @override
  State<HorizontalCardScroller> createState() => _HorizontalCardScrollerState();
}

class _HorizontalCardScrollerState extends State<HorizontalCardScroller> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView(
            controller: _controller,
            children: widget.cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: card,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        SmoothPageIndicator(
          controller: _controller,
          count: widget.cards.length,
          effect: const ExpandingDotsEffect(
            activeDotColor: AppColors.darkMaroon,
            dotColor: AppColors.dimGray,
            dotHeight: 8,
            dotWidth: 8,
            expansionFactor: 3,
          ),
        ),
      ],
    );
  }
}
