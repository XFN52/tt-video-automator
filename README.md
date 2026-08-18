# TT Video Automator 🎬⚡

**English** | [Русский](README_RU.md)

[![GitHub Stars](https://img.shields.io/github/stars/XFN52/tt-video-automator?style=social)](https://github.com/XFN52/tt-video-automator)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platforms-Windows%20%7C%20Android-blue)](https://github.com/XFN52/tt-video-automator/releases)
[![FFmpeg](https://img.shields.io/badge/FFmpeg-6.x%20%2B%20NVENC-007808?logo=ffmpeg)](https://ffmpeg.org)
[![Whisper AI](https://img.shields.io/badge/Whisper-AI%20Karaoke-FF6F00)](https://github.com/ggerganov/whisper.cpp)
[![GPU Engine](https://img.shields.io/badge/GPU%20Engine-OpenGL%20ES%203.0%20(100--200%20FPS)-green)](#-high-speed-zero-copy-gpu-renderer-android)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **All-in-one batch video automation toolkit for TikTok, Instagram Reels, and YouTube Shorts.**  
> Transform horizontal videos into viral 9:16 vertical shorts with AI auto-cutting, animated Whisper Karaoke subtitles, split-screen gameplay, anti-copyright unique-fication algorithms, and automatic post/hook copywriting via DeepSeek & Gemini.

---

## ⚡ Why TT Video Automator?

Designed specifically for **Faceless Channel Creators**, **Affiliate Marketers (UAP / Arbitrage)**, **Content Agencies**, and **Media Buyers** who need to produce and unique-fy hundreds of high-retention short videos daily without manual editing in Premiere or CapCut.

| Feature | TT Video Automator | Manual Editing (CapCut/Premiere) | Basic Scripts |
| :--- | :---: | :---: | :---: |
| **Batch Processing** | 🚀 **Parallel Multi-Worker** | ❌ One by one | ⚠️ Slow single-thread |
| **Local Whisper AI Karaoke** | ✅ **Built-in Offline (CUDA/CPU)** | ⚠️ Manual typing / Paid Cloud | ❌ No |
| **AI Smart Cut & Cliffhangers** | 🤖 **DeepSeek / Gemini / Ollama** | ❌ Manual listening & cutting | ❌ No |
| **Anti-Copyright Unique-fication** | 🛡️ **EXIF Spoof + Noise + EQ + Speed** | ⚠️ Tedious manual tweaks | ⚠️ Simple re-encode |
| **Android GPU Rendering Speed** | ⚡ **100–200+ FPS (OpenGL ES 3.0)** | ❌ Standard ~30 FPS | ❌ N/A |
| **Custom Overlays & Branding** | 🎨 **Visual Drag-and-Drop Editor** | ⚠️ Manual keyframing | ❌ Hardcoded coordinates |
| **Autoposter Integration** | 🌐 **Generates MP4 + Post + Meta JSON** | ❌ Manual publishing | ❌ No |

---

## 🚀 Key Features

### 1. 🤖 AI Smart Cut & Auto-Episode Splitter
- **Intelligent Story Parsing**: Local Whisper AI transcribes the audio with word-level timestamps, then LLMs (**DeepSeek V3**, **Google Gemini 3.7 Flash**, **OpenAI**, or local **Ollama**) detect natural narrative boundaries.
- **Viral Cliffhangers**: Splits full-length movies, podcasts, or streams into binge-worthy 30–60s episodes ending right on tension peaks to maximize viewer retention and comments.
- **Automated Copywriting**: Generates clickbait hook titles, description copy with Call-To-Action (CTA), and viral hashtags exported directly into `<video>_post.txt` and `<video>_meta.json`.

### 2. 🛡️ Advanced Anti-Copyright & Video Unique-fication Engine
Bypass automated TikTok/Instagram/YouTube spam filters and duplicate content detectors:
- **EXIF Metadata Spoofing**: Injects authentic camera metadata (Apple iPhone 14 Pro, QuickTime 7.7.1 encoder tags).
- **Subtle Speed Warping**: Micro-tempo adjustments (`setpts`, `atempo`) without audible pitch shift.
- **Dynamic Color Grading**: Randomizes gamma, saturation, and contrast offsets (`eq`).
- **Subpixel Digital Noise**: Adds imperceptible grain overlay (`noise`) to break hash signatures.
- **Horizontal Flipping**: Optional smart mirror transform (`hflip`).

### 3. 🎤 Local Whisper AI Karaoke Subtitles
- **100% Offline & Free**: Transcribes audio using `whisper.cpp` (Nvidia CUDA cuBLAS & CPU AVX2 acceleration) — no expensive cloud API subscriptions needed.
- **TikTok-Style Highlight**: Generates styled `.ass` karaoke subtitles with word-by-word active glow effect.
- **Independent Show/Hide Control**: Keep Whisper active for AI hook/post generation while hiding on-screen subtitle burn-in whenever you need clean video output.

### 4. 🎛️ 9:16 Reformatting & Split-Screen Gameplay
- **Dynamic Blur Background**: Centers 16:9 landscape footage over an aesthetically blurred vertical 9:16 background.
- **Split-Screen Mode**: Places main video on the top half and automatically loops viral background gameplay (Subway Surfers, GTA V, Minecraft Parkour) on the bottom half.

### 5. 🎨 Interactive Drag-and-Drop Overlay Editor (`FullPreviewEditor`)
- Live 9:16 interactive canvas with real-time mouse/touch drag-and-drop repositioning and scaling for:
  - Video and image watermark banners (PNG / transparent MP4 / MOV).
  - Top viral hook titles.
  - "Part 1", "Part 2" episodic tags.
  - Dynamic karaoke subtitles.
- Unlimited custom presets saved locally in Isar NoSQL Database.

### 6. ⚡ High-Speed Zero-Copy GPU Renderer (Android)
- **100–200+ FPS Native Rendering**: Bypasses slow mobile FFmpeg using direct hardware `MediaCodec` + `OpenGL ES 3.0` surface-to-surface pipeline.
- **Zero-Cache File Management**: Direct storage IO via `StoragePathHelper` (`/storage/emulated/0/...`) prevents storage clutter.

### 7. 🌐 Autoposter Bridge Ready
Outputs ready-to-publish packages (`.mp4` + `_post.txt` + `_meta.json`) pre-formatted for remote automation servers based on **Camoufox Browser + Xray-core** (see [AUTOPOSTER_API_SPEC.md](AUTOPOSTER_API_SPEC.md)).

---

## 🏗️ Architecture & Tech Stack

```
lib/
├── core/
│   ├── constants/            # Output resolutions (720x1280, 1080x1920)
│   ├── database/             # Isar NoSQL database provider & schemas
│   ├── ffmpeg/               # Complex FFmpeg filtergraph generator
│   ├── router/               # Declarative GoRouter routing
│   ├── services/             # Settings persistence (AppSettingsService)
│   └── theme/                # TikTok Dark / Neon Pink UI theme
│
├── features/
│   ├── ai_assistant/         # DeepSeek / Gemini / Ollama AI integration & prompt engineering
│   ├── dashboard/            # Batch processing queue, progress trackers, workers
│   ├── presets/              # Preset domain model & interactive canvas editor
│   ├── processing/           # BatchQueueManager, NativeGpuEngine, FFmpegEngine
│   ├── subtitles/            # WhisperService (whisper.cpp C++ bridge, ASS generator)
│   ├── tasks/                # Riverpod StateNotifier queue management
│   └── trimmer/              # Visual timeline video trimmer & frame strip preview
│
android/app/src/main/kotlin/.../gpu/
├── AudioTrackMuxer.kt        # Audio stream muxing
├── EglCore.kt                # Hardware EGL 1.4 context & display surface
├── GlProgram.kt              # OpenGL ES 3.0 shader program compiler
├── GpuVideoRenderer.kt       # Multi-pass shader engine (Blur, noise, text, overlays)
└── GpuVideoTranscoder.kt     # Zero-Copy MediaCodec hardware transcoder
```

- **Frontend**: Flutter (Dart 3.x) with Flutter Riverpod 2.x.
- **Database**: Isar NoSQL DB (ultra-fast embedded local database).
- **Desktop Rendering**: FFmpeg CLI + Nvidia NVENC hardware acceleration.
- **Mobile Rendering**: Native Kotlin, Android MediaCodec, OpenGL ES 3.0, EGL.
- **AI / Speech**: Whisper.cpp (offline speech-to-text), DeepSeek V3, Google Gemini.

---

## 📦 Installation & Quick Start

### Prerequisites
- **Windows**: Windows 10/11 (64-bit). Ensure `ffmpeg.exe` is installed and in your system `%PATH%`.
- **Android**: Android 8.0 (API level 26) or higher.

### 1. Clone the Repository
```bash
git clone https://github.com/XFN52/tt-video-automator.git
cd tt-video-automator
```

### 2. Install Dependencies & Build Code Generators
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 3. Build & Run for Windows Desktop
```bash
# Debug mode
flutter run -d windows

# Compile standalone Release EXE
flutter build windows
```
*Compiled binary*: `build\windows\x64\runner\Release\tt_video_automator.exe`

### 4. Build & Run for Android
```bash
# Run on connected device
flutter run -d <device_id>

# Compile Release APK
flutter build apk --release
```
*Compiled APK*: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 Testing & Code Quality

Run automated unit and widget test suites:
```bash
flutter test
```

Run static analysis check:
```bash
flutter analyze
```

---

## 🤝 Contributing

Contributions, feature requests, and bug reports are welcome!  
Feel free to open an issue or submit a pull request.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.  
Suitable for both personal and commercial automation workflows.

---

<p align="center">
  Built with ❤️ for Creators, Media Buyers & Automation Enthusiasts.
</p>
