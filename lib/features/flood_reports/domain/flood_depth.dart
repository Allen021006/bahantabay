enum FloodDepth {
  ankle('ankle', 'Ankle'),
  knee('knee', 'Knee'),
  waist('waist', 'Waist'),
  chest('chest', 'Chest');

  const FloodDepth(this.code, this.label);
  final String code;
  final String label;

  static FloodDepth fromCode(String code) => values.firstWhere(
    (depth) => depth.code == code,
    orElse: () => throw const FormatException('Unknown flood depth.'),
  );
}
