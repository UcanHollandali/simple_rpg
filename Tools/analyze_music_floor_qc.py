from __future__ import annotations

from pathlib import Path

import numpy as np
import soundfile as sf


ROOT = Path(__file__).resolve().parent.parent
TRACKS = (
    {
        "label": "ui_hub",
        "path": ROOT / "Assets" / "Audio" / "Music" / "music_ui_hub_loop_proto_01.ogg",
        "max_centroid_hz": 900.0,
        "max_hi_ratio_4k": 0.05,
        "max_loop_sample_jump": 0.01,
    },
    {
        "label": "combat",
        "path": ROOT / "Assets" / "Audio" / "Music" / "music_combat_loop_proto_01.ogg",
        "max_centroid_hz": 1_500.0,
        "max_hi_ratio_4k": 0.08,
        "max_loop_sample_jump": 0.01,
    },
    {
        "label": "run_end",
        "path": ROOT / "Assets" / "Audio" / "Music" / "music_run_end_loop_proto_01.ogg",
        "max_centroid_hz": 900.0,
        "max_hi_ratio_4k": 0.05,
        "max_loop_sample_jump": 0.01,
    },
)


def analyze_track(path: Path) -> dict[str, float]:
    signal, sample_rate = sf.read(path, always_2d=True)
    mono = np.mean(signal, axis=1)
    rms = float(np.sqrt(np.mean(np.square(mono))))
    peak = float(np.max(np.abs(mono)))
    crest = peak / max(rms, 1e-9)
    fft = np.fft.rfft(mono)
    magnitudes = np.abs(fft)
    freqs = np.fft.rfftfreq(mono.size, d=1.0 / sample_rate)
    centroid_hz = 0.0
    if np.any(magnitudes):
        centroid_hz = float(np.sum(freqs * magnitudes) / np.sum(magnitudes))
    hi_band = float(np.sum(magnitudes[freqs >= 4_000.0]))
    hi_ratio_4k = hi_band / max(float(np.sum(magnitudes)), 1e-9)
    loop_sample_jump = abs(float(mono[0] - mono[-1])) if mono.size >= 2 else 0.0
    loop_slope_jump = (
        abs(float((mono[1] - mono[0]) - (mono[-1] - mono[-2])))
        if mono.size >= 4
        else 0.0
    )
    return {
        "duration_seconds": signal.shape[0] / float(sample_rate),
        "sample_rate": float(sample_rate),
        "rms": rms,
        "peak": peak,
        "crest": crest,
        "centroid_hz": centroid_hz,
        "hi_ratio_4k": hi_ratio_4k,
        "loop_sample_jump": loop_sample_jump,
        "loop_slope_jump": loop_slope_jump,
    }


def fail(message: str) -> None:
    raise SystemExit(message)


def main() -> None:
    print("music_floor_qc")
    for track in TRACKS:
        path: Path = track["path"]
        if not path.exists():
            fail(f"Missing music floor asset: {path}")
        metrics = analyze_track(path)
        print(
            "%s duration=%.2fs sr=%d rms=%.4f peak=%.4f crest=%.3f centroid=%.1fHz hi_ratio_4k=%.4f loop_sample_jump=%.6f loop_slope_jump=%.6f"
            % (
                track["label"],
                metrics["duration_seconds"],
                int(metrics["sample_rate"]),
                metrics["rms"],
                metrics["peak"],
                metrics["crest"],
                metrics["centroid_hz"],
                metrics["hi_ratio_4k"],
                metrics["loop_sample_jump"],
                metrics["loop_slope_jump"],
            )
        )
        if metrics["centroid_hz"] > track["max_centroid_hz"]:
            fail(
                "%s centroid %.1fHz exceeded threshold %.1fHz."
                % (track["label"], metrics["centroid_hz"], track["max_centroid_hz"])
            )
        if metrics["hi_ratio_4k"] > track["max_hi_ratio_4k"]:
            fail(
                "%s hi_ratio_4k %.4f exceeded threshold %.4f."
                % (track["label"], metrics["hi_ratio_4k"], track["max_hi_ratio_4k"])
            )
        if metrics["loop_sample_jump"] > track["max_loop_sample_jump"]:
            fail(
                "%s loop_sample_jump %.6f exceeded threshold %.6f."
                % (
                    track["label"],
                    metrics["loop_sample_jump"],
                    track["max_loop_sample_jump"],
                )
            )
    print("music_floor_qc: ok")


if __name__ == "__main__":
    main()
