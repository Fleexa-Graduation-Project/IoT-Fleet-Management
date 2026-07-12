import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:flutter/material.dart';

class CustomRowDetails extends StatelessWidget {
  const CustomRowDetails({
    super.key,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  final String title;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(width: 30),
        Text(
          "• $title",
          style: Styles.style14Medium.copyWith(color: Colors.grey),
        ),
        const Spacer(),
        Text(
          value,
          style: Styles.style14Medium.copyWith(color: valueColor),
        ),
      ],
    );
  }
}
