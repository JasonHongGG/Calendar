import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DateSelectorModal extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onConfirm;

  const DateSelectorModal({
    super.key,
    required this.initialDate,
    required this.onConfirm,
  });

  @override
  State<DateSelectorModal> createState() => _DateSelectorModalState();
}

class _DateSelectorModalState extends State<DateSelectorModal> {
  late int _selectedYear;
  late int _selectedMonth;
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;

  final int _startYear = 1970;
  final int _endYear = 2099;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;

    _yearController = FixedExtentScrollController(
      initialItem: _selectedYear - _startYear,
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate lists for picker
    final years = List.generate(
      _endYear - _startYear + 1,
      (index) => _startYear + index,
    );
    final months = List.generate(12, (index) => index + 1);

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.cardBackground,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Date',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),

            // Picker Area
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Year Picker
                  _buildPickerColumn(
                    items: years.map((e) => e.toString()).toList(),
                    initialItem: _selectedYear - _startYear,
                    fontSize: 26,
                    itemHeight: 40,
                    width: 80,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedYear = _startYear + index;
                      });
                    },
                    controller: _yearController,
                  ),

                  _buildPickerSeparator('/', fontSize: 26, height: 40),

                  // Month Picker
                  _buildPickerColumn(
                    items: months
                        .map((e) => e.toString().padLeft(2, '0'))
                        .toList(),
                    initialItem: _selectedMonth - 1,
                    fontSize: 26,
                    itemHeight: 40,
                    width: 60,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedMonth = index + 1;
                      });
                    },
                    controller: _monthController,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gradientStart.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onConfirm(
                          DateTime(_selectedYear, _selectedMonth),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerColumn({
    required List<String> items,
    required int initialItem,
    required ValueChanged<int> onSelectedItemChanged,
    required FixedExtentScrollController controller,
    double fontSize = 18,
    double width = 60,
    double itemHeight = 32,
  }) {
    return SizedBox(
      width: width,
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: itemHeight,
        onSelectedItemChanged: onSelectedItemChanged,
        squeeze: 1.2,
        diameterRatio: 1.5,
        selectionOverlay: Container(
          decoration: const BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
        ),
        children: items
            .map(
              (item) => Center(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPickerSeparator(
    String text, {
    double fontSize = 18,
    double height = 32,
  }) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      height: height,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
