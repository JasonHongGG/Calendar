import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import 'date_range_picker.dart';
import 'delete_confirmation_dialog.dart';

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
      _selectedColorIndex = -1; // 預設隨機
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
    // 計算內容高度，盡量讓它適應一頁
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 40,
            offset: Offset(0, -10),
          ),
        ],
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
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              // 調整 padding，底部保留安全距離
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
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
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (_isEditing)
                          IconButton(
                            onPressed: _deleteEvent,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                              size: 28,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.withValues(
                                alpha: 0.1,
                              ),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 事件名稱
                    _buildStyledTextField(
                      controller: _titleController,
                      label: '事件名稱',
                      placeholder: '輸入標題...',
                      icon: Icons.edit_rounded,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? '請輸入事件名稱'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // 日期區域
                    _buildDateSection(),
                    const SizedBox(height: 16),

                    // 顏色區域
                    _buildColorSection(),
                    const SizedBox(height: 16),

                    // 備註區域 (高度縮減)
                    _buildStyledTextField(
                      controller: _descriptionController,
                      label: '備註',
                      placeholder: '添加備註...',
                      icon: Icons.notes_rounded,
                      maxLines: 1, // 減少行數至 1 行
                      isLast: true,
                    ),
                    const SizedBox(height: 24),

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

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              isDense: true, // 緊湊佈局
            ),
            validator: validator,
            textInputAction: isLast
                ? TextInputAction.done
                : TextInputAction.next,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    final duration = _endDate.difference(_startDate).inDays + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            '時間',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        GestureDetector(
          onTap: _showDateRangePicker,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
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
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.textTertiary.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gradientStart.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$duration 天',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gradientStart,
                          ),
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

  Widget _buildDateBlock({
    required DateTime date,
    required String label,
    required IconData icon,
    required Color color,
    required CrossAxisAlignment alignment,
  }) {
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          CalendarDateUtils.formatMonthDaySlash(date),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${CalendarDateUtils.formatYear(date)} • ${CalendarDateUtils.formatWeekday(date)}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '標籤顏色',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(
          height: 68, // 再次增加高度以容納更大的發光效果
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 8,
            ), // 增加垂直 padding 讓陰影顯示
            scrollDirection: Axis.horizontal,
            // +1 因為第一個是隨機按鈕
            itemCount: AppColors.eventColors.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                // 隨機按鈕
                return _buildColorItem(
                  index: -1,
                  color: Colors.transparent, // 隨機按鈕用漸層處理
                  isRandom: true,
                );
              }
              // 實際顏色列表 (index - 1 對應到 List)
              final colorIndex = index - 1;
              return _buildColorItem(
                index: colorIndex,
                color: AppColors.eventColors[colorIndex],
                isRandom: false,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorItem({
    required int index,
    required Color color,
    required bool isRandom,
  }) {
    final isSelected = _selectedColorIndex == index;
    final size = isSelected ? 48.0 : 36.0;

    // 定義彩虹漸層
    const rainbowGradient = SweepGradient(
      colors: [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.purple,
        Colors.red,
      ],
    );

    return GestureDetector(
      onTap: () => setState(() => _selectedColorIndex = index),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none, // 允許陰影超出範圍
        children: [
          // 彩虹陰影 (僅在選中且為隨機按鈕時顯示)
          if (isRandom && isSelected)
            Positioned(
              top: 4, // 向下偏移
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: rainbowGradient,
                  ),
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
              boxShadow: (isSelected && !isRandom)
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: isSelected && !isRandom
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : (isRandom && isSelected
                      ? const Icon(
                          Icons.shuffle_rounded,
                          color: Colors.white,
                          size: 20,
                        )
                      : (isRandom
                            ? const Icon(
                                Icons.shuffle_rounded,
                                color: Colors.white70,
                                size: 16,
                              )
                            : null)),
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
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
                Icon(
                  _isEditing ? Icons.save_rounded : Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isEditing ? '儲存變更' : '新增事件',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final result = await showDateRangePickerDialog(
      context,
      initialStartDate: _startDate,
      initialEndDate: _endDate,
    );

    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
    }
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<EventProvider>(context, listen: false);

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
    );

    final endDateTime = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      23,
      59,
    );

    int finalColorIndex;
    if (_selectedColorIndex == -1) {
      // 隨機選擇一個顏色
      finalColorIndex = Random().nextInt(AppColors.eventColors.length);
    } else {
      finalColorIndex = _selectedColorIndex;
    }

    if (_isEditing) {
      final updatedEvent = widget.editEvent!.copyWith(
        title: _titleController.text.trim(),
        startDate: startDateTime,
        endDate: endDateTime,
        isAllDay: true,
        colorIndex: finalColorIndex,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      provider.updateEvent(updatedEvent);
    } else {
      provider.addEvent(
        title: _titleController.text.trim(),
        startDate: startDateTime,
        endDate: endDateTime,
        isAllDay: true,
        colorIndex: finalColorIndex,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
    }

    Navigator.pop(context);
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
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return Transform.scale(
          scale: curvedAnimation.value,
          child: Opacity(
            opacity: animation.value,
            child: _buildDeleteDialog(context),
          ),
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // 內容說明
            Text(
              '確定要刪除「${widget.editEvent!.title}」嗎？\n此動作無法復原。',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
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
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
void showAddEventSheet(
  BuildContext context, {
  DateTime? initialDate,
  Event? editEvent,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) =>
        AddEventSheet(initialDate: initialDate, editEvent: editEvent),
  );
}
