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

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _hasLastDeleteBackup = false;

  @override
  void initState() {
    super.initState();
    _refreshHasLastDeleteBackup();
  }

  Future<void> _refreshHasLastDeleteBackup() async {
    final metaStore = BackupMetaStore();
    final jsonString = await metaStore.getLastDeleteBackupJson();
    if (!mounted) return;
    setState(() {
      _hasLastDeleteBackup = jsonString != null;
    });
  }

  Future<void> _showSettingsModal(BuildContext context, {required String title, String? description, required Widget child, String closeLabel = '關閉', String? primaryLabel, Future<void> Function()? onPrimary, bool primaryDestructive = false, Widget? headerTrailing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: _SettingsModal(
            title: title,
            description: description,
            closeLabel: closeLabel,
            primaryLabel: primaryLabel,
            primaryDestructive: primaryDestructive,
            headerTrailing: headerTrailing,
            onPrimary: onPrimary == null
                ? null
                : () async {
                    Navigator.of(sheetContext).maybePop();
                    await onPrimary();
                  },
            child: child,
          ),
        );
      },
    );
  }

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

  String _labelForEventColorTone(EventColorTone tone) {
    switch (tone) {
      case EventColorTone.normal:
        return '一般';
      case EventColorTone.light:
        return '淺色';
      case EventColorTone.lightest:
        return '最淺';
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
          _SectionLabel('偏好設定'),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.text_fields_rounded,
                title: '月曆事件標題大小',
                subtitle: '目前：${_labelForSize(settings.monthEventTitleSize)}',
                onTap: () {
                  _showSettingsModal(
                    context,
                    title: '月曆事件標題大小',
                    description: '調整月曆格子中的事件標題顯示大小。',
                    closeLabel: '完成',
                    child: Consumer<SettingsProvider>(
                      builder: (context, settings, _) {
                        return RadioGroup<MonthEventTitleSize>(
                          groupValue: settings.monthEventTitleSize,
                          onChanged: (value) {
                            if (value == null) return;
                            settings.setMonthEventTitleSize(value);
                          },
                          child: Column(
                            children: MonthEventTitleSize.values
                                .map(
                                  (size) => RadioListTile<MonthEventTitleSize>(
                                    value: size,
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    title: Text(
                                      _labelForSize(size),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    ),
                                    activeColor: AppColors.gradientStart,
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              _SettingsDivider(),
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: '事件顏色深淺',
                subtitle: '目前：${_labelForEventColorTone(settings.eventColorTone)}',
                onTap: () {
                  _showSettingsModal(
                    context,
                    title: '事件顏色深淺',
                    description: '調整全系統事件顏色呈現的深淺（包含月/週檢視、列表、圓點與選色）。',
                    closeLabel: '完成',
                    child: Consumer<SettingsProvider>(
                      builder: (context, settings, _) {
                        return RadioGroup<EventColorTone>(
                          groupValue: settings.eventColorTone,
                          onChanged: (value) {
                            if (value == null) return;
                            settings.setEventColorTone(value);
                          },
                          child: Column(
                            children: EventColorTone.values
                                .map(
                                  (tone) => RadioListTile<EventColorTone>(
                                    value: tone,
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    title: Text(
                                      _labelForEventColorTone(tone),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    ),
                                    activeColor: AppColors.gradientStart,
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingLarge),

          _SectionLabel('AI'),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.auto_awesome_rounded,
                title: 'AI 指令',
                subtitle: settings.aiEnabled ? '已啟用' : '已停用',
                onTap: () {
                  final controller = TextEditingController(text: context.read<SettingsProvider>().aiBaseUrl);
                  _showSettingsModal(
                    context,
                    title: 'AI 指令',
                    description: '設定 AI 指令伺服器連線位置。',
                    closeLabel: '完成',
                    headerTrailing: Consumer<SettingsProvider>(
                      builder: (context, settings, _) {
                        return _HeaderToggle(value: settings.aiEnabled, onChanged: settings.setAiEnabled);
                      },
                    ),
                    child: Consumer<SettingsProvider>(
                      builder: (context, settings, _) {
                        return Column(
                          children: [
                            TextField(
                              controller: controller,
                              enabled: settings.aiEnabled,
                              decoration: InputDecoration(
                                hintText: 'https://example.com',
                                filled: true,
                                fillColor: settings.aiEnabled ? AppColors.dividerLight : AppColors.dividerLight.withValues(alpha: 0.65),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                                  borderSide: BorderSide(color: AppColors.dividerLight.withValues(alpha: 0.9), width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                                  borderSide: BorderSide(color: AppColors.gradientStart.withValues(alpha: 0.45), width: 1.2),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                                  borderSide: BorderSide(color: AppColors.dividerLight.withValues(alpha: 0.9), width: 1),
                                ),
                              ),
                              onChanged: settings.setAiBaseUrl,
                            ),
                            const SizedBox(height: 10),
                            _HintText('小提示：Android 模擬器連本機可用 http://10.0.2.2:3000'),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingLarge),

          _SectionLabel('資料管理'),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.download_rounded,
                title: '匯出備份（JSON）',
                subtitle: '輸出事件與設定',
                onTap: () {
                  _showSettingsModal(
                    context,
                    title: '匯出備份（JSON）',
                    description: '將事件與設定輸出成 JSON 檔案。',
                    closeLabel: '取消',
                    primaryLabel: '開始匯出',
                    onPrimary: () => _exportJson(context),
                    child: const _InfoPanel(title: '會包含：', bullets: ['事件清單', 'AI 設定', '月曆事件標題大小', '事件顏色深淺']),
                  );
                },
              ),
              _SettingsDivider(),
              _SettingsTile(
                icon: Icons.upload_rounded,
                title: '匯入備份（合併）',
                subtitle: '同 id 更新，沒有的新增',
                onTap: () {
                  _showImportMergeModal(context);
                },
              ),
              if (_hasLastDeleteBackup) ...[
                _SettingsDivider(),
                _SettingsTile(
                  icon: Icons.history_rounded,
                  title: '復原上次刪除',
                  subtitle: '用最後一次刪除前的備份覆蓋事件',
                  onTap: () {
                    _showSettingsModal(
                      context,
                      title: '復原上次刪除',
                      description: '會以「上次刪除前」自動建立的備份覆蓋目前事件（不影響設定）。',
                      closeLabel: '取消',
                      primaryLabel: '復原',
                      onPrimary: () async {
                        final metaStore = BackupMetaStore();
                        final jsonString = await metaStore.getLastDeleteBackupJson();
                        if (jsonString == null) {
                          if (!context.mounted) return;
                          NotificationOverlay.show(context: context, message: '沒有可復原的刪除紀錄', type: NotificationType.info);
                          await _refreshHasLastDeleteBackup();
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

                        if (!context.mounted) return;
                        final eventProvider = context.read<EventProvider>();
                        try {
                          await eventProvider.replaceAllEvents(BackupCodec.normalizeImportedEvents(backup.events));
                          await metaStore.clearLastDeleteBackup();
                          await _refreshHasLastDeleteBackup();
                          if (!context.mounted) return;
                          NotificationOverlay.show(context: context, message: '已復原', type: NotificationType.success);
                        } catch (e) {
                          if (!context.mounted) return;
                          NotificationOverlay.show(context: context, message: '復原失敗：$e', type: NotificationType.error);
                        }
                      },
                      child: const _InfoPanel(title: '注意事項：', bullets: ['只會覆蓋事件，不影響設定', '復原後會清除這筆刪除紀錄']),
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: AppDimens.spacingLarge),

          _SectionLabel('危險操作'),
          _SettingsCard(
            accentBorderColor: Colors.redAccent.withValues(alpha: 0.35),
            children: [
              _SettingsTile(
                icon: Icons.delete_forever_rounded,
                iconColor: Colors.redAccent,
                title: '刪除所有事件（可復原）',
                subtitle: '會先建立備份，可立即復原',
                onTap: () {
                  _showSettingsModal(
                    context,
                    title: '刪除所有事件',
                    description: '將刪除所有事件（不影響設定）。此操作可復原（會先建立備份）。',
                    closeLabel: '取消',
                    primaryLabel: '刪除',
                    primaryDestructive: true,
                    onPrimary: () async {
                      final settingsProvider = context.read<SettingsProvider>();
                      final eventProvider = context.read<EventProvider>();

                      final now = DateTime.now();
                      final backup = CalendarBackup(version: CalendarBackup.currentVersion, exportedAt: now, settings: BackupCodec.settingsToJson(settingsProvider), events: eventProvider.events);
                      final jsonString = backup.toJsonString(pretty: false);

                      final metaStore = BackupMetaStore();
                      try {
                        await metaStore.saveLastDeleteBackupJson(jsonString);
                        await _refreshHasLastDeleteBackup();

                        await eventProvider.clearAllEvents();

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
                              await _refreshHasLastDeleteBackup();
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
                    },
                    child: const _InfoPanel(title: '你將會：', bullets: ['刪除所有事件', '自動建立可復原備份', '可在通知列或「復原上次刪除」找回'], tone: _InfoTone.danger),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showImportMergeModal(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        CalendarBackup? parsed;
        int? willAdd;
        int? willUpdate;
        String? error;
        bool busy = false;

        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: StatefulBuilder(
            builder: (context2, setState) {
              Future<void> pickAndParse() async {
                setState(() {
                  busy = true;
                  error = null;
                });
                try {
                  final result = await FilePicker.platform.pickFiles(dialogTitle: '匯入備份（JSON）', type: FileType.custom, allowedExtensions: const ['json'], withData: true);

                  if (!sheetContext.mounted) return;

                  if (result == null || result.files.isEmpty) {
                    setState(() {
                      busy = false;
                    });
                    return;
                  }

                  final file = result.files.single;
                  String content;
                  if (file.bytes != null) {
                    content = utf8.decode(file.bytes!);
                  } else if (file.path != null) {
                    content = await File(file.path!).readAsString();
                    if (!sheetContext.mounted) return;
                  } else {
                    throw const FileSystemException('No readable file content');
                  }

                  final backup = CalendarBackup.fromJsonString(content);

                  if (!sheetContext.mounted) return;

                  final eventProvider = context2.read<EventProvider>();
                  final existingIds = eventProvider.events.map((e) => e.id).toSet();
                  final importedEvents = BackupCodec.normalizeImportedEvents(backup.events);
                  final importIds = importedEvents.map((e) => e.id).toSet();
                  final updates = importIds.where(existingIds.contains).length;
                  final adds = importIds.length - updates;

                  setState(() {
                    parsed = backup;
                    willAdd = adds;
                    willUpdate = updates;
                    busy = false;
                  });
                } catch (e) {
                  setState(() {
                    parsed = null;
                    willAdd = null;
                    willUpdate = null;
                    busy = false;
                    error = e.toString();
                  });
                }
              }

              Future<void> doImport() async {
                final backup = parsed;
                if (backup == null) return;
                setState(() {
                  busy = true;
                  error = null;
                });
                try {
                  final settingsProvider = context2.read<SettingsProvider>();
                  final eventProvider = context2.read<EventProvider>();
                  final importedEvents = BackupCodec.normalizeImportedEvents(backup.events);

                  BackupCodec.applySettingsFromJson(settingsProvider, backup.settings);
                  await eventProvider.mergeEvents(importedEvents);
                  if (!context.mounted) return;
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).maybePop();
                  NotificationOverlay.show(context: context, message: '匯入完成', type: NotificationType.success);
                } catch (e) {
                  if (!context.mounted) return;
                  setState(() {
                    busy = false;
                    error = e.toString();
                  });
                  NotificationOverlay.show(context: context, message: '匯入失敗：$e', type: NotificationType.error);
                }
              }

              final canImport = parsed != null && busy == false;

              return _SettingsModal(
                title: '匯入備份（合併）',
                description: '從 JSON 檔合併匯入：同 id 會更新，沒有的會新增。',
                closeLabel: '取消',
                primaryLabel: canImport ? '合併匯入' : '選擇檔案',
                onPrimary: () async {
                  if (busy) return;
                  if (parsed == null) {
                    await pickAndParse();
                    return;
                  }
                  await doImport();
                },
                child: Column(
                  children: [
                    if (parsed == null) ...[
                      const _InfoPanel(title: '匯入內容：', bullets: ['事件會以 id 合併（更新/新增）', '設定會套用（AI、標題大小等）']),
                      const SizedBox(height: 12),
                      if (busy) const _BusyRow(label: '讀取檔案中...'),
                      if (error != null) ...[const SizedBox(height: 12), _ErrorText('解析失敗：$error')],
                    ] else ...[
                      _InfoPanel(title: '即將變更：', bullets: ['新增：${willAdd ?? 0} 筆', '更新：${willUpdate ?? 0} 筆', '設定：將依備份內容套用']),
                      const SizedBox(height: 12),
                      if (busy) const _BusyRow(label: '匯入中...'),
                      if (error != null) ...[const SizedBox(height: 12), _ErrorText('匯入失敗：$error')],
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () {
                                setState(() {
                                  parsed = null;
                                  willAdd = null;
                                  willUpdate = null;
                                  error = null;
                                });
                              },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('重新選擇檔案'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.spacingSmall),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textTertiary.withValues(alpha: 0.95), letterSpacing: 1.2),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final Color? accentBorderColor;
  const _SettingsCard({required this.children, this.accentBorderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))],
        border: accentBorderColor == null ? null : Border.all(color: accentBorderColor!),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.dividerLight);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, this.iconColor, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final leadingBg = (iconColor ?? AppColors.gradientStart).withValues(alpha: 0.12);
    final leadingFg = iconColor ?? AppColors.gradientStart;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingNormal, vertical: AppDimens.spacingMedium),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: leadingBg, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: leadingFg, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary.withValues(alpha: 0.9)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsModal extends StatelessWidget {
  final String title;
  final String? description;
  final String closeLabel;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryDestructive;
  final Widget child;
  final Widget? headerTrailing;

  const _SettingsModal({required this.title, this.description, required this.closeLabel, this.primaryLabel, this.onPrimary, this.primaryDestructive = false, required this.child, this.headerTrailing});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimens.radiusXLarge);
    final canPrimary = primaryLabel != null && onPrimary != null;

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          boxShadow: [BoxShadow(color: const Color(0xFF000000).withValues(alpha: 0.12), blurRadius: 22, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(100)),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingNormal),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ),
                  if (headerTrailing != null) ...[headerTrailing!, const SizedBox(width: 6)],
                  IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.close_rounded), color: AppColors.textTertiary, splashRadius: 22),
                ],
              ),
            ),
            if (description != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(AppDimens.spacingNormal, 0, AppDimens.spacingNormal, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    description!,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textTertiary, height: 1.35),
                  ),
                ),
              ),
            ],
            Flexible(
              child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(AppDimens.spacingNormal, 0, AppDimens.spacingNormal, AppDimens.spacingLarge), child: child),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimens.spacingNormal, 0, AppDimens.spacingNormal, AppDimens.spacingNormal),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.9)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMedium)),
                      ),
                      child: Text(closeLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  if (canPrimary) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: onPrimary,
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryDestructive ? Colors.redAccent : AppColors.gradientStart,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMedium)),
                        ),
                        child: Text(primaryLabel!, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

enum _InfoTone { normal, danger }

class _InfoPanel extends StatelessWidget {
  final String title;
  final List<String> bullets;
  final _InfoTone tone;

  const _InfoPanel({required this.title, required this.bullets, this.tone = _InfoTone.normal});

  @override
  Widget build(BuildContext context) {
    final borderColor = tone == _InfoTone.danger ? Colors.redAccent.withValues(alpha: 0.25) : AppColors.divider.withValues(alpha: 0.75);
    final bg = tone == _InfoTone.danger ? Colors.redAccent.withValues(alpha: 0.06) : AppColors.gradientStart.withValues(alpha: 0.05);
    final titleColor = tone == _InfoTone.danger ? Colors.redAccent : AppColors.textPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: titleColor),
          ),
          const SizedBox(height: 8),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(color: titleColor.withValues(alpha: 0.85), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  final String text;
  const _HintText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary.withValues(alpha: 0.95), height: 1.35),
    );
  }
}

class _BusyRow extends StatelessWidget {
  final String label;
  const _BusyRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.gradientStart.withValues(alpha: 0.9))),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.redAccent.withValues(alpha: 0.95)),
    );
  }
}

class _HeaderToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _HeaderToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Transform.scale(
        scale: 0.86,
        child: Switch.adaptive(value: value, onChanged: onChanged, activeThumbColor: AppColors.gradientStart, activeTrackColor: AppColors.gradientStart.withValues(alpha: 0.30), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ),
    );
  }
}
