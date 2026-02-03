import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  String _labelForSize(MonthEventTitleSize size) {
    switch (size) {
      case MonthEventTitleSize.medium:
        return '適中';
      case MonthEventTitleSize.large:
        return '放大';
      case MonthEventTitleSize.xlarge:
        return '超大';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('設定'), backgroundColor: Colors.white, foregroundColor: AppColors.textPrimary, elevation: 0, centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.spacingNormal),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingNormal, vertical: AppDimens.spacingNormal),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
              boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '月曆事件標題大小',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text('目前：${_labelForSize(settings.monthEventTitleSize)}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                const SizedBox(height: 12),
                RadioGroup<MonthEventTitleSize>(
                  groupValue: settings.monthEventTitleSize,
                  onChanged: (value) {
                    if (value == null) return;
                    settings.setMonthEventTitleSize(value);
                  },
                  child: Column(
                    children: MonthEventTitleSize.values.map((size) {
                      return RadioListTile<MonthEventTitleSize>(
                        value: size,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          _labelForSize(size),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        activeColor: AppColors.gradientStart,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spacingNormal),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingNormal, vertical: AppDimens.spacingNormal),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
              boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Base URL',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '啟用 AI 指令',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    Switch.adaptive(value: settings.aiEnabled, onChanged: settings.setAiEnabled, activeThumbColor: AppColors.gradientStart, activeTrackColor: AppColors.gradientStart.withValues(alpha: 0.3)),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: settings.aiBaseUrl,
                  decoration: InputDecoration(
                    hintText: 'http://localhost:3000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                  onChanged: settings.setAiBaseUrl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
