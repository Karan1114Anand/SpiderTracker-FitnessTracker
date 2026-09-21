/// Running targets. The plan itself (workouts, meals, run stages) comes from
/// the user's own LLM-generated JSON — see `UserPlan`.
library;

/// One stage of the progressive running plan. Distance is a range because
/// the plan deliberately prescribes a band, not a single target.
class RunTarget {
  final double minKm;
  final double maxKm;

  /// Effort description, e.g. "Easy, conversational".
  final String pace;

  /// The one-line coaching cue shown under the target.
  final String note;

  const RunTarget({
    required this.minKm,
    required this.maxKm,
    required this.pace,
    required this.note,
  });

  /// Renders as "2–3 km", or "5 km" when the band collapses to a point.
  String get distanceLabel {
    String fmt(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    return minKm == maxKm
        ? '${fmt(minKm)} km'
        : '${fmt(minKm)}–${fmt(maxKm)} km';
  }
}
