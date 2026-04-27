You are a senior iOS engineer and product designer. Build a complete production-ready native SwiftUI iOS app called **Breedy** from scratch.

Important constraints:
- Read and strictly follow `DESIGN.md` for all UI/UX, spacing, typography, colors, motion, mascot style, and visual language.
- Read and strictly follow `INSTRUCTIONS.md` for coding architecture, patterns, conventions, dependencies, implementation rules, and technical constraints.
- Use native Swift + SwiftUI only unless `INSTRUCTIONS.md` explicitly allows external packages.
- Target latest stable iOS version with backward compatibility when possible.
- Deliver a fully working app, compile-ready.
- Use modern SwiftUI APIs. Avoid deprecated patterns.
- Use MVVM or clean modular architecture.
- Write maintainable, scalable, testable code.

# PRODUCT GOAL

Breedy is the best breathing app on iPhone: elegant, fast, calming, habit-forming, delightful, and privacy-first.

The differentiator is a lovable mascot named **Breedy** that gently guides users through breathing sessions, celebrates progress, reduces anxiety, and adds warmth without being childish.

The app must feel premium, minimal, emotionally intelligent, and highly polished.

# CORE INSIGHTS TO IMPLEMENT

Many breathing apps fail because they are:
- bloated
- full of paywalls
- noisy
- require accounts
- too many taps before starting
- weak progress systems
- boring visuals
- poor customization
- no offline mode
- bad reminders
- lack Apple Health integration

Breedy must solve all of those.

# BUILD THE FULL APP WITH THESE FEATURES

## 1. APP STRUCTURE / TABS

Use a polished tab navigation with these sections:

1. Home  
2. Sessions  
3. Progress  
4. Companion  
5. Settings

---

## 2. HOME SCREEN (FAST START)

The best breathing apps let users start in seconds.

Build Home with:

- Large greeting based on time of day
- Breedy mascot animated and alive
- “How do you want to feel?” quick states:
  - Calm
  - Focus
  - Sleep
  - Energy
  - Anxiety Relief
- One-tap recommended session card
- Resume last session
- Daily streak card
- Minutes breathed today
- Quick Start button
- Smart suggestion based on time/day usage history

Breedy should react to selected mood.

---

## 3. GUIDED BREATHING ENGINE (MOST IMPORTANT)

Create a world-class breathing session engine.

Support phases:

- Inhale
- Hold
- Exhale
- Hold (optional)

Allow custom timing in seconds.

Examples presets:

- Box Breathing (4-4-4-4)
- 4-7-8
- Coherent Breathing (5.5 in / 5.5 out)
- Physiological Sigh
- Deep Calm (6-2-8-2)
- Energy Breath
- Sleep Wind Down
- Anxiety Reset (short emergency mode)

Features:

- Smooth circle / orb animation synced to breath
- Breedy mascot breathing with user
- Text cues: Inhale / Hold / Exhale
- Countdown ring
- Remaining time
- Session pause / resume / stop
- Haptics for transitions
- Optional sound cues
- Optional voice cues
- Dark immersive Zen Mode
- Tap to hide UI during session
- Lock screen / Live Activity support if possible
- Works offline
- Prevent screen sleep during active session

Animation quality must be excellent.

---

## 4. CUSTOM SESSION BUILDER

Users love customization.

Create builder where user can set:

- inhale seconds
- hold1 seconds
- exhale seconds
- hold2 seconds
- total duration OR cycles
- title
- icon
- color theme
- mascot mood

Allow save/edit/delete custom routines.

---

## 5. PROGRESS / HABIT SYSTEM

Make users return daily without being manipulative.

Track:

- total minutes
- total sessions
- current streak
- longest streak
- weekly consistency
- preferred session type
- mood improvements logged before/after

Charts:

- 7 day
- 30 day
- yearly heatmap style

Gamification:

- gentle XP system
- levels
- milestones
- badges
- celebrations by Breedy

Examples:
- First Breath
- 7 Day Flow
- 100 Minutes
- Calm Master

No casino-style dark patterns.

---

## 6. COMPANION TAB (BREEDY)

This is a signature feature.

Breedy is a smart emotional breathing companion.

Include:

- Daily check-in:
  - stress level
  - mood
  - energy
  - sleep quality

Breedy responds kindly.

- Encouragement messages
- Progress celebration
- Recommended session based on mood
- Tiny evolving relationship system
- Unlockable expressions/accessories/themes through milestones
- Idle animations
- Seasonal changes

Tone: calm, supportive, witty, warm.

Never cringe.

---

## 7. REMINDERS / ROUTINES

Implement local notifications.

Allow:

- morning reminder
- work break reminder
- evening unwind
- custom reminders
- smart reminder if streak about to break
- habit schedules by weekday

Beautiful settings UI.

---

## 8. APPLE HEALTH / APPLE ECOSYSTEM

If possible natively implement:

- Apple Health mindfulness minutes write support
- Apple Watch preparation hooks / future-ready structure
- Widgets:
  - Quick Calm
  - Streak
  - Start Last Session
- Live Activity during active breathing

---

## 9. SETTINGS

Include:

- sound on/off
- haptics on/off
- voice cues on/off
- theme: system / light / dark
- mascot intensity (minimal / normal / playful)
- data export
- privacy mode
- notifications
- restore purchases placeholder if monetized later
- about Breedy

---

## 10. PRIVACY-FIRST

No forced account.

Local-first storage using SwiftData / Core Data (choose best modern option).

No analytics unless clearly optional.

Offline-first.

Export/import user data.

---

## 11. ONBOARDING

Keep short. Max 3 screens.

Collect:

- goal (stress, focus, sleep, habit)
- reminder preference
- mascot enabled yes/no

Then enter app immediately.

---

## 12. DESIGN QUALITY

Must feel App Store feature-worthy.

Use:

- buttery animations
- subtle depth
- gradients
- glass / material where appropriate
- calm motion
- tactile buttons
- accessibility friendly contrast
- Dynamic Type support
- VoiceOver labels

---

## 13. TECHNICAL REQUIREMENTS

Implement:

- clean folder structure
- reusable components
- no placeholder junk
- realistic sample data
- preview providers
- unit-testable logic
- persistence layer
- notification manager
- health manager abstraction
- breathing engine timer accuracy
- robust background/foreground state handling

---

## 14. DELIVERABLES

Generate all necessary files for a real project:

- App entry
- Models
- Views
- ViewModels
- Managers
- Services
- Components
- Assets references
- Sample data
- Helpers
- Extensions

Include comments only when useful.

---

## 15. EXTRA DELIGHT

Add subtle touches such as:

- mascot yawns at night
- mascot celebrates streaks
- sunrise/sunset home backgrounds
- tiny confetti on milestones
- heartbeat pulse while idle
- calming microcopy

---

## 16. WHAT TO OPTIMIZE FOR

If forced to choose, prioritize in this order:

1. Session experience quality
2. Simplicity / low friction
3. Emotional delight via Breedy
4. Daily retention through habits
5. Beautiful premium UI
6. Technical cleanliness

---

## 17. NOW EXECUTE

Build the full app codebase immediately.

Do not give explanations first.
Do not output a plan only.
Create the actual production-ready SwiftUI implementation file by file.
Assume DESIGN.md and INSTRUCTIONS.md are available and must be obeyed exactly.  