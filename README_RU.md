# TT Video Automator 🎬🚀

[English](README.md) | **Русский**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Windows%20%7C%20Android-blue)](https://github.com/XFN52/tt-video-automator)
[![FFmpeg](https://img.shields.io/badge/FFmpeg-6.x%20%2B%20NVENC-007808?logo=ffmpeg)](https://ffmpeg.org)
[![Whisper AI](https://img.shields.io/badge/Whisper-AI%20Karaoke-FF6F00)](https://github.com/ggerganov/whisper.cpp)
[![GPU Engine](https://img.shields.io/badge/GPU%20Engine-OpenGL%20ES%203.0%20(100--200%20FPS)-green)](#7-аппаратный-zero-copy-gpu-рендерер-android-100200-fps)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Профессиональное кроссплатформенное приложение на Flutter (Windows & Android) для автоматизированного пакетного производства, уникализации и адаптации видео под вертикальный формат 9:16 (**TikTok**, **Instagram Reels**, **YouTube Shorts**, **VK Клипы**). 

Идеальный инструмент для владельцев **Faceless-каналов**, **арбитражников трафика (УБТ / FB / TT)**, контент-мейкеров и медиабаинговых команд.

---

## 🌟 Ключевые возможности

### 1. Пакетный процессинг и очередь задач
- **Параллельная обработка**: одновременный многопоточный рендеринг видео (автоматическое масштабирование под ядра CPU/GPU).
- **Drag-and-Drop**: мгновенное добавление пачек видеофайлов перетаскиванием в окно программы.
- **Персистентность очереди**: состояние очереди сохраняется в локальной базе данных Isar. При перезапуске незавершенные задачи восстанавливаются.
- **Умное запоминание путей**: приложение сохраняет выбранные рабочие директории в `app_settings.json`.

### 2. Форматирование в 9:16 и уникализация (Anti-Spam / Anti-Copyright)
- **Режимы фона**:
  - _Размытый фон (Dynamic Blur)_: центрирование исходного видео с адаптивным размытием под 9:16 (720x1280 / 1080x1920).
  - _Сплит-скрин (Split-Screen)_: оригинальное видео сверху, а снизу — зацикленный геймплей (GTA V, Minecraft, Subway Surfers, CS2).
- **Комплекс алгоритмов уникализации видео**:
  - Микро-изменение темпа видео и аудио (`setpts`, `atempo`) без слышимого искажения тональности.
  - Динамическая цветокоррекция с тонкой рандомизацией гаммы, контраста и насыщенности (`eq`).
  - Наложение субпиксельного цифрового шума (`noise`).
  - Горизонтальное зеркалирование (`hflip`).
  - **Спуфинг метаданных EXIF** под камеру Apple iPhone 14 Pro / QuickTime Encoder для обхода фильтров повторного контента.

### 3. Оффлайн Whisper AI и караоке-субтитры
- **Локальная транскрибация речи**: извлечение аудио (WAV 16 kHz Mono) и генерация пословных таймкодов через Whisper C++ (`whisper-cli.exe`) без отправки данных в облако.
- **Аппаратное ускорение**: автоматическая загрузка и запуск cuBLAS-бинарника (Nvidia CUDA). При отсутствии GPU задействуется высокооптимизированный CPU AVX2 режим.
- **Караоке-стиль ASS**: генерация стильных динамических субтитров с пословной желто-белой подсветкой в стиле TikTok.
- **Раздельное управление**: возможность отключить впекание субтитров на видео, сохраняя распознавание Whisper для генерации ИИ-хуков и постов.

### 4. ИИ Авто-нарезка на серии и клиффхэнгеры (AI Smart Cut)
- **Умная разбивка сюжета**: Whisper AI извлекает речь, а LLM (**DeepSeek V3** / **Gemini 3.7 Flash** / **OpenAI** / **Groq** / **Ollama**) находит смысловые границы и делит длинные ролики на логичные серии (30–45с, 45–60с, 60–90с).
- **Клиффхэнгеры (Cliffhangers)**: ИИ завершает каждую часть на самом интригующем моменте для максимального досмотра и удержания аудитории.
- **Автогенерация хуков и постов**: создание цепляющих заголовков-хуков, готовых текстов постов с призывами к действию (CTA) и пакетов вирусных хэштегов (`*_post.txt` и `*_meta.json`).

### 5. Оверлеи, текст и фоновая музыка
- **Плашки и баннеры**: наложение PNG-логотипов или прозрачных анимированных видеоплашек (MP4/MOV).
- **Текстовый хук и автонумерация**: генерация плашек "Часть 1", "Часть 2" с автопоиском системных шрифтов Windows (Arial, Calibri, Segoe UI).
- **Фоновая музыка**: случайная выборка трека из указанной папки MP3, нормализация громкости и микширование через `amix`.

### 6. Визуальный интерактивный предпросмотр (FullPreviewEditor)
- Интерактивный холст 9:16: прямое перемещение и ресайз плашек, заголовка-хука, нумерации и субтитров мышью или пальцем на тачскрине.
- Пресетная система: сохранение неограниченного числа профилей оформления с мгновенным переключением на главном экране.

### 7. Аппаратный Zero-Copy GPU-рендерер (Android 100–200 FPS)
- **Прямой пайплайн MediaCodec + OpenGL ES 3.0**: аппаратный декодер транслирует кадры прямо в текстуру `GL_TEXTURE_EXTERNAL_OES`, шейдеры применяют размытие, цветокоррекцию, шум, баннеры и караоке, а аппаратный энкодер сохраняет MP4 со скоростью 100–200+ кадров/сек.
- **Zero-Cache**: работа напрямую с накопителем (`/storage/emulated/0/...`) через `StoragePathHelper` без забивания системной памяти.

### 8. Мост интеграции с автопостером
- Автоматическая подготовка полного комплекта публикации (`*.mp4` + `*_post.txt` + `*_meta.json`) для мгновенной передачи в связку **Camoufox + Xray-core** (спецификация: [AUTOPOSTER_API_SPEC.md](AUTOPOSTER_API_SPEC.md)).

---

## 🏛 Архитектура проекта

```
lib/
├── core/
│   ├── constants/            # Разрешения рендера и константы
│   ├── database/             # Инициализация и CRUD Isar DB
│   ├── ffmpeg/               # Генератор filtergraph для FFmpeg CLI
│   ├── router/               # Навигация GoRouter
│   ├── services/             # Хранилище настроек (AppSettingsService)
│   ├── theme/                # Темная тема оформления (TikTok Dark/Cyan/Pink)
│   └── utils/                # StoragePathHelper, FontExtractor, FileUtils
│
├── features/
│   ├── ai_assistant/         # Интеграция DeepSeek, Gemini, Ollama, AI Smart Cut
│   ├── dashboard/            # Экран очереди, карточки задач, управление батчем
│   ├── presets/              # Модели пресетов, визуальный редактор наложения
│   ├── processing/           # BatchQueueManager, NativeGpuEngine, FFmpegEngine
│   ├── subtitles/            # WhisperService, пословные токены, генератор ASS
│   ├── tasks/                # StateNotifier очереди Riverpod, модели VideoTask
│   └── trimmer/              # Визуальная нарезка по таймлайну и превью-лента
│
android/app/src/main/kotlin/.../gpu/
├── AudioTrackMuxer.kt        # Мультиплексор аудиопотоков
├── EglCore.kt                # EGL контекст и Surface
├── GlProgram.kt              # Компилятор шейдеров OpenGL ES 3.0
├── GpuVideoRenderer.kt       # Шейдерный рендерер (Blur, караоке, баннеры, хуки)
└── GpuVideoTranscoder.kt     # Zero-Copy MediaCodec транскодер (100-200 FPS)
```

---

## 🛠 Стек технологий

- **Фреймворк**: Flutter (Dart 3.x, Android & Windows Desktop).
- **Стейт-менеджмент**: Flutter Riverpod 2.x.
- **База данных**: Isar NoSQL Database.
- **Аппаратный рендер (Android)**: Kotlin, MediaCodec, OpenGL ES 3.0, EGL 1.4.
- **Видеообработка (Windows)**: FFmpeg CLI + Nvidia NVENC (`h264_nvenc`).
- **Транскрибация речи**: Whisper C++ (`whisper-cli.exe`, ggml-tiny / base, cuBLAS + AVX2).
- **LLM Провайдеры**: DeepSeek V3, Google Gemini, OpenAI, Groq, локальная Ollama.
- **Видеоплеер**: `video_player` + `fvp` (MDK/DirectX/Vulkan).

---

## 🚀 Установка и сборка

### 1. Клонирование репозитория
```bash
git clone https://github.com/XFN52/tt-video-automator.git
cd tt-video-automator
```

### 2. Установка зависимостей и генерация кода
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 3. Запуск и сборка под Windows
```bash
# Режим разработки
flutter run -d windows

# Сборка Release EXE
flutter build windows
```
*Исполняемый файл*: `build\windows\x64\runner\Release\tt_video_automator.exe`

### 4. Запуск и сборка под Android
```bash
# Режим разработки
flutter run -d <device_id>

# Сборка Release APK
flutter build apk --release
```
*Установочный APK*: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📄 Лицензия

Распространяется под лицензией [MIT](LICENSE). Разрешено коммерческое и персональное использование.
