# Peblo AI Story Buddy & Quiz Component

Peblo is an AI-powered learning playground built for children aged 5–12. This single-screen Flutter application demonstrates the core integration of the **Raga** (storytelling) and **Vidya** (quiz) worlds, providing a dynamic, performant, and child-first interactive audio story and comprehension quiz experience.

---

## 1. Why Flutter Was Chosen
Flutter was selected for the Peblo Mobile App based on several strategic advantages:
* **Single Codebase, Cross-Platform**: Enables rapid deployment across both Android and iOS from a single Dart codebase.
* **Declarative UI**: Streamlines building highly responsive, state-driven interfaces suited for modern mobile design patterns.
* **High-Performance Animation Engine**: Leverages Skia/Impeller graphics pipelines to achieve 60fps animations (confetti, card shaking, custom mascot handoffs) seamlessly on budget mobile hardware.
* **Dart's Type Safety & Sound Null Safety**: Restricts runtime errors and layout crashes, which is critical when launching apps for young, independent learners.
* **Strong Ecosystem**: Robust packages for Text-to-Speech, audio playback, haptics, and Lottie animations are ready-to-use.

---

## 2. Audio to Quiz State Handoff
The transition from the narrative audio state to the active quiz state is controlled using Riverpod state provider listeners. 
* **State Mapping**: 
  - `AudioNotifier` manages the `AudioState` (`idle`, `preparing`, `playing`, `completed`, `error`).
  - `QuizNotifier` manages the `QuizState` (`hidden`, `revealing`, `awaitingAnswer`, `wrong`, `correct`).
* **Handoff Logic**: In [story_buddy_screen.dart](file:///d:/Flutter/flutter dev/projects/peblo_ai/lib/features/story_buddy/presentation/screens/story_buddy_screen.dart), a widget-level listener (`ref.listen<AudioState>`) tracks state changes:
  ```dart
  ref.listen<AudioState>(audioStateProvider, (prev, next) {
    if (next == AudioState.completed) {
      ref.read(quizStateProvider.notifier).revealQuiz();
      ref.read(buddyStateProvider.notifier).setPointing();
    }
  });
  ```
  Once `AudioState.completed` is detected, the quiz slides up into view and the mascot bobs, transitioning from Raga to Vidya pointing to the quiz options.

---

## 3. Data-Driven Quiz Architecture
The quiz rendering engine is completely dynamic and generic, ensuring no questions, option lists, or answers are hardcoded:
* **JSON Schema**: Reads from a standard JSON data contract:
  ```json
  {
    "question": "What colour was Pip the Robot's lost gear?",
    "options": ["Red", "Green", "Blue", "Yellow"],
    "answer": "Blue",
    "hint": "Think about what colour the sky is!"
  }
  ```
* **Parsing**: Deserialized by `QuizModel.fromJson()` which incorporates validation guards checking that `options.length` falls strictly between `3` and `5` items.
* **Rendering**: Adapts option buttons dynamically using a `ListView.builder` over the parsed options.
* **Evaluation**: Validation compares values (`selectedOption == answer`) rather than static indexes, supporting option shuffling or content additions without structural changes.

---

## 4. Remote Audio Caching Approach
For premium narrations (such as ElevenLabs remote API calls), the application implements a resilient local caching layer:
* **Cache Keying**: The caching service calculates a SHA-256 hash of the story text:
  ```dart
  final bytes = utf8.encode(storyText);
  final digest = sha256.convert(bytes);
  final cacheKey = digest.toString();
  ```
* **Lifecycle (7-day TTL)**: Checks if a local cache file exists in `path_provider`'s temporary folder. If it does, the app reads the modification timestamp. Files older than 7 days are automatically purged on checks.
* **Offline Resiliency**: If a network fetch fails, timeout limit exceeds (8s), or the user is offline with no cached file, the system silently falls back to the device-native `flutter_tts` engine, hiding errors from children.

---

## 5. Audio Loading and Failure Flow
Narration states follow a strict state machine to handle errors without locking up the UI:

```
[ IDLE ] ──(tap CTA)──► [ PREPARING ] ──(native ready)──► [ PLAYING ] ──(finished)──► [ COMPLETED ]
   ▲                           │                                │
   │                           ▼ (engine fail / timeout)        ▼ (audio cut)
   └─────────────────────── [ ERROR ] ◄─────────────────────────┘
```

* **Preparing State**: The button disables and shows a spinner with a *"Getting ready..."* label.
* **Error Warning**: If native initialization fails or ElevenLabs times out, the app renders a warning card with:
  - **Try Again**: Re-tries initialization and speech.
  - **Read Myself**: Instantly forces the state to `completed`, sliding up the quiz and letting the child bypass audio issues as plain text.

---

## 6. Performance Profiling
During performance audits using Flutter DevTools:
* **Frame Rendering**: Animations (confetti blasts, wrong-option card shakes, character transitions) execute at a stable **60fps** (under the 16.6ms frame budget).
* **Rebuild Counts**: Isolated repaint scopes using `RepaintBoundary` around the Confetti and Buddy widgets ensure that static background layouts, story card typography, and headers skip canvas painting cycles.
* **Isolates**: Large text formatting and JSON parsing operations run on background threads using Dart's `compute()` isolates to avoid UI thread jank.

---

## 7. Budget Device Optimizations
Optimized to execute smoothly on entry-level Android devices (~3GB RAM, MediaTek Snapdragon 400-series):
* **Repaint Boundaries**: Wrap heavy animation widgets (`BuddyCharacter` and `ConfettiWidget`) to prevent paint tick propagation.
* **Reduced Confetti Count**: Particle generation capped at `20` particles.
* **Const Constructors**: Instantiated on all widgets with static attributes to reuse instances and reduce heap collection.
* **Asset Optimization**: High-quality compressed WebP images restricted to `2x` assets to match typical budget 720p screens.
* **APK Size Reduction**: Built using `--split-per-abi` and `--strip-debug` configurations to keep final download packages under `25MB`.

---

## 8. AI Usage Transparency
* **Where AI was used**: Assisted in creating the custom 600ms dual-curve `AnimatedSwitcher` offsets for character handoffs, and designing the custom speech bubble `CustomPainter` vector shapes.
* **Rejected Suggestion**: An AI suggestion to download remote Lottie animations dynamically was rejected. It introduced layout glitches on slow Tier-3 internet connections. We implemented local, offline state-driven PNG assets instead.
* **Resolved Issue**: Fixed a Riverpod listener exception where `ref.listen` triggered state modifications during active layout cycles by queueing transitions to fire after frame callbacks.

---

## 9. Project Directory Structure

```
lib/
├── main.dart                      # App entry point (wraps tree in ProviderScope)
├── app/
│   └── peblo_app.dart             # MaterialApp, PebloTheme, and routes configuration
├── core/
│   ├── constants/
│   │   └── buddy_assets.dart      # Static asset paths for Raga and Vidya mascots
│   ├── theme/
│   │   └── peblo_theme.dart       # Colors, card styling, and touch-target button themes
│   └── services/
│       ├── tts_service.dart       # Native flutter_tts engine wrapper & lifecycles
│       └── audio_cache_service.dart# Local file caching and SHA-256 keying
└── features/
    └── story_buddy/
        ├── data/
        │   ├── models/
        │   │   └── quiz_model.dart # Quiz model structure & dynamic assert checks
        │   └── repositories/
        │       └── quiz_repository.dart# Static and remote JSON parsing pipelining
        ├── presentation/
        │   ├── screens/
        │   │   └── story_buddy_screen.dart# Screen layout, status rows, speech bubble shapes
        │   └── widgets/
        │       ├── buddy_character.dart# Mascot switcher with 600ms handoff curves
        │       ├── story_card.dart# Story text view with sound-reactive border pulsing
        │       ├── read_button.dart# State-driven CTA button (spinner, wave)
        │       ├── quiz_section.dart# Option tile listView builder & confetti triggers
        │       └── option_tile.dart# Option button containing 300ms shake animations
        └── providers/
            ├── audio_provider.dart# Riverpod AudioState & AudioNotifier
            ├── quiz_provider.dart # Riverpod QuizStatus, QuizState, & QuizNotifier
            └── buddy_provider.dart# Riverpod BuddyState & BuddyNotifier
```

---

## Character Assets & Attribution
The characters **Raga** (storytelling mascot) and **Vidya** (quiz mascot) featured
in this app are original creations of **Peblo** (mypeblo.com).
These assets are used with **explicit written permission** from the Peblo HR team,
granted via email (hello@mypeblo.com) for the sole purpose of this
Mobile App Developer Internship Challenge submission.
All characters remain the exclusive intellectual property of Peblo.
They are not for redistribution, commercial use, or reuse outside this assessment.
> Raga: Peblo TV / Storytelling World | Vidya: Quiz World / Mastery
