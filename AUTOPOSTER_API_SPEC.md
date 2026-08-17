# Спецификация API Автопостера для TT Video Automator (Camoufox + Xray-core)

Версия спецификации: **3.5.0 (Camoufox + Xray-core Reality/VLESS Engine)**  
Архитектура: **TT Automator Client + VPS Autoposter (Camoufox + Xray-core Proxy) + Telegram Control Plane**

---

## 1. Архитектура Проксирования через Xray-core

Для обхода блокировок, цензуры и изоляции сетевых профилей на сервере используется **Xray-core** (VLESS-Reality / Trojan / Shadowsocks / VMess):

```
┌────────────────────────────────────────────────────────────┐
│         TT Video Automator (Android-телефон / Windows)      │
│  - Локальный GPU-рендер (караоке, хук, плашка, нарезка)    │
│  - Отправка готовых серий на VPS через Multipart API       │
└─────────────────────────────┬──────────────────────────────┘
                              │ POST /api/v1/remote/upload-task
                              ▼
┌────────────────────────────────────────────────────────────┐
│              Remote Autoposter Server (Linux VPS)          │
│                                                            │
│  ┌───────────────────────┐       ┌──────────────────────┐  │
│  │   FastAPI Backend     │ ◄───► │  PostgreSQL / SQLite │  │
│  │   Upload / Webhooks   │       │  Очереди и расписание│  │
│  └───────────┬───────────┘       └──────────────────────┘  │
│              │                                             │
│              ▼                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │      Camoufox Headless Workers (Playwright Python)   │  │
│  │  - Эмуляция реальных браузерных сессий (Stealth)     │  │
│  │  - Проброс SOCKS5/HTTP через локальные порты Xray    │  │
│  └───────┬──────────────────────┬──────────────────────┬┘  │
│          │ socks5://127.0.0.1:20001                     │  │
│          │                      │ socks5://127.0.0.1:20002 │
│          ▼                      ▼                      ▼   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │               Xray-core Service (Sidecar)            │  │
│  │  - Мульти-инбаунды (SOCKS5/HTTP на портах 20001-N)   │  │
│  │  - VLESS + XTLS Reality / Trojan / Shadowsocks       │  │
│  │  - Маршрутизация по аккаунтам и соцсетям             │  │
│  └───────┬──────────────────────┬──────────────────────┬┘  │
└──────────┼──────────────────────┼──────────────────────┼───┘
           │ VLESS-Reality        │ VLESS-Reality        │
           ▼                      ▼                      ▼
     ┌───────────┐          ┌───────────┐          ┌───────────┐
     │  TikTok   │          │  YouTube  │          │ Instagram │
     │  Creator  │          │  Studio   │          │   Reels   │
     │  Center   │          │  (Web UI) │          │  (Web UI) │
     └───────────┘          └───────────┘          └───────────┘
                                  ▲
                                  │ Уведомления и кнопки управления
                                  ▼
                  ┌───────────────────────────────┐
                  │      Telegram Admin Bot       │
                  │  - Карточки утверждения       │
                  │  - Кнопки «Опубликовать»,     │
                  │    «Перенести», «Изменить»    │
                  │  - Отчеты с прямыми ссылками  │
                  └───────────────────────────────┘
```

---

## 2. Конфигурация Xray-core (`xray_config.json`)

Xray-core поднимает изолированный локальный порт SOCKS5/HTTP для каждого профиля/аккаунта, маскируя трафик через VLESS-Reality:

```json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "socks_in_tt_01",
      "port": 20001,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      }
    },
    {
      "tag": "socks_in_yt_01",
      "port": 20002,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      }
    },
    {
      "tag": "socks_in_ig_01",
      "port": 20003,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "tag": "out_vless_reality_us",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "egress-node.example.com",
            "port": 443,
            "users": [
              {
                "id": "a918237b-9182-4212-9843-128934789123",
                "encryption": "none",
                "flow": "xtls-rprx-vision"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.microsoft.com:443",
          "xver": 0,
          "serverNames": ["www.microsoft.com"],
          "privateKey": "YOUR_PRIVATE_REALITY_KEY",
          "shortIds": ["0123456789abcdef"]
        }
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "inboundTag": ["socks_in_tt_01", "socks_in_yt_01", "socks_in_ig_01"],
        "outboundTag": "out_vless_reality_us"
      }
    ]
  }
}
```

---

## 3. Интеграция Camoufox с Xray-core

В коде воркера Python передается адрес локального SOCKS5-инбаунда Xray:

```python
from camoufox.sync_api import Camoufox

def get_stealth_browser_with_xray(profile_dir: str, xray_socks_port: int = 20001):
    """
    Запуск антидетект-браузера Camoufox через локальный Xray VLESS-Reality туннель
    """
    launch_args = {
        "user_data_dir": profile_dir,
        "headless": True,
        "geoip": True,  # Подстраивает часовой пояс и локаль под выходной узел Xray
        "proxy": {
            "server": f"socks5://127.0.0.1:{xray_socks_port}"
        }
    }
    return Camoufox(**launch_args)
```

---

## 4. Схема Базы Данных (PostgreSQL DDL)

```sql
-- Профили аккаунтов Camoufox с привязкой к портам Xray
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    account_key VARCHAR(64) UNIQUE NOT NULL,      -- e.g. "tt_psych_01"
    platform VARCHAR(32) NOT NULL,                -- 'tiktok', 'youtube', 'instagram'
    profile_dir_path VARCHAR(255) NOT NULL,       -- "/app/profiles/tt_psych_01"
    xray_inbound_port INT NOT NULL,               -- e.g. 20001
    daily_limit INT DEFAULT 10,
    posts_today INT DEFAULT 0,
    status VARCHAR(32) DEFAULT 'active',          -- 'active', 'needs_reauth', 'cooldown'
    last_used_at TIMESTAMP WITH TIME ZONE
);

-- Группы сериалов (нарезка одного ролика на N частей)
CREATE TABLE series (
    id SERIAL PRIMARY KEY,
    series_uuid VARCHAR(64) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    total_parts INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Отдельные посты (серии)
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    series_id INT REFERENCES series(id) ON DELETE CASCADE,
    part_number INT NOT NULL,
    local_video_path VARCHAR(512) NOT NULL,
    hook_title VARCHAR(255) NOT NULL,
    caption TEXT NOT NULL,
    call_to_action TEXT,
    hashtags TEXT[] DEFAULT '{}',
    scheduled_time_utc TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(32) DEFAULT 'pending_approval', -- 'pending_approval', 'scheduled', 'uploading', 'published', 'failed'
    telegram_message_id BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Результаты загрузки в каждую платформу
CREATE TABLE post_targets (
    id SERIAL PRIMARY KEY,
    post_id INT REFERENCES posts(id) ON DELETE CASCADE,
    account_id INT REFERENCES accounts(id),
    platform VARCHAR(32) NOT NULL,
    external_post_url VARCHAR(512),
    status VARCHAR(32) DEFAULT 'queued',           -- 'queued', 'running', 'success', 'failed'
    error_message TEXT,
    published_at_utc TIMESTAMP WITH TIME ZONE
);
```

---

## 5. API Приема Контента (TT Automator ➔ VPS)

### `POST /api/v1/remote/upload-task`

Используется приложением TT Video Automator для передачи отрендеренного ролика и метаданных на сервер.

#### Request Headers:
```http
POST /api/v1/remote/upload-task HTTP/1.1
Host: autoposter.your-server.com
Authorization: Bearer YOUR_SUPER_SECRET_KEY
Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryXPN
```

#### Request Payload (Multipart):
- `video_file`: Бинарный MP4-файл.
- `metadata`: JSON-строка:

```json
{
  "client_task_id": 42,
  "series": {
    "series_uuid": "ser_20260818_psych_01",
    "series_title": "Психология мужчин, которые слишком много думают",
    "part_number": 1,
    "total_parts": 4
  },
  "media_info": {
    "duration_seconds": 57.5,
    "filesize_bytes": 18203326
  },
  "content": {
    "hook_title": "Твой мозг держит тебя в заложниках",
    "caption": "Ты устаешь не от работы, а от бесконечного шума в собственной голове. Твой вечный анализ — это не подготовка к будущему, а просто замаскированный страх сделать первый шаг.\n\nНапиши в комментариях: как часто мысли мешают тебе начать действовать? 👇",
    "call_to_action": "Ставь лайк, отправь другу и переходи в Telegram по ссылке в описании профиля.",
    "hashtags": ["#психология", "#саморазвитие", "#мысли", "#оверсинкинг", "#fyp"]
  },
  "scheduling": {
    "strategy": "auto_staggered",
    "preferred_start_utc": "2026-08-18T12:00:00Z",
    "interval_minutes": 180,
    "require_telegram_approval": true
  },
  "targets": [
    { "platform": "tiktok", "account_key": "tt_psych_01" },
    { "platform": "youtube", "account_key": "yt_psych_01" },
    { "platform": "instagram", "account_key": "ig_psych_01" }
  ]
}
```

---

## 6. Docker Compose Развертывание с Xray-core

```yaml
version: '3.8'

services:
  xray:
    image: teddysun/xray:latest
    container_name: autoposter_xray
    restart: always
    volumes:
      - ./xray_config.json:/etc/xray/config.json
    ports:
      - "127.0.0.1:20001-20010:20001-20010"

  postgres:
    image: postgres:15-alpine
    container_name: autoposter_postgres
    restart: always
    environment:
      POSTGRES_DB: autoposter_db
      POSTGRES_USER: autoposter_user
      POSTGRES_PASSWORD: super_secure_db_password
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    container_name: autoposter_redis
    restart: always
    volumes:
      - redisdata:/data

  autoposter_app:
    build: .
    container_name: autoposter_camoufox
    restart: always
    command: sh -c "Xvfb :99 -screen 0 1920x1080x24 & export DISPLAY=:99 && uvicorn main:app --host 0.0.0.0 --port 8000"
    environment:
      DATABASE_URL: postgresql://autoposter_user:super_secure_db_password@postgres:5432/autoposter_db
      REDIS_URL: redis://redis:6379/0
      API_SECRET_TOKEN: YOUR_SUPER_SECRET_KEY
      TELEGRAM_BOT_TOKEN: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz
      TELEGRAM_ADMIN_CHAT_ID: 987654321
    volumes:
      - media_storage:/app/storage
      - camoufox_profiles:/app/profiles
    ports:
      - "8000:8000"
    depends_on:
      - xray
      - postgres
      - redis

volumes:
  pgdata:
  redisdata:
  media_storage:
  camoufox_profiles:
```

---

## 7. Подводные камни и Решения (Xray-core + Camoufox)

1. **DNS Leak (Утечка DNS через системный резолвер)**:
   - Если Camoufox делает DNS-запросы мимо Xray, целевые соцсети увидят реальный IP хостинга VPS.
   - **Решение**: В настройках браузера Playwright и Xray включается удаленный DNS-резолвинг (`"socks5://127.0.0.1:20001"`, режим `remote_dns=True` в Firefox через `network.proxy.socks_remote_dns = true`).
2. **Разрыв Reality-туннеля при пиковых сетевых нагрузках**:
   - При отдаче 100 МБ потока TCP-буфер VLESS может кратковременно сбросить скорость.
   - **Решение**: Использование Flow `xtls-rprx-vision` с включенным TCP BBR на сервере (`sysctl net.ipv4.tcp_congestion_control=bbr`).
3. **Хелсчек выходных узлов Xray перед запуском сессии**:
   - Перед стартом Camoufox воркер делает легкий HTTP HEAD запрос к `https://www.google.com/generate_204` через локальный порт Xray. Если ответ не получен в течение 3 сек, задача не начинает браузерную сессию, а шлет алерт в Telegram.
