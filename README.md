# YAAD — Personal Memory & Action System

> **“Show it → YAAD understands → remembers → acts.”**

YAAD is a personal memory and action system designed for everyday Indian life.

## Overview

YAAD helps users capture physical documents, bills, prescriptions, IDs, warranties, and certificates, understand their contents, and automatically create actionable reminders and memory retrieval.

## Tech Stack & Architecture

- **Flutter & Dart** (Android-first)
- **Material 3** customized with YAAD visual system
- **Riverpod** for state management
- **go_router** for stateful tab navigation and routing
- **Drift / SQLite** local database layer
- **flutter_secure_storage** for secrets & secure credentials
- **shared_preferences** for local settings and onboarding state

## Feature Highlights (v0.1 Foundation)

1. **Onboarding**: 3-step value proposition walkthrough with persistent state.
2. **Home**: Attention dashboard highlighting urgent actions (bills due, insurance renewals, medicine reminders) and upcoming expirations.
3. **Capture**: Point & Remember camera shell reticle with detection status.
4. **Vault**: Life-oriented categories (IDs, Bills & Payments, Vehicles, Medical, Warranties, Education & Jobs).
5. **Search**: Instant local search with query suggestions ("Bike insurance", "Electricity bills", etc.).
6. **Chat**: "Ask YAAD" conversational memory interface with contextual memory cards.
7. **Settings**: Profile, Privacy & Security, Notifications, Language, Family Vault, Backup, Subscription, and Developer Replay Onboarding tool.

## Getting Started

```bash
# Clone the repository
git clone https://github.com/AniketBhatia2091/YAAD.git
cd YAAD

# Get dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit tests
flutter test

# Launch app
flutter run
```
