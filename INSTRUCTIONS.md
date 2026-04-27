# INSTRUCTIONS.md

## Goal
Build a **native SwiftUI app in Xcode** that can be adapted to any topic (health, finance, education, productivity, etc.) while including advanced app features such as onboarding, paywalls, persistence, widgets, Live Activities, App Intents, notifications, and optional watchOS sync.

---

## 1) Project setup in Xcode

1. Create a new project:
   - Xcode → **File → New → Project → iOS App**
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Lifecycle: **SwiftUI App**
2. Set deployment target according to required APIs:
   - Live Activities require iOS 16.1+, with iOS 16.2+ recommended for better production stability
   - Control Widgets need iOS 18+
3. Add extra targets if needed:
   - **Widget Extension** (for home/lock widgets and Live Activity UI)
   - **watchOS App** (if Apple Watch support is required)
4. Enable capabilities:
   - App Groups
   - Push Notifications (if needed)
   - Background Modes (if needed)
   - In-App Purchase
5. Define bundle identifiers and App Group IDs consistently across targets.

---

## 2) Recommended architecture

Use a layered architecture:

- `Views/` → SwiftUI screens and reusable components
- `Services/` → business logic managers (timer/session, subscriptions, notifications, sync)
- `Models/` → Codable structs, enums, Core Data/SwiftData models, Live Activity attributes
- `ViewModels/` → state orchestration for complex screens
- `Extensions/` and `Utilities/` → helpers and formatting

### State strategy

- Prefer `@Observable` models for new app-wide/shared state in modern SwiftUI (Observation framework, iOS 17+).
- Prioritize incremental migration from legacy `ObservableObject` code when modernizing existing apps.
- Use `ObservableObject`/`@StateObject` only when you specifically need Combine-based behavior or older OS compatibility.
- Use `@AppStorage` for simple preferences
- Use Core Data or SwiftData for historical/session records
- Use App Group `UserDefaults(suiteName:)` for app ↔ widget/watch shared data

---

## 3) Navigation and app shell

- Use `NavigationStack` for modern navigation; avoid `NavigationView` unless you must support older OS versions.
- Use the new Tab API for main app areas (Home, Insights, History, Settings, etc.) to get type-safe selection, cleaner state handling, and modern tab behavior (iOS 18+); use `TabView` only when targeting older systems.
- Trigger first-run onboarding with a persisted flag:
  - Example key: `hasSeenOnboarding`
  - Show onboarding as `.fullScreenCover` on first launch.

---

## 4) Onboarding implementation (generic)

Create a multi-step flow that does 3 things:

1. Explains value proposition
2. Captures personalization data
3. Requests permissions contextually

### Suggested onboarding steps

1. Welcome/value page
2. Personalization (name, role, goals, interests)
3. Feature preview
4. Permission prompt page (notifications, health data, etc.)
5. Optional paywall step
6. Success/ready screen

### Technical notes

- For paged onboarding, use `TabView` with `.tabViewStyle(.page)` (or a custom pager) plus an explicit page-selection model and programmatic step control.
- Keep validation per page (disable Continue until required fields are valid).
- Save onboarding data immediately to persistence layer.
- Request permissions only in dedicated permission step (not on app launch).

---

## 5) Paywall and subscription system

Use **StoreKit 2** (native Apple framework) as the base implementation.

### Components (StoreKit 2)

- `SubscriptionManager` service:
  - Product IDs
  - Product fetch
  - Purchase flow
  - Restore purchases
  - Transaction updates listener
  - Entitlement verification
  - Cached/offline status with expiration checks
- `PaywallView`:
  - Can use `SubscriptionStoreView` for native paywall
  - Include restore button, terms URL, privacy URL

### Example code: fetch products

```swift
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var products: [Product] = []
    private let productIDs = ["app.pro.monthly", "app.pro.yearly"]

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("Product fetch failed: \\(error)")
        }
    }
}
```

### Example code: native paywall UI

```swift
import SwiftUI
import StoreKit

struct PaywallView: View {
    var body: some View {
        SubscriptionStoreView(groupID: "YOUR_SUBSCRIPTION_GROUP_ID") {
            VStack(spacing: 8) {
                Text("Upgrade to Pro")
                    .font(.title.bold())
                Text("Unlock premium features")
                    .foregroundStyle(.secondary)
            }
        }
        .storeButton(.visible, for: .restorePurchases)
        .subscriptionStorePolicyDestination(
            url: URL(string: "https://example.com/terms")!,
            for: .termsOfService
        )
        .subscriptionStorePolicyDestination(
            url: URL(string: "https://example.com/privacy")!,
            for: .privacyPolicy
        )
    }
}
```

### Example code: verify active entitlement

```swift
import StoreKit

@MainActor
func verifyProAccess(productIDs: Set<String>) async -> Bool {
    for await result in Transaction.currentEntitlements {
        guard case .verified(let transaction) = result else { continue }
        guard productIDs.contains(transaction.productID) else { continue }

        if let expiration = transaction.expirationDate {
            if expiration > Date() { return true }
        } else {
            return true // non-expiring entitlement
        }
    }
    return false
}
```

### Example code: listen for renewals/refunds

```swift
func listenForTransactionUpdates() {
    Task.detached {
        for await update in Transaction.updates {
            guard case .verified(let transaction) = update else { continue }
            await MainActor.run {
                // Refresh your local entitlement state here
            }
            await transaction.finish()
        }
    }
}
```

### Access control pattern

- Add computed capabilities in subscription manager:
  - `canAccessFeatureA`, `canAccessFeatureB`, etc.
- In UI, gate premium features with:
  - disabled/blurred content
  - lock overlays
  - paywall triggers via `.sheet`

### Offline behavior

- Cache subscription status and last verification date.
- Apply grace-period logic when network is unavailable.
- Sync premium status to App Group for widgets/watch.

---

## 6) Persistence and data model

Use persistence by responsibility:

- `@AppStorage` / `UserDefaults`: settings and lightweight flags
- Core Data / SwiftData: history, logs, analytics records
- App Group defaults: shared preset/config snapshots for widgets/watch

### Good practices

- Keep all storage keys centralized
- Version your Codable payloads when sharing between targets
- Validate restored checkpoints (e.g., drop stale state older than 24h)
- Recompute derived analytics from source records when needed

---

## 7) Core feature-engine pattern (generic, any app domain)

If your app has long-running or multi-phase workflows (learning plans, workout blocks, guided tasks, delivery states, etc.), model it as a **state machine service**.

### Lifecycle

- Define clear states (e.g., `idle`, `active`, `paused`, `completed`, `failed`)
- Expose explicit transitions (`start`, `pause`, `resume`, `complete`, `cancel`)
- Keep transition logic centralized in one manager/service

### Reliability

- Save workflow checkpoints when app moves to background
- Restore checkpoints on launch before rendering dependent UI
- Recompute derived progress from persisted timestamps/data, not only in-memory counters
- On app resume, resync state if system time/device conditions changed
- Validate and discard corrupted or stale checkpoints

---

## 8) Notifications

Implement a dedicated notification manager:

- Request authorization from onboarding/settings
- Schedule phase or milestone notifications
- Use deterministic notification IDs per cycle/phase
- Cancel pending notifications when session stops
- Respect iOS pending notification limits

---

## 9) Widgets and Live Activities

## Home widgets

- Build timelines with `WidgetKit`
- Read shared data from App Group defaults
- Provide fallback placeholder content when data is missing
- Deep-link widget taps back into app routes

## Live Activities

1. Define `ActivityAttributes` + `ContentState`
2. Start activity when session starts
3. Update state on pause/resume transitions
4. End activity on session stop/completion
5. Implement Lock Screen and Dynamic Island UI in widget extension

### Data contract rules

- Keep attributes minimal and serializable
- Pass stable identifiers and timestamps
- Avoid storing heavy payloads in Activity state

---

## 10) App Intents, Shortcuts, and control surfaces

- Add `AppIntent` actions for common flows (start, stop, open section)
- Register `AppShortcutsProvider` with useful phrases
- Add control widgets (when target iOS supports them)
- Ensure intents safely access shared managers (`MainActor` where needed)

---

## 11) watchOS synchronization (optional)

If watch support is required:

- Implement `WatchConnectivity` manager on iPhone and watch targets
- Sync:
  - presets/config
  - active session state
  - premium status
  - summary stats
- Use both real-time messages (`sendMessage`) and queued fallback (`transferUserInfo`)
- Mirror selected shared state to App Group for watch complications/widgets

---

## 12) Design and UX implementation guidance

- Build with a reusable component system (cards, chips, stat tiles, buttons)
- Keep spacing/typography/radius tokens consistent
- Use adaptive layouts for widget families and device sizes
- Design clear premium lock states and upgrade CTAs
- Make onboarding and paywall transitions smooth and obvious

### Accessibility

- Prefer semantic controls (`Button`) over bare gestures
- Support Dynamic Type
- Ensure color contrast in dark/light modes
- Add clear labels for icon-only elements

---

## 13) Security, privacy, and compliance

- Never hardcode secrets in source
- Include Terms and Privacy links in paywall
- Request only necessary permissions and explain value before prompting
- Handle purchase failures and verification errors explicitly
- Keep local user data handling transparent and reversible (reset/export where applicable)

---

## 14) QA checklist before shipping

1. First launch and onboarding path
2. Subscription purchase + restore + cancellation + offline behavior
3. Premium gating on all feature entry points
4. Core workflow lifecycle (start/pause/resume/complete/cancel as applicable)
5. Background/foreground recovery
6. Notifications scheduling/cancel behavior
7. Widget data freshness and deep links
8. Live Activity lifecycle and Dynamic Island states
9. watch sync reliability (if enabled)
10. Data reset/export paths

---

## 15) Suggested implementation order for a new app

1. Core data models and app architecture
2. Main navigation shell
3. Core feature engine/service (domain logic)
4. Persistence and settings
5. Onboarding
6. Paywall and entitlement gating
7. Widgets and Live Activities
8. Intents/Shortcuts
9. watch integration
10. QA hardening and release prep

---

## 16) Prompting another AI with this file

When giving this document to another AI, include:

- App theme/domain
- Target OS versions
- Free vs premium feature matrix
- Required platforms (iOS only vs iOS + watchOS)
- Must-have integrations (widgets, live activity, app intents, notifications)
- Visual style constraints

This allows the AI to reuse the same technical blueprint while changing only domain-specific content.