class StickerOptions {
  StickerOptions._();

  static const Map<String, String> stickers = {'party': '🎉', 'sparkle': '✨', 'thumbs_up': '👍', 'check': '✔️', 'cross': '❌', 'circle': '⭕', 'ticket': '🎫', 'train': '🚄', 'plane': '✈️', 'cart': '🛒', 'gift': '🎁', 'ban': '🚫'};

  static List<String> get keys => stickers.keys.toList(growable: false);
}
