# Spider-Tracker — Product Requirements Document

> Recovered 2026-09-22 from the session transcript where Karan pasted it
> (b1392ac5, 2026-09-21T14:46Z). This is the source of truth for scope.
> Verbatim apart from this header.

---

Product Requirements Document
Spider-Tracker
Personal fitness & diet tracker — Android app · Karan Anand · Sep 2026
Goal: 95 kg → 80–85 kg by Dec 2026
Theme: Spider-Man (Tom Holland)
Platform: Android (sideload APK)
Stack: MIT App Inventor / Flutter
01
Overview & Goals
Spider-Tracker is a lightweight Android app for Karan Anand to log daily workouts, track mess-food diet, and monitor weight progress toward a Peter Parker physique by December 2026. It lives entirely offline on the phone — no login, no server, no data sent anywhere.

Single goal the app exists to serve: Make it frictionless to check off today's workout and log today's meals — so Karan stays consistent, not just motivated.
Success in one line
Karan opens the app daily, marks workouts done, logs meals, and can see his weight trend without any friction or setup.

02
Target User & Context
Attribute    Detail
User    Karan Anand — BTech engineering student, hostel resident
Fitness level    Beginner to intermediate; no gym access
Space    Hostel room (small) + hostel grounds / road for running
Diet control    Low — dependent on mess menu; can choose what to pick
Device    Android phone; app sideloaded as APK (no Play Store needed)
Usage pattern    Morning: check today's workout. Post-workout: mark done. Meals: log 3× daily. Weekly: weigh-in on Monday.
03
Core Features
🕸️
Daily Workout Log
View today's pre-set exercises. Tap to mark each set done. Track streak.

🍛
Mess Meal Tracker
Log breakfast, lunch, snack, dinner from preset mess options. Rate each meal.

⚖️
Weekly Weight Log
Enter weight every Monday. See trend chart from start to now.

🏃
Running Log
Log evening run (distance + duration). Active from October 1 onward.

🔥
Streak Counter
Spider-Man-themed streak — web grows longer with each consecutive day.

📊
Progress Dashboard
Weight trend line, workouts completed, days to goal, current streak.

Feature Priority
Feature    Priority    MVP?
Daily workout checklist    P1    ✅ Yes
Meal log (3–4 meals/day)    P1    ✅ Yes
Weekly weight entry + chart    P1    ✅ Yes
Streak counter    P1    ✅ Yes
Running log (from Oct 1)    P2    ✅ Yes
Progress dashboard    P2    ✅ Yes
Daily reminder notifications    P2    Optional
Photo progress log    P3    ❌ V2
Calorie counting    P3    ❌ V2
04
Workout Plan — Peter Parker Physique
Tom Holland's Peter Parker is lean, agile, and functional — not bulky. Target: defined chest and shoulders, visible arms, flat stomach, strong legs. The app hard-codes this plan and displays each day's routine automatically.

Phase logic the app uses: Sep 21–30 = foundation (no running). Oct 1 onwards = add evening run. The app auto-unlocks the running module on Oct 1.
Phase 1 — Foundation (Sep 21–30)
Day    Focus    Key Exercises    Duration
Mon    Push — Chest & Shoulders    Standard push-ups 4×15, Wide push-ups 3×12, Pike push-ups 3×10, Diamond push-ups 3×10, Tricep dips 3×12    35–40 min
Tue    Core & Back    Superman holds 4×12, Towel rows 3×12, Plank 3×45s, Bicycle crunches 3×20, Leg raises 3×15, Russian twists 3×20    35 min
Wed    Legs    Bodyweight squats 4×20, Jump squats 3×15, Reverse lunges 3×12 each, Wall sit 3×45s, Glute bridges 4×15, Calf raises 3×25    35 min
Thu    HIIT Burn    3 circuits × (Jumping jacks 40s, High knees 40s, Burpees 40s, Mountain climbers 40s, Jump squats 40s) — 20 sec rest each    20–25 min
Fri    Full Body    Burpees 3×10, Push-ups 3×15, Squats 3×20, Plank-to-downdog 3×12, Glute bridges 3×15, Bicycle crunches 3×20    40 min
Sat    Active Rest    Walk 30–45 min — counts toward streak    30–45 min
Sun    Full Rest    No workout — rest day    —
Phase 2 — Oct & Nov (Running Added)
Same weekly split as above. Running is added as a separate evening session — 6 days/week (skip Sunday).

Month    Run Target    Pace    Notes
October (wk 1–2)    2–3 km/day    Easy, conversational    Build habit first, not pace
October (wk 3–4)    3–4 km/day    Moderate    Increase by 0.5 km every 4 days
November (wk 1–2)    4–5 km/day    Moderate–brisk    Aim for 30 min continuous
November (wk 3–4)    5 km/day    Comfortable but pushing    Maintain pace, not increase
Run timing: 6:00–7:00 PM, before dinner. Log it in the app immediately after — distance + rough time.
Peter Parker Reference Points
Attribute    Tom Holland stats    Your target
Height    5'8"    5'11" (you're taller — advantage)
Build    Lean, agile, defined — not mass    Same — prioritize leanness over size
Body fat    ~10–12%    ~14–16% by Dec (realistic)
Key muscles    Chest, shoulders, core, legs    Push focus + cardio = matches plan
05
Diet Tracking — Mess Food
The app doesn't count calories. It tracks compliance — did you eat the right things at each meal? Simple binary logging with preset mess options.

Meal Log Structure (in the app)
Meal    Time    Preset Options (user picks)    Flag if chosen
Breakfast    7–8 AM    Poha / Upma / Idli / Bread+butter / Puri    🚩 Puri / Bread+butter
Lunch    1–2 PM    Roti + Dal + Sabzi + Curd / Rice + Dal / Rice + Rajma    🚩 Extra rice, skip curd
Snack    4–5 PM    Roasted chana / Banana / Peanuts / Biscuits / Cold drink    🚩 Biscuits / Cold drink
Dinner    7–8 PM    Same as lunch options    🚩 Late night canteen run
App logic: If user selects a 🚩 flagged item, show a gentle warning — "Peter Parker wouldn't" — but still allow logging. No calorie math. Just awareness.
Daily Diet Score
Each meal is rated Good / Okay / Cheat on user input. Daily score = (Good meals × 2 + Okay × 1) out of 8 max. Shown as a web-strength meter on the dashboard.

06
UI/UX & Spider-Man Theme
Visual Identity
Element    Value
Primary colors    Deep navy #1A2D6E, Crimson red #D01F2B
Accent    Web gold #F5C518 (for streaks, achievements)
Background    Near-black #0A0E1A with subtle web grid texture
Font (display)    Bebas Neue — bold, comic-adjacent, strong
Font (body)    Inter — clean and readable
Iconography    Web/spider motifs for streaks, spider icon for app
Streak visual    Spiderweb that grows a strand for each day completed
Themed UX Copy
Trigger    Message
Workout complete    "With great power comes great responsibility. Done."
Cheat food selected    "Peter Parker wouldn't. But you're still logging it — respect."
7-day streak    "Your friendly neighbourhood grind doesn't stop."
Missed day    "Even Spider-Man had bad days. Get back tomorrow."
Goal weight reached    "Suit up. You're ready."
Monday weigh-in reminder    "The web doesn't lie. Time to check in."
Key UX Principles
Zero friction to log. Home screen shows today's workout + today's meals + current streak — nothing else. All logging done in ≤3 taps. No sign-in, no sync, no ads.

07
Tech Stack & Architecture
Two options depending on your skill level. MIT App Inventor = no code needed, build in browser, export APK. Flutter = if you know Dart or want to learn it.
Option A — MIT App Inventor (Recommended for quick build)
Platform
MIT App Inventor 2 — browser-based visual builder, free
Storage
TinyDB — built-in local key-value store, no setup
Charts
Chart component — App Inventor has a built-in line chart block
Export
Build APK — download and sideload directly to Android
Time to build
2–4 weekends if doing it yourself
Option B — Flutter (Better long-term)
Language
Dart + Flutter
Storage
SQLite via sqflite package — relational, easy queries
Charts
fl_chart package — clean line/bar charts
State
Provider — simple state management
Build
flutter build apk --release — sideload to phone
Time to build
1–2 weekends if familiar with Flutter; 3–4 if learning
Data Storage — All Local
No backend. No cloud. All data lives in phone storage. User can export as CSV for backup (V2).

08
Screens & Navigation
🏠
Home / Dashboard
Today's workout status, meals logged, streak, weight trend mini-chart

💪
Today's Workout
Exercise list with set/rep checklist. Mark done per set. Completion triggers animation.

🍛
Meal Log
4 meal slots. Tap to log what you had. Flag system for bad choices.

🏃
Run Log
Enter km and minutes. Visible from Oct 1. Running streak shown separately.

⚖️
Weight Check-in
Monday-only weight entry. Locks after entry till next Monday.

📈
Progress
Weight trend line (start → now → goal). Workout completion heatmap. Diet score history.

Navigation Flow
Home
→
Workout
→
Meals
→
Run Log
→
Weight
→
Progress
Bottom nav bar with 5 icons. Home is default on launch. No back-stack complexity.

09
Data Model
workout_log
date
String
YYYY-MM-DD, primary key
day_type
String
Push / Pull / Legs / HIIT / FullBody / Rest
sets_done
JSON
Array of {exercise, sets_completed}
completed
Boolean
True if all exercises marked
notes
String
Optional free text
meal_log
date
String
YYYY-MM-DD
meal_type
String
breakfast / lunch / snack / dinner
items
JSON
Array of items selected
quality
String
good / okay / cheat
weight_log
date
String
Monday date only
weight_kg
Float
Recorded weight
note
String
Optional
run_log
date
String
YYYY-MM-DD
distance_km
Float
Distance run
duration_min
Integer
Total time in minutes
app_state (single record)
start_weight
Float
95 kg — set on first launch
goal_weight
Float
82.5 kg default (mid of 80–85)
goal_date
String
2026-11-30
current_streak
Integer
Consecutive days with workout logged
run_unlocked
Boolean
True after Oct 1 2026
10
Out of Scope & Future Scope
Item    Status    Reason
Calorie counting    V2    Too complex for mess food; awareness-based is enough
Photo progress log    V2    Privacy concern; add only if user wants
Social / sharing    V2    Private tool first
Play Store publish    V3    APK sideload is enough for personal use
Cloud sync / backup    V2    Local-first; CSV export in V2
iOS version    Out    Android only
Custom workout editor    V2    Hardcoded plan is sufficient for 10-week sprint
11
Success Metrics
Metric    Target by Dec 1, 2026
Weight    80–85 kg (from 95 kg)
Workout consistency    ≥ 5/7 days per week logged
Diet compliance    ≥ 6/8 daily diet score on average
Running (from Oct 1)    5 km continuous run by Nov 30
App usage    Opens app daily — zero-friction habit built
Longest streak    ≥ 30 days by end of November
Final call: App is a tool, not the goal. If you're consistent without the app, great. But having it makes it 2× easier to stay honest — especially on the diet side.
Spider-Tracker PRD · Karan Anand · Sep 2026 · With great power comes great responsibility.
