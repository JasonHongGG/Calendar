import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/date_sticker_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/sticker_options.dart';

Future<void> showStickerPickerSheet({required BuildContext context, required DateTime date}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: StickerPickerSheet(date: date),
      );
    },
  );
}

class StickerPickerSheet extends StatelessWidget {
  final DateTime date;

  const StickerPickerSheet({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimens.radiusXLarge);

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
                  const Expanded(
                    child: Text(
                      '貼圖',
                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.close_rounded), color: AppColors.textTertiary, splashRadius: 22),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(AppDimens.spacingNormal, 0, AppDimens.spacingNormal, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '選擇日期貼圖（再次點擊可取消）。',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textTertiary, height: 1.35),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppDimens.spacingNormal, 0, AppDimens.spacingNormal, AppDimens.spacingNormal),
                child: Consumer<DateStickerProvider>(
                  builder: (context, provider, _) {
                    final selectedKey = provider.getStickerKey(date);
                    final items = StickerOptions.keys;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final key = items[index];
                        final emoji = StickerOptions.stickers[key] ?? '';
                        final isSelected = key == selectedKey;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              provider.setSticker(date, isSelected ? null : key);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected ? Border.all(color: AppColors.gradientStart, width: 1.5) : Border.all(color: AppColors.dividerLight),
                              ),
                              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
