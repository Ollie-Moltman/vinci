# Vinci

AI-powered photo search app for Android — search your photo library using natural language descriptions.

## Overview

Vinci uses on-device AI (MobileCLIP) to index your photos and let you search them with text queries like "photos where I'm wearing a formal shirt" or "sunset at the beach with friends."

All processing happens on-device — your photos never leave your phone.

## Tech Stack

- **Flutter** — Cross-platform app framework (Android-first, iOS-ready)
- **MobileCLIP** — On-device vision-language model for text↔image embeddings
- **TFLite** — TensorFlow Lite for on-device ML inference
- **Custom vector store** — JSON-backed local vector DB (swap to ChromaDB for scale)
- **photo_manager** — Photo library access on Android

## Features

| Feature | Status |
|--------|--------|
| Permission onboarding | ✅ |
| Photo gallery indexing (background) | ✅ |
| Text-to-photo search with similarity scores | ✅ |
| Real photo thumbnails via `photo_manager` | ✅ |
| Photo detail view with match % | ✅ |
| Share to other apps | ✅ |
| View in gallery / open in Photos app | ✅ |
| Favorites persistence (SharedPreferences) | ✅ |
| Auto-indexing on first launch | ✅ |
| Re-index from Settings | ✅ |
| Bottom navigation bar | ✅ |
| Splash screen | ✅ |
| Adaptive app icon (Android) | ✅ |
| Index persistence across restarts | ✅ |

## Screens

| Screen | Description | Status |
|--------|-------------|--------|
| Splash | App branding before permission check | ✅ |
| Permissions | Photo access request with privacy info | ✅ |
| Search / Home | Text input + quick query chips | ✅ |
| Results | Photo grid with thumbnail loading | ✅ |
| Detail | Full photo + share + view in gallery | ✅ |
| Settings | Auto-index toggle, re-index, stats | ✅ |

## Build

```bash
# Install Flutter dependencies
flutter pub get

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

## Next Steps

1. **Drop real `.tflite` model files** into `assets/models/` to get production-quality embeddings:
   - `mobileclip_image_embedding.tflite`
   - `mobileclip_text_embedding.tflite`
   (Download from HuggingFace: `apple/MobileCLIP-S2-OpenCLIP`)

2. **Upgrade vector store** from JSON-file backend to ChromaDB for better performance at scale

3. **Add Face Detection** for person-specific search

4. **iOS build** — same codebase, test on iOS device
# Debug marker
