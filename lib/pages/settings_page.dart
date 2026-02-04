import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import '../services/backup_meta_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../widgets/top_notification.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _exportJson(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final eventsProvider = context.read<EventProvider>();

    final now = DateTime.now();
    final fileName = 'calendar-backup-${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.json';

    final backup = CalendarBackup(version: CalendarBackup.currentVersion, exportedAt: now, settings: BackupCodec.settingsToJson(settings), events: eventsProvider.events);

    final jsonString = backup.toJsonString(pretty: true);

    try {
      // On Android/iOS, file_picker requires bytes to be provided when saving.
      if (Platform.isAndroid || Platform.isIOS) {
        final bytes = Uint8List.fromList(utf8.encode(jsonString));
        final saved = await FilePicker.platform.saveFile(dialogTitle: '匯出備份（JSON）', fileName: fileName, type: FileType.custom, allowedExtensions: const ['json'], bytes: bytes);
        if (!context.mounted) return;
        NotificationOverlay.show(context: context, message: saved == null ? '已匯出' : '已匯出：$saved', type: NotificationType.success);
        return;
      }

      // Desktop platforms: ask for a path then write via dart:io
      final savePath = await FilePicker.platform.saveFile(dialogTitle: '匯出備份（JSON）', fileName: fileName, type: FileType.custom, allowedExtensions: const ['json']);

      if (savePath == null) return;
      await File(savePath).writeAsString(jsonString, flush: true);
      if (!context.mounted) return;
      NotificationOverlay.show(context: context, message: '已匯出：$savePath', type: NotificationType.success);
    } catch (e) {
      if (!context.mounted) return;
      NotificationOverlay.show(context: context, message: '匯出失敗：$e', type: NotificationType.error);
    }
  }

  Future<void> _importJson(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(dialogTitle: '匯入備份（JSON）', type: FileType.custom, allowedExtensions: const ['json'], withData: true);

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    String content;
    try {
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        throw const FileSystemException('No readable file content');
      }
    } catch (e) {
      if (!context.mounted) return;
      NotificationOverlay.show(context: context, message: '讀取檔案失敗：$e', type: NotificationType.error);
      return;
    }

    CalendarBackup backup;
    try {
      backup = CalendarBackup.fromJsonString(content);
    } catch (e) {
      if (!context.mounted) return;
      NotificationOverlay.show(context: context, message: 'JSON 格式不正確：$e', type: NotificationType.error);
      return;
    }

    final settingsProvider = context.read<SettingsProvider>();
    final eventProvider = context.read<EventProvider>();

    final existingIds = eventProvider.events.map((e) => e.id).toSet();
    final importedEvents = BackupCodec.normalizeImportedEvents(backup.events);
    final importIds = importedEvents.map((e) => e.id).toSet();
    final willUpdate = importIds.where(existingIds.contains).length;
    final willAdd = importIds.length - willUpdate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('確認匯入'),
          content: Text('匯入會「合併」到目前資料：\n同 id 會更新，沒有的會新增。\n\n即將新增：$willAdd 筆\n即將更新：$willUpdate 筆'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('合併匯入')),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      BackupCodec.applySettingsFromJson(settingsProvider, backup.settings);
      await eventProvider.mergeEvents(importedEvents);
      if (!context.mounted) return;
      NotificationOverlay.show(context: context, message: '匯入完成', type: NotificationType.success);
    } catch (e) {
      if (!context.mounted) return;
      NotificationOverlay.show(context: context, message: '匯入失敗：$e', type: NotificationType.error);
    }
  }

  Future<void> _restoreLastDelete(BuildContext context) async {
    final metaStore = BackupMetaStore();
    final jsonString = await metaStore.getLastDeleteBackupJson();
    if (jsonString == null) {
      if (!context.mounted) return;
      NotificationOverlay.show(context: context, message: '沒有可復原的刪除紀錄', type: NotificationType.info);
      return;
    }

    CalendarBackup backup;
    try {
      backup = CalendarBackup.fromJsonString(jsonString);
    } catch (e) {
      if (!context.mounted) return;
      NotificationOverlay.show(context: context, message: '復原失敗：備份損毀（$e）', type: NotificationType.error);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('復原上次刪除'),
          content: const Text('將以備份內容覆蓋目前事件（不影響設定）。'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('復原')),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final eventProvider = context.read<EventProvider>();
    try {
      await eventProvider.replaceAllEvents(BackupCodec.normalizeImportedEvents(backup.events));
      await metaStore.clearLastDeleteBackup();
      if (!context.mounted) return;
      NotificationOverlay.show(context: context, message: '已復原', type: NotificationType.success);
    } catch (e) {
      if (!context.mounted) return;
      NotificationOverlay.show(context: context, message: '復原失敗：$e', type: NotificationType.error);
    }
  }

  Future<void> _deleteAllData(BuildContext context) async {
    final settingsProvider = context.read<SettingsProvider>();
    final eventProvider = context.read<EventProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('刪除所有事件'),
          content: const Text('將刪除所有事件（不影響設定）。\n此操作可復原（會先建立備份）。'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('取消')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('刪除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final now = DateTime.now();
    final backup = CalendarBackup(version: CalendarBackup.currentVersion, exportedAt: now, settings: BackupCodec.settingsToJson(settingsProvider), events: eventProvider.events);
    final jsonString = backup.toJsonString(pretty: false);

    final metaStore = BackupMetaStore();
    try {
      await metaStore.saveLastDeleteBackupJson(jsonString);

      await eventProvider.clearAllEvents();
      // Keep settings unchanged

      if (!context.mounted) return;

      NotificationOverlay.show(
        context: context,
        message: '已刪除所有事件',
        type: NotificationType.info,
        duration: const Duration(seconds: 8),
        actionLabel: '復原',
        onAction: () async {
          try {
            final restoreBackup = CalendarBackup.fromJsonString(jsonString);
            await eventProvider.replaceAllEvents(BackupCodec.normalizeImportedEvents(restoreBackup.events));
            await metaStore.clearLastDeleteBackup();
            if (!context.mounted) return;
            NotificationOverlay.show(context: context, message: '已復原', type: NotificationType.success);
          } catch (e) {
            if (!context.mounted) return;
            NotificationOverlay.show(context: context, message: '復原失敗：$e', type: NotificationType.error);
          }
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      NotificationOverlay.show(context: context, message: '刪除失敗：$e', type: NotificationType.error);
    }
  }

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
                  '資料匯入 / 匯出（JSON）',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.download_rounded, color: AppColors.gradientStart),
                  title: const Text(
                    '匯出備份',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  subtitle: const Text('輸出事件與設定為 JSON 檔', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  onTap: () => _exportJson(context),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.upload_rounded, color: AppColors.gradientStart),
                  title: const Text(
                    '匯入備份',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  subtitle: const Text('從 JSON 檔合併匯入（同 id 更新/不存在新增）', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  onTap: () => _importJson(context),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history_rounded, color: AppColors.gradientStart),
                  title: const Text(
                    '復原上次刪除',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  subtitle: const Text('從最後一次刪除所建立的備份復原事件', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  onTap: () => _restoreLastDelete(context),
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
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '危險操作',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                  title: const Text(
                    '刪除所有事件（可復原）',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  subtitle: const Text('會先建立備份，可用「復原」或「復原上次刪除」找回事件', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  onTap: () => _deleteAllData(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
