/// Keyword heuristic for food a user types in by hand.
///
/// There are no preset dishes anywhere in the app: every meal option comes
/// from the plan the user's LLM generated. This only decides whether a
/// hand-typed extra should carry the gentle warning.
library;

/// Items that are almost always worth flagging, whatever they're called.
/// A custom entry containing one of these is flagged automatically, so
/// the warning still fires for food typed in by hand.
const List<String> _flagWords = [
  'fried',
  'fry',
  'pakora',
  'samosa',
  'maggi',
  'noodle',
  'chips',
  'cold drink',
  'coke',
  'pepsi',
  'soda',
  'juice',
  'shake',
  'sugar',
  'sweet',
  'dessert',
  'gulab',
  'jalebi',
  'halwa',
  'kheer',
  'ice cream',
  'cake',
  'chocolate',
  'biscuit',
  'burger',
  'pizza',
  'roll',
  'momo',
  'canteen',
  'ordered',
  'swiggy',
  'zomato',
  'butter',
  'cheese',
  'mayo',
];

/// Whether a hand-typed item should carry the gentle warning.
bool shouldFlagCustom(String name) {
  final n = name.trim().toLowerCase();
  return _flagWords.any(n.contains);
}
