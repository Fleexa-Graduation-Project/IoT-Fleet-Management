import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fleexa/core/utils/constants/app_colors.dart';
import 'package:fleexa/core/utils/constants/styles.dart';
import 'package:fleexa/generated/l10n.dart';
import 'package:go_router/go_router.dart';

class NormalDurationDialog extends StatefulWidget {
  final int initialMinutes;
  final ValueChanged<int> onSaved;

  const NormalDurationDialog({
    super.key,
    required this.initialMinutes,
    required this.onSaved,
  });

  @override
  State<NormalDurationDialog> createState() => _NormalDurationDialogState();
}

class _NormalDurationDialogState extends State<NormalDurationDialog> {
  late TextEditingController _controller;
  late int _currentMinutes;

  @override
  void initState() {
    super.initState();
    _currentMinutes = widget.initialMinutes;
    _controller = TextEditingController(text: _currentMinutes.toString());
  }

  void _updateValue(int newValue) {
    if (newValue < 1 || newValue > 60) return;
    setState(() {
      _currentMinutes = newValue;
      _controller.text = _currentMinutes.toString();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.nearBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Set Normal Duration",
                  style: Styles.style16Medium.copyWith(color: AppColors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.coolGray),
                  onPressed: () => GoRouter.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Controls Row ( - , TextField , + )
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Decrement Button
                _buildActionButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _updateValue(_currentMinutes - 1),
                ),
                const SizedBox(width: 16),

                // TextField for Minutes Input
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style:
                        Styles.style20Medium.copyWith(color: AppColors.white),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.darkGray),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.wineRed),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed >= 1 && parsed <= 60) {
                        _currentMinutes = parsed;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Increment Button
                _buildActionButton(
                  icon: Icons.add_rounded,
                  onTap: () => _updateValue(_currentMinutes + 1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Minutes",
              style: Styles.style12Regular.copyWith(color: AppColors.coolGray),
            ),
            const SizedBox(height: 24),

            // Action Buttons (Cancel / Save)
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => GoRouter.of(context).pop(),
                    child: Text(
                      S.of(context).cancel,
                      style: const TextStyle(color: AppColors.coolGray),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.wineRed,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      widget.onSaved(_currentMinutes);
                      GoRouter.of(context).pop();
                    },
                    child: Text(
                      S.of(context).set,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.darkGray.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.white, size: 20),
      ),
    );
  }
}
