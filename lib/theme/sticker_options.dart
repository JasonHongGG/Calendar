class StickerOptions {
  StickerOptions._();

  static const Map<String, String> stickers = {'coffee': '☕', 'work': '💼', 'study': '📚', 'exercise': '💪', 'party': '🎉', 'travel': '✈️', 'birthday': '🎂', 'shopping': '🛒', 'meeting': '🤝', 'health': '🩺', 'family': '👨‍👩‍👧‍👦', 'movie': '🎬'};

  static List<String> get keys => stickers.keys.toList(growable: false);
}
