#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Anti YouTube Content ID Video Tester v5 (Deep Visual Transformation)
Применяет радикальные визуальные фильтры (Speed 1.15x, Vintage LUT, 30s cut, Lightleak overlay, PiP)
вместе с подтвержденным аудио T4.
"""

import argparse
import os
import sys
import subprocess
import time
from pathlib import Path

# Цвета для вывода в консоль
GREEN = "\033[92m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
RED = "\033[91m"
BOLD = "\033[1m"
RESET = "\033[0m"

V5_PROFILES = {
    "v5_x1_speed_115_zoom35": {
        "name": "X1: Скорость 1.15x + Зум 35% (Ломает оптический поток кадров)",
        "desc": "Ускорение на 15% (быстрое движение актеров сбивает нейросеть детекции) + зум 35% + зеркало + виньетка + T4 аудио.",
        "speed": 1.15,
        "crop_ratio": 0.35,
        "mirror": True,
        "mode": "speed_zoom",
        "pitch_rate": 1.12,
        "music_volume": 0.40,
    },
    "v5_x2_vintage_film_grade": {
        "name": "X2: Vintage Film Grading (Кинопленка / Ломает цветовые гистограммы)",
        "desc": "Стилизация под кинопленку (curves=vintage + ч/б примесь + контраст) + зум 30% + зеркало + T4 аудио.",
        "speed": 1.05,
        "crop_ratio": 0.30,
        "mirror": True,
        "mode": "vintage_grade",
        "pitch_rate": 1.09,
        "music_volume": 0.40,
    },
    "v5_x3_pip_mini_window_35pct": {
        "name": "X3: PiP Мини-окно 35% экрана на фоне видео природы",
        "desc": "Сериал занимает всего 35% экрана в круглом/прямоугольном окне с рамкой на фоне природы + T4 аудио.",
        "speed": 1.04,
        "crop_ratio": 0.10,
        "mirror": True,
        "mode": "pip_window",
        "pitch_rate": 1.08,
        "music_volume": 0.40,
    },
    "v5_x4_short_30s_threshold": {
        "name": "X4: Микро-клип 30 секунд (Ниже порога детекции правообладателя)",
        "desc": "Ролик длительностью 30 секунд (порог срабатывания Content ID обычно 30-45 сек) + зум 35% + зеркало + T4 аудио.",
        "speed": 1.06,
        "crop_ratio": 0.35,
        "mirror": True,
        "mode": "short_30s",
        "duration_cap": 30.0,
        "pitch_rate": 1.09,
        "music_volume": 0.40,
    },
    "v5_x5_scanlines_noise_heavy": {
        "name": "X5: Scanlines + Heavy Temporal Grain + Dynamic Glitch",
        "desc": "Наложение полупрозрачных горизонтальных скан-линий и тяжелого шума поверх зума 30% (разбивает матрицу пикселей) + T4 аудио.",
        "speed": 1.05,
        "crop_ratio": 0.30,
        "mirror": True,
        "mode": "scanlines",
        "pitch_rate": 1.09,
        "music_volume": 0.40,
    },
}

def build_ffmpeg_command(
    input_file: str,
    output_file: str,
    profile_key: str,
    bg_video_path: str,
    use_nvenc: bool = True,
) -> list:
    cfg = V5_PROFILES[profile_key]
    
    cmd = ["ffmpeg", "-hide_banner", "-y"]
    
    if cfg.get("duration_cap"):
        cmd.extend(["-t", str(cfg["duration_cap"])])
        
    cmd.extend(["-i", input_file]) # Input 0
    
    has_bg_video = cfg["mode"] in ["pip_window"]
    if has_bg_video:
        cmd.extend(["-stream_loop", "-1", "-i", bg_video_path]) # Input 1
        
    # Synthetic harmonic music bed for T4 audio
    cmd.extend([
        "-f", "lavfi",
        "-i", "aevalsrc=0.18*sin(180*2*PI*t)*sin(2*2*PI*t)+0.12*sin(360*2*PI*t)*cos(4*2*PI*t)+0.10*sin(540*2*PI*t)*sin(8*2*PI*t):s=48000:d=300"
    ])
    music_idx = 2 if has_bg_video else 1
    
    filter_complex = []
    mode = cfg["mode"]
    
    # --- ВИДЕО ФИЛЬТРЫ ---
    if mode == "pip_window":
        v_card = "[0:v]"
        if cfg["mirror"]:
            filter_complex.append(f"{v_card}hflip[v_pip_m]")
            v_card = "[v_pip_m]"
        filter_complex.append(
            "[1:v]scale=720:1280:flags=fast_bilinear:force_original_aspect_ratio=increase,crop=720:1280[bg_vid]"
        )
        # Small reaction window in center: 420x540
        filter_complex.append(
            f"{v_card}scale=420:540:flags=fast_bilinear:force_original_aspect_ratio=increase,crop=420:540,"
            f"drawbox=x=0:y=0:w=iw:h=ih:color=white@0.9:t=6,"
            f"eq=contrast=1.12:saturation=1.15[pip_fg]"
        )
        filter_complex.append(
            f"[bg_vid][pip_fg]overlay=(W-w)/2:(H-h)/2:shortest=1,noise=alls=5:allf=t+u[v_framed]"
        )
        pts = 1.0 / cfg["speed"]
        filter_complex.append(f"[v_framed]setpts={pts:.4f}*PTS[v_out]")
        
    elif mode == "vintage_grade":
        v_cur = "[0:v]"
        if cfg["mirror"]:
            filter_complex.append(f"{v_cur}hflip[v_m]")
            v_cur = "[v_m]"
        crop_fac = 1.0 - cfg["crop_ratio"]
        filter_complex.append(
            f"{v_cur}crop=in_w*{crop_fac:.3f}:in_h*{crop_fac:.3f}:(in_w-out_w)/2:(in_h-out_h)/2,"
            f"scale=720:1280:flags=fast_bilinear,"
            f"curves=vintage,"
            f"eq=contrast=1.18:saturation=0.88:brightness=0.03,"
            f"vignette=angle=PI/3.8,"
            f"noise=alls=7:allf=t+u[v_vint]"
        )
        pts = 1.0 / cfg["speed"]
        filter_complex.append(f"[v_vint]setpts={pts:.4f}*PTS[v_out]")
        
    elif mode == "scanlines":
        v_cur = "[0:v]"
        if cfg["mirror"]:
            filter_complex.append(f"{v_cur}hflip[v_m]")
            v_cur = "[v_m]"
        crop_fac = 1.0 - cfg["crop_ratio"]
        filter_complex.append(
            f"{v_cur}crop=in_w*{crop_fac:.3f}:in_h*{crop_fac:.3f}:(in_w-out_w)/2:(in_h-out_h)/2,"
            f"scale=720:1280:flags=fast_bilinear,"
            f"drawgrid=w=720:h=4:t=1:color=black@0.18,"
            f"eq=contrast=1.15:saturation=1.20:brightness=0.02,"
            f"vignette=angle=PI/4.0,"
            f"noise=alls=8:allf=t+u[v_scan]"
        )
        pts = 1.0 / cfg["speed"]
        filter_complex.append(f"[v_scan]setpts={pts:.4f}*PTS[v_out]")
        
    else: # speed_zoom & short_30s
        v_cur = "[0:v]"
        if cfg["mirror"]:
            filter_complex.append(f"{v_cur}hflip[v_m]")
            v_cur = "[v_m]"
        crop_fac = 1.0 - cfg["crop_ratio"]
        filter_complex.append(
            f"{v_cur}crop=in_w*{crop_fac:.3f}:in_h*{crop_fac:.3f}:(in_w-out_w)/2:(in_h-out_h)/2,"
            f"scale=720:1280:flags=fast_bilinear,"
            f"eq=contrast=1.14:saturation=1.18:brightness=0.02:gamma=0.94,"
            f"colorbalance=rs=0.06:gs=-0.02:bs=0.04,"
            f"vignette=angle=PI/4.0,"
            f"noise=alls=7:allf=t+u[v_proc]"
        )
        pts = 1.0 / cfg["speed"]
        filter_complex.append(f"[v_proc]setpts={pts:.4f}*PTS[v_out]")
        
    # --- PROVEN T4 AUDIO FILTER ---
    rate_mult = cfg["pitch_rate"]
    speed_val = cfg["speed"]
    atempo_comp = speed_val / rate_mult
    
    a_cur = "[0:a]"
    new_rate = int(48000 * rate_mult)
    filter_complex.append(
        f"{a_cur}asetrate={new_rate},aresample=48000,atempo={atempo_comp:.4f}[a_formant]"
    )
    a_cur = "[a_formant]"
    filter_complex.append(
        f"{a_cur}highpass=f=110,lowpass=f=7600,equalizer=f=1200:t=q:w=1.5:g=3.2,equalizer=f=3500:t=q:w=1.2:g=-3.5[a_eq]"
    )
    a_cur = "[a_eq]"
    vol = cfg.get("music_volume", 0.40)
    filter_complex.append(f"[{music_idx}:a]volume={vol:.2f}[bg_m]")
    filter_complex.append(f"{a_cur}[bg_m]amix=inputs=2:duration=first:dropout_transition=2[a_out]")
    
    fc_str = ";".join(filter_complex)
    cmd.extend(["-filter_complex", fc_str])
    cmd.extend(["-map", "[v_out]", "-map", "[a_out]"])
    cmd.extend(["-shortest"])
    
    if use_nvenc:
        cmd.extend([
            "-c:v", "h264_nvenc",
            "-preset", "p1",
            "-rc", "vbr",
            "-cq", "24",
            "-b:v", "2M",
            "-maxrate", "3M",
            "-bufsize", "4M",
            "-pix_fmt", "yuv420p"
        ])
    else:
        cmd.extend([
            "-c:v", "libx264",
            "-preset", "fast",
            "-crf", "22",
            "-pix_fmt", "yuv420p"
        ])
        
    cmd.extend([
        "-c:a", "aac",
        "-b:a", "128k",
        "-map_metadata", "-1",
        "-metadata", "make=Apple",
        "-metadata", "model=iPhone 15 Pro",
        "-metadata", "software=17.4",
        output_file
    ])
    
    return cmd

def render_profile(
    input_file: str,
    output_dir: str,
    profile_key: str,
    bg_video_path: str,
    use_nvenc: bool = True,
) -> str:
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    input_stem = Path(input_file).stem
    output_file = os.path.join(output_dir, f"{input_stem}_{profile_key}.mp4")
    
    cfg = V5_PROFILES[profile_key]
    print(f"\n{CYAN}{BOLD}▶ Рендеринг: {cfg['name']}{RESET}")
    print(f"  {YELLOW}Суть: {cfg['desc']}{RESET}")
    print(f"  {YELLOW}Выходной файл: {output_file}{RESET}")
    
    cmd = build_ffmpeg_command(
        input_file=input_file,
        output_file=output_file,
        profile_key=profile_key,
        bg_video_path=bg_video_path,
        use_nvenc=use_nvenc,
    )
    
    start_time = time.time()
    try:
        proc = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="replace"
        )
        elapsed = time.time() - start_time
        
        if proc.returncode == 0:
            file_size_mb = os.path.getsize(output_file) / (1024 * 1024)
            print(f"  {GREEN}✔ Успешно за {elapsed:.1f} сек! Размер: {file_size_mb:.1f} МБ{RESET}")
            return output_file
        else:
            if use_nvenc:
                print(f"  {YELLOW}⚠ NVENC не сработал, пробуем CPU (libx264)...{RESET}")
                return render_profile(input_file, output_dir, profile_key, bg_video_path, use_nvenc=False)
            print(f"  {RED}✘ Ошибка FFmpeg (код {proc.returncode}):\n{proc.stderr[-500:]}{RESET}")
            return None
    except Exception as e:
        print(f"  {RED}✘ Исключение при выполнении: {e}{RESET}")
        return None

def generate_matrix_markdown(output_dir: str, rendered_files: dict):
    md_path = os.path.join(output_dir, "TEST_MATRIX_V5.md")
    with open(md_path, "w", encoding="utf-8") as f:
        f.write("# Таблица Радикального Прорыва v5 (со звуком T4)\n\n")
        f.write("Загрузите эти 5 файлов в YouTube Studio («Доступ по ссылке»).\n\n")
        f.write("| Файл | Профиль | Видео метод | Аудио метод |\n")
        f.write("|---|---|---|---|\n")
        f.write("| `..._v5_x1_speed_115_zoom35.mp4` | **X1: Скорость 1.15x + Zoom 35%** | Сбивает оптический поток движения | T4 (Formant +12% + Music 40%) |\n")
        f.write("| `..._v5_x2_vintage_film_grade.mp4` | **X2: Vintage Film Grade** | Ломает гистограммы цветов | T4 (Formant +9% + Music 40%) |\n")
        f.write("| `..._v5_x3_pip_mini_window_35pct.mp4` | **X3: PiP Окно 35% на природе** | Сериал занимает лишь 35% экрана | T4 (Formant +8% + Music 40%) |\n")
        f.write("| `..._v5_x4_short_30s_threshold.mp4` | **X4: Клип 30 секунд** | Ниже лимита детекции правообладателя | T4 (Formant +9% + Music 40%) |\n")
        f.write("| `..._v5_x5_scanlines_noise_heavy.mp4` | **X5: Scanlines + Шум 8** | Ломает пиксельную матрицу кадра | T4 (Formant +9% + Music 40%) |\n")
    print(f"\n{GREEN}📄 Таблица с описанием сохранена в: {md_path}{RESET}")

def main():
    parser = argparse.ArgumentParser(description="YouTube Content ID Visual Breakthrough Tester v5")
    parser.add_argument(
        "--input", "-i",
        default=r"K:\папка Андрея\курсы\vless\XPN\recomend\01_part1_unique.mp4",
        help="Путь к исходному проблемному видео"
    )
    parser.add_argument(
        "--bg-video",
        default=r"K:\папка Андрея\курсы\vless\XPN\recomend\Природа HD Качество Короткое Видео [get-save_unique.mp4",
        help="Путь к фоновому видео (природа/геймплей) для PiP"
    )
    parser.add_argument(
        "--output-dir", "-o",
        default=r"K:\папка Андрея\курсы\vless\XPN\recomend\test_antiban_v5",
        help="Папка для сохранения тестовых вариантов"
    )
    parser.add_argument(
        "--profile", "-p",
        choices=list(V5_PROFILES.keys()) + ["all"],
        default="all",
        help="Какой профиль отрендерить"
    )
    parser.add_argument(
        "--cpu",
        action="store_true",
        help="Использовать кодек CPU (libx264) вместо GPU NVENC"
    )
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        print(f"{RED}Ошибка: Исходный файл не найден: {args.input}{RESET}")
        sys.exit(1)
        
    print(f"\n{BOLD}=== Генератор Радикального Прорыва v5 ==={RESET}")
    use_nvenc = not args.cpu
    rendered_files = {}
    
    if args.profile == "all":
        for key in V5_PROFILES:
            out = render_profile(args.input, args.output_dir, key, args.bg_video, use_nvenc=use_nvenc)
            rendered_files[key] = out
    else:
        out = render_profile(args.input, args.output_dir, args.profile, args.bg_video, use_nvenc=use_nvenc)
        rendered_files[args.profile] = out
        
    generate_matrix_markdown(args.output_dir, rendered_files)
    print(f"\n{GREEN}{BOLD} Готово! Все варианты отрендерены в {args.output_dir}{RESET}\n")

if __name__ == "__main__":
    main()
