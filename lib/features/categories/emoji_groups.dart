import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/tappable.dart';

/// The curated emoji of the inline icon pickers (category and envelope
/// editors), grouped under localized labels. Every emoji here has a Fluent
/// Flat PNG (see `_fluentEmoji` in category_icon.dart).
List<(String, List<String>)> emojiPickerGroups(S tr) => [
      (tr.emojiGroupFood, const [
        '🛒', '🍕', '🍔', '🍗', '🥗', '🍣', '🍜', '🌮', '🥐', '🍰',
        '☕', '🍺', '🥤', '🍷', '🧁', '🍩', '🥡', '🧃',
      ]),
      (tr.emojiGroupTransport, const [
        '🚗', '⛽', '🚕', '🚌', '🚇', '🚲', '✈️', '🛳️', '🚁', '🅿️',
        '🛞', '🏍️',
      ]),
      (tr.emojiGroupHome, const [
        '🏠', '💡', '💧', '🔌', '📡', '🛏️', '🪑', '🧹', '🧺', '🔧',
        '🏗️', '🔑',
      ]),
      (tr.emojiGroupShopping, const [
        '🛍️', '👕', '👗', '👟', '👜', '💄', '🕶️', '💎', '🧴', '💇',
      ]),
      (tr.emojiGroupHealth, const [
        '💊', '🏥', '🩺', '🏋️', '🧘', '🏊', '🚴', '🦷', '🩹', '💉',
      ]),
      (tr.emojiGroupEntertainment, const [
        '🎬', '🎮', '🎵', '🎤', '🎭', '🎨', '📺', '🎧', '🎪', '🎲',
        '🍿', '📷',
      ]),
      (tr.emojiGroupWork, const [
        '🎓', '📚', '💻', '📱', '🖨️', '📊', '💼', '🏢', '📝', '✏️',
        '🔬', '📐',
      ]),
      (tr.emojiGroupMoney, const [
        '💰', '💳', '🏦', '📈', '💵', '🪙', '💲', '🧾', '📑', '🏧',
      ]),
      (tr.emojiGroupFamily, const [
        '👶', '🧒', '👨‍👩‍👧', '🐾', '🐕', '🐈', '🧸', '🍼', '🎁', '❤️',
        '🎂', '🏡',
      ]),
      (tr.emojiGroupTravel, const [
        '✈️', '🏖️', '🏔️', '🗺️', '🧳', '⛺', '🏨', '🎢', '🎣', '⛷️',
      ]),
      (tr.emojiGroupOther, const [
        '📦', '🎯', '🔖', '⭐', '🌱', '♻️', '🤝', '🙏', '🚀', '🏷️',
        '📌', '🗂️',
      ]),
    ];

/// The inline emoji grid shown under an icon + name row (never in a dialog
/// or nested sheet — see CLAUDE.md "Icon pickers — inline only").
class InlineEmojiGrid extends StatelessWidget {
  const InlineEmojiGrid({
    super.key,
    required this.selected,
    required this.onPick,
  });

  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final cellRadius = BorderRadius.circular(RadiusTokens.md);
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.sfv(context),
        borderRadius: BorderRadius.circular(RadiusTokens.md),
      ),
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          for (final (label, emojis) in emojiPickerGroups(S.of(context)))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 6),
                  child: Text(label,
                      style: TextStyle(
                        fontSize: TypographyTokens.captionSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ts(context),
                      )),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final e in emojis)
                      Tappable(
                        onTap: () => onPick(e),
                        borderRadius: cellRadius,
                        color: e == selected ? AppColors.accentLight : null,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: cellRadius,
                            border: e == selected
                                ? Border.all(color: AppColors.accent, width: 2)
                                : null,
                          ),
                          child: Center(child: EmojiGlyph(e, size: 24)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
