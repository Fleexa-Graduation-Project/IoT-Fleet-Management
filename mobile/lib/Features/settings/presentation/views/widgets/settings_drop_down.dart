import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/constants/styles.dart';

class SettingsDropDown<T> extends StatelessWidget {
  const SettingsDropDown({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    required this.labelBuilder,
    this.minWidth = 60,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        dropdownColor: AppColors.charcoalBlack,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.coolGray,
          size: 20,
        ),
        style: Styles.style14Medium.copyWith(color: AppColors.white),
        selectedItemBuilder: (context) {
          return items.map(
            (item) {
              return Container(
                alignment: Alignment.centerRight,
                constraints: BoxConstraints(minWidth: minWidth),
                child: Text(
                  labelBuilder(item),
                  style: Styles.style14Medium.copyWith(color: AppColors.white),
                ),
              );
            },
          ).toList();
        },
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  labelBuilder(item),
                  style: Styles.style14Medium.copyWith(color: AppColors.white),
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}
