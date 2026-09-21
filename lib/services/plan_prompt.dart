/// Builds the prompt a user pastes into any LLM, and reads the reply back.
///
/// Nothing here talks to a network: the user is the transport. That keeps
/// the app offline and means no personal data ever leaves the phone unless
/// the user chooses to paste it somewhere.
library;

import 'dart:convert';

import '../models/models.dart';
import '../models/user_plan.dart';

String buildPlanPrompt(UserProfile p, DateTime now) {
  final goalDate = dateKey(p.goalDateFrom(now));
  final today = dateKey(now);
  final diet = p.diet.trim().isEmpty ? 'no restrictions' : p.diet.trim();
  final direction = p.goalKg < p.currentKg ? 'lose' : 'gain';
  final delta = (p.goalKg - p.currentKg).abs().toStringAsFixed(1);
  return '''
You are a careful fitness and nutrition coach. Build a personal plan for the person below and reply with ONLY a single JSON object. No prose, no markdown fences, no comments.

PERSON
- Name: ${p.name}
- Age: ${p.age}
- Height: ${p.heightCm.toStringAsFixed(0)} cm
- Current weight: ${p.currentKg.toStringAsFixed(1)} kg
- Goal weight: ${p.goalKg.toStringAsFixed(1)} kg (to $direction $delta kg)
- Today: $today. Goal date: $goalDate (${p.weeks} weeks)
- Workout setup / what they can do: ${p.workoutType}
- Training days per week: ${p.daysPerWeek}
- Diet: $diet

RULES
- Choose a safe, realistic pace (at most about 1 kg per week). Adapt sets, reps and difficulty to the person's age and to what they can actually do with the setup above.
- "week" has exactly 7 entries, Monday first, Sunday last. Use exactly ${p.daysPerWeek} training days; the other days are rest days with "exercises": [] (a light walk may be an exercise).
- Each exercise has "name", "sets" (1-10) and EITHER "reps" (integer) OR "seconds" (integer, for holds or timed work). Add "per_side": true when the count is per side.
- "meals" has "breakfast", "lunch", "snack" and "dinner", each with 10-16 realistic, everyday options that suit the diet above. Set "flagged": true on options that tend to work against the goal, false otherwise. Include a few flagged options in each list.
- "run" is optional. Include it only if running fits the person's setup and goal; otherwise use null. Stages must start on or after $today and before $goalDate, and get gradually harder.
- Do not include calorie counts or medical advice.

OUTPUT FORMAT (exactly these keys; the angle-bracket parts are placeholders you must replace with real content)
{
  "week": [
    {
      "title": "<day name, e.g. the muscle group or focus>",
      "short": "<one short word>",
      "duration": "<e.g. 35 min>",
      "exercises": [
        {"name": "<exercise>", "sets": <number>, "reps": <number>},
        {"name": "<timed exercise>", "sets": <number>, "seconds": <number>},
        {"name": "<one-sided exercise>", "sets": <number>, "reps": <number>, "per_side": true}
      ]
    }
  ],
  "meals": {
    "breakfast": [{"name": "<dish>", "flagged": <true or false>}],
    "lunch": [{"name": "<dish>", "flagged": <true or false>}],
    "snack": [{"name": "<item>", "flagged": <true or false>}],
    "dinner": [{"name": "<dish>", "flagged": <true or false>}]
  },
  "run": {
    "window": "<time of day>",
    "days": [<weekday numbers, 1 = Monday to 7 = Sunday>],
    "stages": [
      {"from": "YYYY-MM-DD", "min_km": <number>, "max_km": <number>, "pace": "<effort>", "note": "<one-line cue>"}
    ]
  }
}
Fill "week" with all 7 days and every meal list with 10-16 options. Use "run": null if running does not fit. Every dish and exercise must come from you, tailored to this person.
''';
}

/// Pulls the JSON object out of an LLM reply, tolerating code fences and
/// surrounding chatter, and parses it into a plan.
UserPlan parsePlanReply(String reply) {
  final start = reply.indexOf('{');
  final end = reply.lastIndexOf('}');
  if (start < 0 || end <= start) {
    throw const FormatException('No JSON object found in the pasted text.');
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(reply.substring(start, end + 1));
  } on FormatException catch (e) {
    throw FormatException(
      'That is not valid JSON (${e.message}). Ask the AI to reply with '
      'JSON only, then paste again.',
    );
  }
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Expected a JSON object.');
  }
  return UserPlan.fromJson(decoded);
}
