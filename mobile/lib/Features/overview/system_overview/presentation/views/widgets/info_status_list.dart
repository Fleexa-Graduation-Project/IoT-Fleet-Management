import 'package:flutter/material.dart';
import 'package:fleexa/Features/overview/system_overview/data/models/info_status_model.dart';
import 'package:fleexa/Features/overview/system_overview/presentation/views/widgets/info_status_row.dart';

class InfoStatusList extends StatelessWidget {
  final List<InfoStatusModel> items;
  final double spacing;

  const InfoStatusList({
    super.key,
    required this.items,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        items.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : spacing),
          child: InfoStatusRow(infoStatusModel: items[index]),
        ),
      ),
    );
  }
}
