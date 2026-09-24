#!/usr/bin/env python3
"""
scripts/extract_video_frames.py

Extrator inteligente e ultrarrápido de frames para análise multimodal e OCR com IA.
Extrai keyframes de tela distribuídos temporalmente, redimensionados e compactados,
com timestamps precisos para correlação com a transcrição do áudio (Whisper).

Uso:
    python3 scripts/extract_video_frames.py <caminho_video> <dir_saida_frames> [--max-frames 20]
"""

import sys
import os
import json
import argparse
import subprocess
import hashlib
from pathlib import Path

def get_video_duration(video_path: str) -> float:
    """Obtém a duração total do vídeo em segundos via ffprobe."""
    cmd = [
        "ffprobe",
        "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1",
        video_path
    ]
    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        return float(res.stdout.strip())
    except Exception as e:
        sys.stderr.write(f"Aviso: falha ao obter duração via ffprobe ({e}). Usando padrão de 60s.\n")
        return 60.0

def format_timestamp(seconds: float) -> str:
    """Formata segundos em HH:MM:SS."""
    secs = int(round(seconds))
    h = secs // 3600
    m = (secs % 3600) // 60
    s = secs % 60
    if h > 0:
        return f"{h:02d}:{m:02d}:{s:02d}"
    return f"{m:02d}:{s:02d}"

def calculate_sampling_timestamps(duration: float, max_frames: int = 20, min_frames: int = 5) -> list:
    """
    Calcula os timestamps de amostragem inteligentes baseados na duração do vídeo.
    Evita bordas extremas (primeiros e últimos 3 segundos) onde costumam ocorrer telas pretas ou vinhetas.
    """
    if duration <= 10.0:
        # Vídeos curtíssimos
        return [max(1.0, duration / 2.0)]

    # Margem de segurança de início e fim
    start_margin = min(5.0, duration * 0.05)
    end_margin = max(duration - 5.0, duration * 0.95)
    usable_duration = end_margin - start_margin

    if duration < 60:
        # Vídeos curtos (< 1 min): 1 frame a cada 8-12s
        target_count = min(max_frames, max(min_frames, int(duration // 10)))
    elif duration < 300:
        # Vídeos médios (1-5 min): 1 frame a cada 15-25s
        target_count = min(max_frames, max(min_frames, int(duration // 20)))
    elif duration < 1200:
        # Vídeos de 5-20 min: ~15-20 frames
        target_count = min(max_frames, max(min_frames, 15))
    else:
        # Vídeos longos (> 20 min): max_frames espaçados uniformemente
        target_count = max_frames

    step = usable_duration / (target_count + 1)
    timestamps = [start_margin + (i + 1) * step for i in range(target_count)]
    return [round(ts, 1) for ts in timestamps]

def extract_frame_at(video_path: str, timestamp_s: float, output_path: str) -> bool:
    """Extrai um único frame no timestamp com redimensionamento e compressão otimizados."""
    cmd = [
        "ffmpeg",
        "-y",
        "-nostdin",
        "-ss", str(timestamp_s),
        "-i", video_path,
        "-frames:v", "1",
        "-vf", "scale=1280:-1:flags=lanczos",
        "-q:v", "4",
        output_path
    ]
    try:
        subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        return os.path.exists(output_path) and os.path.getsize(output_path) > 1000
    except subprocess.CalledProcessError:
        return False

def compute_file_hash(filepath: str) -> str:
    """Calcula hash rápido MD5 dos primeiros 32KB do frame para detecção de duplicatas estáticas."""
    try:
        hasher = hashlib.md5()
        with open(filepath, "rb") as f:
            chunk = f.read(32768)
            hasher.update(chunk)
        return hasher.hexdigest()
    except Exception:
        return ""

def main():
    parser = argparse.ArgumentParser(description="Extrator de frames de vídeo para Visão Multimodal.")
    parser.add_argument("video_path", help="Caminho do arquivo de vídeo (.mp4, etc.)")
    parser.add_argument("output_dir", help="Diretório de saída para salvar os frames")
    parser.add_argument("--max-frames", type=int, default=20, help="Número máximo de frames (padrão: 20)")
    parser.add_argument("--min-frames", type=int, default=5, help="Número mínimo de frames (padrão: 5)")
    args = parser.parse_args()

    video_path = os.path.abspath(args.video_path)
    output_dir = os.path.abspath(args.output_dir)

    if not os.path.isfile(video_path):
        sys.stderr.write(f"Erro: arquivo de vídeo não encontrado: {video_path}\n")
        sys.exit(1)

    os.makedirs(output_dir, exist_ok=True)

    duration = get_video_duration(video_path)
    timestamps = calculate_sampling_timestamps(duration, max_frames=args.max_frames, min_frames=args.min_frames)

    extracted_frames = []
    seen_hashes = set()

    for idx, ts in enumerate(timestamps, start=1):
        time_str = format_timestamp(ts)
        safe_time = time_str.replace(":", "m") + "s"
        frame_filename = f"frame_{idx:03d}_{safe_time}.jpg"
        frame_path = os.path.join(output_dir, frame_filename)

        if extract_frame_at(video_path, ts, frame_path):
            f_size = os.path.getsize(frame_path)
            f_hash = compute_file_hash(frame_path)

            # Evita duplicatas consecutivas idênticas (ex: slide parado por longo período)
            if f_hash and f_hash in seen_hashes and len(extracted_frames) >= args.min_frames:
                try:
                    os.remove(frame_path)
                except OSError:
                    pass
                continue

            seen_hashes.add(f_hash)
            extracted_frames.append({
                "index": idx,
                "filename": frame_filename,
                "path": frame_path,
                "timestamp_s": ts,
                "time_str": time_str,
                "size_bytes": f_size
            })

    # Grava manifesto com os metadados dos frames
    manifest_path = os.path.join(output_dir, "frames_manifest.json")
    manifest = {
        "video": os.path.basename(video_path),
        "duration_s": duration,
        "duration_formatted": format_timestamp(duration),
        "total_frames": len(extracted_frames),
        "frames": extracted_frames
    }

    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)

    print(json.dumps({
        "ok": True,
        "count": len(extracted_frames),
        "duration_s": duration,
        "manifest": manifest_path
    }))

if __name__ == "__main__":
    main()
