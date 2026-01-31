import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import 'date_range_picker.dart';

/// 新增事件底部彈出表單
class AddEventSheet extends StatefulWidget {
  final DateTime? initialDate;
  final Event? editEvent;

  const AddEventSheet({super.key, this.initialDate, this.editEvent});

  @override
  State<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<AddEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;
  int _selectedColorIndex = 0;

  bool get _isEditing => widget.editEvent != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final event = widget.editEvent!;
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      _startDate = event.startDate;
      _endDate = event.endDate;
      _selectedColorIndex = event.colorIndex;
    } else {
      final initialDate = widget.initialDate ?? DateTime.now();
      _startDate = initialDate;
      _endDate = initialDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 拖曳指示條
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              // 標題
              _buildHeader(),
              const SizedBox(height: 24),
              // 事件名稱
              _buildTitleField(),
              const SizedBox(height: 20),
              // 日期選擇
              _buildDateRow(),
              const SizedBox(height: 20),
              // 顏色選擇
              _buildColorPicker(),
              const SizedBox(height: 20),
              // 備註
              _buildDescriptionField(),
              const SizedBox(height: 24),
              // 按鈕
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
          child: Icon(_isEditing ? Icons.edit_rounded : Icons.add_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Text(
          _isEditing ? '編輯事件' : '新增事件',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(labelText: '事件名稱', hintText: '輸入事件名稱', prefixIcon: Icon(Icons.event_note_rounded)),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '請輸入事件名稱';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildDateRow() {
    final isSameDay = CalendarDateUtils.isSameDay(_startDate, _endDate);

    return GestureDetector(
      onTap: _showDateRangePicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.date_range_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  '事件日期',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDateChip(_startDate, true),
                  if (!isSameDay) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.arrow_forward_rounded, color: AppColors.gradientStart.withValues(alpha: 0.5), size: 18),
                    ),
                    _buildDateChip(_endDate, false),
                  ],
                ],
              ),
            ),
            if (!isSameDay) ...[
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.gradientStart.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    '共 ${_endDate.difference(_startDate).inDays + 1} 天',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gradientStart),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(DateTime date, bool isStart) {
    return Column(
      children: [
        Text(
          isStart ? '開始' : '結束',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          CalendarDateUtils.formatMonthDay(date),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        Text(CalendarDateUtils.formatWeekday(date), style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Future<void> _showDateRangePicker() async {
    final result = await showDateRangePickerDialog(context, initialStartDate: _startDate, initialEndDate: _endDate);

    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
    }
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '選擇顏色',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(AppColors.eventColors.length, (index) {
            final color = AppColors.eventColors[index];
            final isSelected = index == _selectedColorIndex;

            return GestureDetector(
              onTap: () => setState(() => _selectedColorIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 36 : 32,
                height: isSelected ? 36 : 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: AppColors.textPrimary, width: 3) : null,
                  boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))] : null,
                ),
                child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(labelText: '備註（選填）', hintText: '輸入備註', prefixIcon: Icon(Icons.notes_rounded)),
      maxLines: 2,
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.divider),
              ),
            ),
            child: const Text(
              '取消',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.gradientStart.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: ElevatedButton(
              onPressed: _saveEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _isEditing ? '儲存變更' : '新增事件',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<EventProvider>();

    final startDateTime = DateTime(_startDate.year, _startDate.month, _startDate.day);

    final endDateTime = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59);

    if (_isEditing) {
      final updatedEvent = widget.editEvent!.copyWith(title: _titleController.text.trim(), startDate: startDateTime, endDate: endDateTime, isAllDay: true, colorIndex: _selectedColorIndex, description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim());
      provider.updateEvent(updatedEvent);
    } else {
      provider.addEvent(title: _titleController.text.trim(), startDate: startDateTime, endDate: endDateTime, isAllDay: true, colorIndex: _selectedColorIndex, description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim());
    }

    Navigator.pop(context);
  }
}

/// 顯示新增事件表單
void showAddEventSheet(BuildContext context, {DateTime? initialDate, Event? editEvent}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddEventSheet(initialDate: initialDate, editEvent: editEvent),
  );
}
