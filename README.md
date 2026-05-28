# Vinci

AI-powered photo search app for Android — search your photo library using natural language descriptions.

## Overview

Vinci uses on-device AI (MobileCLIP) to index your photos and let you search them with text queries like "photos where I'm wearing a formal shirt" or "sunset at the beach with friends."

## Tech Stack

- **Flutter** — Cross-platform app framework
- **MobileCLIP** — On-device vision-language model for image embeddings
- **ChromaDB** — Local vector database for similarity search
- **photo_manager** — Photo library access on Android

## Screens

| Screen | Description | Status |
|--------|-------------|--------|
| Screen 0 | Permissions / Onboarding | ✅ Final |
| Screen 1 | Search / Home | ✅ Final |
| Screen 2 | Search Results | ✅ Final |
| Screen 3 | Photo Detail | ✅ Final |
| Screen 4 | Settings | ✅ Final |

Wireframes are in `references/`.

## Build

```bash
# Install dependencies
flutter pub get

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

## Project Status

🚧 In active development — Flutter project shell created, build environment being configured.
