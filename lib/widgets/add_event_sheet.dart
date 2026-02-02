import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import 'date_range_picker.dart';
import 'top_notification.dart';

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

  // -1 代表隨機顏色，0~N 代表 AppColors.eventColors 的索引
  int _selectedColorIndex = -1;

  bool _isColorPickerExpanded = false;

  bool get _isEditing => widget.editEvent != null;

  // 提醒功能相關變數
  bool _isReminderEnabled = false;
  DateTime? _reminderTime;
  bool _isReminderExpanded = false;
  int _reminderViewIndex = 0; // 0: 日期, 1: 時間
  Key _pickerKey = UniqueKey();

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

      if (event.reminderTime != null) {
        _isReminderEnabled = true;
        _reminderTime = event.reminderTime!.toLocal();
      } else {
        _isReminderEnabled = false;
        // 預設為開始日期的 00:00
        _reminderTime = DateTime(_startDate.year, _startDate.month, _startDate.day);
      }
    } else {
      final initialDate = widget.initialDate ?? DateTime.now();
      _startDate = initialDate;
      _endDate = initialDate;
      _selectedColorIndex = -1; // 預設隨機

      // 預設為開始日期的 00:00
      _reminderTime = DateTime(_startDate.year, _startDate.month, _startDate.day);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 當我們更改開始日期時，如果提醒時間還沒被手動設定過（或者我們希望保持同步），需要更新預設值
  // 這裡簡單起見，如果提醒時間早於新的開始日期，或者用戶還沒啟用提醒，我們可以更新它
  void _updateDefaultReminderTime() {
    // 預設時間始終保持為開始日期的 00:00，除非用戶手動調整過
    // 但根據需求 "預設就是事件第一天的當天 00:00"，我們在切換日期時同步更新這個默認值比較好
    if (!_isReminderEnabled) {
      _reminderTime = DateTime(_startDate.year, _startDate.month, _startDate.day);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 計算內容高度，盡量讓它適應一頁
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 40, offset: Offset(0, -10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 頂部拖曳條
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(100)),
              ),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              // 調整 padding，底部保留安全距離
              padding: EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 標題
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isEditing ? '編輯事件' : '新增事件',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: -0.5),
                        ),
                        Row(
                          children: [
                            _buildNoteButton(),
                            if (_isEditing)
                              IconButton(
                                onPressed: _deleteEvent,
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 28),
                                style: IconButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.1), padding: const EdgeInsets.all(8)),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 事件名稱 與 顏色選擇器整合
                    _buildTitleWithColorPicker(),
                    const SizedBox(height: 16),

                    // 日期區域
                    _buildDateSection(),
                    const SizedBox(height: 16),

                    // 提醒區域
                    _buildReminderSection(),
                    const SizedBox(height: 16),

                    // 按鈕
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteButton() {
    final hasNote = _descriptionController.text.trim().isNotEmpty;

    return IconButton(
      onPressed: _showDescriptionModal,
      icon: Icon(hasNote ? Icons.sticky_note_2_rounded : Icons.sticky_note_2_outlined, color: hasNote ? AppColors.gradientStart : AppColors.textTertiary, size: 26),
      style: IconButton.styleFrom(backgroundColor: hasNote ? AppColors.gradientStart.withValues(alpha: 0.12) : AppColors.background, padding: const EdgeInsets.all(8)),
      tooltip: '備註',
    );
  }

  void _showDescriptionModal() {
    final tempController = TextEditingController(text: _descriptionController.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, -10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text(
                      '備註',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        _descriptionController.text = tempController.text.trim();
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: const Text('完成'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                  ),
                  child: TextField(
                    controller: tempController,
                    maxLines: 6,
                    minLines: 4,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: '輸入備註內容...',
                      hintStyle: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.normal, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.newline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() => tempController.dispose());
  }

  // ... (TitleWithColorPicker code similar to previous but omitted for brevity if unchanged,
  // but tool requires replacing range. I will assume previous helper methods are unchanged and focus on new one)

  // Need to include _buildTitleWithColorPicker, _buildStyledTextField, _buildDateSection etc
  // because I'm replacing a huge chunk to insert _buildReminderSection.
  // Wait, I can't skip existing code in 'ReplacementContent'. I must provide the FULL content for the range.
  // To minimize token usage and potential errors, I will use multiple replace calls if possible,
  // or just be careful. The user asked me to replace up to saveEvent.

  // Okay, re-reading the "replace_file_content" tool description:
  // "StartLine and EndLine should specify a range of lines containing precisely the instances of TargetContent that you wish to edit."
  // I will target the initState, build method, and insert the new section.

  Widget _buildReminderSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Row 1: Header (Icon + Title + Switch)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _isReminderEnabled ? AppColors.gradientStart.withValues(alpha: 0.1) : AppColors.background, shape: BoxShape.circle),
                child: Icon(Icons.notifications_rounded, size: 20, color: _isReminderEnabled ? AppColors.gradientStart : AppColors.textTertiary),
              ),
              const SizedBox(width: 12),
              const Text(
                '提醒',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final value = !_isReminderEnabled;
                  setState(() {
                    _isReminderEnabled = value;
                    if (value) {
                      _isReminderExpanded = false; // Default to collapsed
                      _reminderViewIndex = -1; // Default to NO selection
                      // Ensure default if null
                      _reminderTime ??= DateTime(_startDate.year, _startDate.month, _startDate.day);
                    } else {
                      _isReminderExpanded = false;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 30,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: _isReminderEnabled ? AppColors.primaryGradient : null, color: _isReminderEnabled ? null : AppColors.textTertiary.withValues(alpha: 0.2)),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: _isReminderEnabled ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Row 2: Date & Time Blocks (Visible if enabled)
          if (_isReminderEnabled && _reminderTime != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                // Date Block
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_isReminderExpanded && _reminderViewIndex == 0) {
                          _isReminderExpanded = false;
                        } else {
                          _reminderViewIndex = 0;
                          _isReminderExpanded = true;
                          _pickerKey = UniqueKey();
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isReminderExpanded && _reminderViewIndex == 0 ? AppColors.gradientStart.withValues(alpha: 0.1) : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: _isReminderExpanded && _reminderViewIndex == 0 ? Border.all(color: AppColors.gradientStart) : Border.all(color: Colors.transparent),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '日期',
                            style: TextStyle(fontSize: 12, color: _isReminderExpanded && _reminderViewIndex == 0 ? AppColors.gradientStart : AppColors.textTertiary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CalendarDateUtils.formatYearMonthDaySlash(_reminderTime!),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isReminderExpanded && _reminderViewIndex == 0 ? AppColors.gradientStart : AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Time Block
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_isReminderExpanded && _reminderViewIndex == 1) {
                          _isReminderExpanded = false;
                        } else {
                          _reminderViewIndex = 1;
                          _isReminderExpanded = true;
                          _pickerKey = UniqueKey();
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isReminderExpanded && _reminderViewIndex == 1 ? AppColors.gradientStart.withValues(alpha: 0.1) : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: _isReminderExpanded && _reminderViewIndex == 1 ? Border.all(color: AppColors.gradientStart) : Border.all(color: Colors.transparent),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '時間',
                            style: TextStyle(fontSize: 12, color: _isReminderExpanded && _reminderViewIndex == 1 ? AppColors.gradientStart : AppColors.textTertiary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CalendarDateUtils.formatTime(_reminderTime!),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isReminderExpanded && _reminderViewIndex == 1 ? AppColors.gradientStart : AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Expanded Picker Area
          AnimatedCrossFade(firstChild: const SizedBox(height: 0), secondChild: _isReminderEnabled ? _buildReminderPicker() : const SizedBox(height: 0), crossFadeState: _isReminderExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst, duration: const Duration(milliseconds: 300), sizeCurve: Curves.easeInOut),
        ],
      ),
    );
  }

  Widget _buildReminderPicker() {
    return Column(
      key: _pickerKey,
      children: [
        const SizedBox(height: 16),
        // Custom Wheel Picker
        SizedBox(
          height: 100, // Compact height for desired visibility (~3 items)
          child: _reminderViewIndex == 0 ? _buildCustomDatePicker() : _buildCustomTimePicker(),
        ),
      ],
    );
  }

  Widget _buildCustomDatePicker() {
    // Basic range for years
    final currentYear = DateTime.now().year;
    // Let's offer a range from 10 years ago to 50 years in future, or just fixed logic
    final years = List.generate(60, (index) => (currentYear - 5) + index);
    final months = List.generate(12, (index) => index + 1);

    // Calculate days in current month to avoid invalid index
    final daysInMonth = DateUtils.getDaysInMonth(_reminderTime!.year, _reminderTime!.month);
    final days = List.generate(daysInMonth, (index) => index + 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Year
        _buildPickerColumn(
          items: years.map((e) => e.toString()).toList(),
          initialItem: years.indexOf(_reminderTime!.year).clamp(0, years.length - 1),
          fontSize: 26,
          itemHeight: 40,
          width: 80, // Reduced from 90
          onSelectedItemChanged: (index) {
            final newYear = years[index];
            final maxDays = DateUtils.getDaysInMonth(newYear, _reminderTime!.month);
            final newDay = min(_reminderTime!.day, maxDays);
            setState(() {
              _reminderTime = DateTime(newYear, _reminderTime!.month, newDay, _reminderTime!.hour, _reminderTime!.minute);
            });
          },
        ),
        _buildPickerSeparator('/', fontSize: 26, height: 40),
        // Month
        _buildPickerColumn(
          items: months.map((e) => e.toString().padLeft(2, '0')).toList(),
          initialItem: _reminderTime!.month - 1,
          fontSize: 26,
          itemHeight: 40,
          width: 60, // Reduced from 70
          onSelectedItemChanged: (index) {
            final newMonth = index + 1;
            final maxDays = DateUtils.getDaysInMonth(_reminderTime!.year, newMonth);
            final newDay = min(_reminderTime!.day, maxDays);
            setState(() {
              _reminderTime = DateTime(_reminderTime!.year, newMonth, newDay, _reminderTime!.hour, _reminderTime!.minute);
            });
          },
        ),
        _buildPickerSeparator('/', fontSize: 26, height: 40),
        // Day
        _buildPickerColumn(
          items: days.map((e) => e.toString().padLeft(2, '0')).toList(),
          initialItem: _reminderTime!.day - 1,
          fontSize: 26,
          itemHeight: 40,
          width: 60, // Reduced from 70
          onSelectedItemChanged: (index) {
            final newDay = index + 1;
            setState(() {
              _reminderTime = DateTime(_reminderTime!.year, _reminderTime!.month, newDay, _reminderTime!.hour, _reminderTime!.minute);
            });
          },
          // Key to refresh day picker if days count changes
          key: ValueKey('day_picker_${daysInMonth}'),
        ),
      ],
    );
  }

  Widget _buildCustomTimePicker() {
    final hours = List.generate(24, (index) => index);
    final minutes = List.generate(60, (index) => index);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Hour
        _buildPickerColumn(
          items: hours.map((e) => e.toString().padLeft(2, '0')).toList(),
          initialItem: _reminderTime!.hour,
          fontSize: 32, // Much larger for Time
          itemHeight: 45,
          width: 80,
          onSelectedItemChanged: (index) {
            setState(() {
              _reminderTime = DateTime(_reminderTime!.year, _reminderTime!.month, _reminderTime!.day, index, _reminderTime!.minute);
            });
          },
        ),
        _buildPickerSeparator(':', fontSize: 26, height: 45),
        // Minute
        _buildPickerColumn(
          items: minutes.map((e) => e.toString().padLeft(2, '0')).toList(),
          initialItem: _reminderTime!.minute,
          fontSize: 32, // Much larger for Time
          itemHeight: 45,
          width: 80,
          onSelectedItemChanged: (index) {
            setState(() {
              _reminderTime = DateTime(_reminderTime!.year, _reminderTime!.month, _reminderTime!.day, _reminderTime!.hour, index);
            });
          },
        ),
      ],
    );
  }

  Widget _buildPickerColumn({required List<String> items, required int initialItem, required ValueChanged<int> onSelectedItemChanged, Key? key, double fontSize = 18, double width = 60, double itemHeight = 32}) {
    return SizedBox(
      width: width,
      child: CupertinoPicker(
        key: key,
        scrollController: FixedExtentScrollController(initialItem: initialItem),
        itemExtent: itemHeight, // Compact item height
        onSelectedItemChanged: onSelectedItemChanged,
        squeeze: 1.2, // Tighter spacing
        diameterRatio: 1.5, // Tighter curve
        selectionOverlay: Container(
          decoration: const BoxDecoration(
            border: Border.symmetric(horizontal: BorderSide(color: AppColors.divider, width: 0.5)),
          ),
        ),
        children: items
            .map(
              (item) => Center(
                child: Text(
                  item,
                  style: TextStyle(fontSize: fontSize, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPickerSeparator(String text, {double fontSize = 18, double height = 32}) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      height: height,
      child: Text(
        text,
        style: TextStyle(fontSize: fontSize, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<EventProvider>(context, listen: false);

    final startDateTime = DateTime(_startDate.year, _startDate.month, _startDate.day);

    final endDateTime = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59);

    int finalColorIndex;
    if (_selectedColorIndex == -1) {
      // 隨機選擇一個顏色
      finalColorIndex = Random().nextInt(AppColors.eventColors.length);
    } else {
      finalColorIndex = _selectedColorIndex;
    }

    final reminderToSave = _isReminderEnabled ? _reminderTime?.toLocal() : null;
    if (_isReminderEnabled && reminderToSave != null) {
      final now = DateTime.now();
      if (!reminderToSave.isAfter(now)) {
        if (context.mounted) {
          NotificationOverlay.show(context: context, message: '提醒時間需晚於現在，請重新設定提醒時間', type: NotificationType.error);
        }
        return;
      }
    }

    if (_isEditing) {
      final updatedEvent = widget.editEvent!.copyWith(title: _titleController.text.trim(), startDate: startDateTime, endDate: endDateTime, isAllDay: true, colorIndex: finalColorIndex, description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(), reminderTime: reminderToSave);
      provider.updateEvent(updatedEvent);
    } else {
      provider.addEvent(title: _titleController.text.trim(), startDate: startDateTime, endDate: endDateTime, isAllDay: true, colorIndex: finalColorIndex, description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(), reminderTime: reminderToSave);
    }

    if (context.mounted && reminderToSave != null) {
      NotificationOverlay.show(context: context, message: '已設定提醒：${_titleController.text.trim()}（${CalendarDateUtils.formatYearMonthDaySlash(reminderToSave)} ${CalendarDateUtils.formatTime(reminderToSave)}）', type: NotificationType.success);
    }

    Navigator.pop(context);
  }

  Widget _buildTitleWithColorPicker() {
    // 獲取當前顏色
    Color currentColor;
    if (_selectedColorIndex == -1) {
      currentColor = Colors.transparent; // 隨機顏色使用特殊顯示
    } else {
      currentColor = AppColors.eventColors[_selectedColorIndex];
    }

    const rainbowGradient = SweepGradient(colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple, Colors.red]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 移除外層裝飾容器
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          child: Row(
            children: [
              // 顏色選擇切換按鈕
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isColorPickerExpanded = !_isColorPickerExpanded;
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedColorIndex == -1 ? null : currentColor,
                    gradient: _selectedColorIndex == -1 ? rainbowGradient : null,
                    boxShadow: [BoxShadow(color: (_selectedColorIndex == -1 ? AppColors.gradientStart : currentColor).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: _selectedColorIndex == -1 ? const Icon(Icons.shuffle_rounded, color: Colors.white, size: 16) : (_isColorPickerExpanded ? const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 20) : const Icon(Icons.edit_rounded, color: Colors.white, size: 16)),
                ),
              ),

              const SizedBox(width: 12),

              // 分隔線
              Container(width: 1, height: 24, color: AppColors.divider),

              const SizedBox(width: 4),

              // 標題輸入框
              Expanded(
                child: TextFormField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: '輸入標題...',
                    hintStyle: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.normal, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? '請輸入事件名稱' : null,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ],
          ),
        ),

        // 可展開的顏色選擇列
        AnimatedCrossFade(
          firstChild: const SizedBox(height: 0),
          secondChild: Padding(padding: const EdgeInsets.only(top: 12), child: _buildColorSelectionRow()),
          crossFadeState: _isColorPickerExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeOutBack,
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    final duration = _endDate.difference(_startDate).inDays + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showDateRangePicker,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
              boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                // 開始日期 (左側，佔比 1)
                Expanded(
                  flex: 1,
                  child: _buildDateBlock(
                    date: _startDate,
                    label: '開始',
                    icon: Icons.calendar_today_rounded,
                    color: AppColors.gradientStart,
                    alignment: CrossAxisAlignment.center, // 改為置中
                  ),
                ),

                // 中間箭頭與天數 (置中，固定寬度或自適應但確保居中)
                Container(
                  constraints: const BoxConstraints(minWidth: 60),
                  child: Column(
                    children: [
                      Icon(Icons.arrow_forward_rounded, color: AppColors.textTertiary.withValues(alpha: 0.5), size: 20),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.gradientStart.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          '$duration 天',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gradientStart),
                        ),
                      ),
                    ],
                  ),
                ),

                // 結束日期 (右側，佔比 1，對齊右邊)
                Expanded(
                  flex: 1,
                  child: _buildDateBlock(
                    date: _endDate,
                    label: '結束',
                    icon: Icons.event_available_rounded,
                    color: AppColors.gradientEnd,
                    alignment: CrossAxisAlignment.center, // 改為置中
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateBlock({required DateTime date, required String label, required IconData icon, required Color color, required CrossAxisAlignment alignment}) {
    // 確保內容相對於所在區塊對齊
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min, // 緊縮 Row 以便對齊
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          CalendarDateUtils.formatMonthDaySlash(date),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
        ),
        const SizedBox(height: 2),
        Text(
          '${CalendarDateUtils.formatYear(date)} • ${CalendarDateUtils.formatWeekday(date)}',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textTertiary),
        ),
      ],
    );
  }

  // 僅保留橫向顏色選擇列表的邏輯
  Widget _buildColorSelectionRow() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        scrollDirection: Axis.horizontal,
        itemCount: AppColors.eventColors.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildColorItem(index: -1, color: Colors.transparent, isRandom: true);
          }
          final colorIndex = index - 1;
          return _buildColorItem(index: colorIndex, color: AppColors.eventColors[colorIndex], isRandom: false);
        },
      ),
    );
  }

  Widget _buildColorItem({required int index, required Color color, required bool isRandom}) {
    final isSelected = _selectedColorIndex == index;
    final size = isSelected ? 48.0 : 36.0;

    // 定義彩虹漸層
    const rainbowGradient = SweepGradient(colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple, Colors.red]);

    return GestureDetector(
      onTap: () => setState(() => _selectedColorIndex = index),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none, // 允許陰影超出範圍
        children: [
          // 彩虹陰影 (僅在選中且為隨機按鈕時顯示)
          if (isRandom && isSelected)
            Transform.translate(
              offset: const Offset(0, 4), // 向下偏移
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: rainbowGradient),
                ),
              ),
            ),

          // 按鈕本體
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              // 如果是隨機，使用彩虹漸層
              gradient: isRandom ? rainbowGradient : null,
              color: isRandom ? null : color,
              shape: BoxShape.circle,
              // 普通顏色的陰影邏輯維持不變
              boxShadow: (isSelected && !isRandom) ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))] : null,
            ),
            child: isSelected && !isRandom ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : (isRandom && isSelected ? const Icon(Icons.shuffle_rounded, color: Colors.white, size: 20) : (isRandom ? const Icon(Icons.shuffle_rounded, color: Colors.white70, size: 16) : null)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.gradientStart.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _saveEvent,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  _isEditing ? '儲存變更' : '新增事件',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final result = await showDateRangePickerDialog(context, initialStartDate: _startDate, initialEndDate: _endDate);

    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
        _updateDefaultReminderTime();
      });
    }
  }

  void _deleteEvent() async {
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox(); // 略過因為我們在 transitionBuilder 構建
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // 彈跳動畫曲線
        final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);

        return Transform.scale(
          scale: curvedAnimation.value,
          child: Opacity(opacity: animation.value, child: _buildDeleteDialog(context)),
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      final provider = Provider.of<EventProvider>(context, listen: false);
      provider.deleteEvent(widget.editEvent!.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Widget _buildDeleteDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 16,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 危險圖示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2), // 紅色背景
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_rounded,
                color: Color(0xFFEF4444), // 紅色圖示
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // 標題
            const Text(
              '刪除事件',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),

            // 內容說明
            Text(
              '確定要刪除「${widget.editEvent!.title}」嗎？\n此動作無法復原。',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),

            // 按鈕排
            Row(
              children: [
                // 取消按鈕
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 刪除按鈕 (漸層背景)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, true),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              '確認刪除',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
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
}

/// 顯示新增事件表單
void showAddEventSheet(BuildContext context, {DateTime? initialDate, Event? editEvent}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: AddEventSheet(initialDate: initialDate, editEvent: editEvent),
    ),
  );
}
