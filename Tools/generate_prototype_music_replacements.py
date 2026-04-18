from __future__ import annotations

import math
import shutil
import subprocess
from pathlib import Path

import imageio_ffmpeg
import numpy as np
import soundfile as sf


SAMPLE_RATE = 44_100
ROOT = Path(__file__).resolve().parent.parent
SOURCE_DIR = ROOT / "SourceArt" / "Edited"
RUNTIME_DIR = ROOT / "Assets" / "Audio" / "Music"
TRACKS = (
    {
        "asset_name": "music_ui_hub_loop_proto_01",
        "master_name": "music_ui_hub_loop_proto_01_master_v001.ogg",
        "builder": "build_ui_hub_track",
        "duration_seconds": 28.0,
    },
    {
        "asset_name": "music_combat_loop_proto_01",
        "master_name": "music_combat_loop_proto_01_master_v001.ogg",
        "builder": "build_combat_track",
        "duration_seconds": 24.0,
    },
    {
        "asset_name": "music_run_end_loop_proto_01",
        "master_name": "music_run_end_loop_proto_01_master_v001.ogg",
        "builder": "build_run_end_track",
        "duration_seconds": 20.0,
    },
)


def midi_to_hz(midi_note: int) -> float:
    return 440.0 * (2.0 ** ((midi_note - 69) / 12.0))


def frac(values: np.ndarray) -> np.ndarray:
    return values - np.floor(values)


def sine_wave(frequency: float | np.ndarray, timeline: np.ndarray, phase: float = 0.0) -> np.ndarray:
    return np.sin((2.0 * np.pi * frequency * timeline) + phase)


def triangle_wave(frequency: float | np.ndarray, timeline: np.ndarray, phase: float = 0.0) -> np.ndarray:
    return 2.0 * np.abs((2.0 * frac((frequency * timeline) + (phase / (2.0 * np.pi)))) - 1.0) - 1.0


def smooth_noise(length: int, seed: int, kernel_size: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    noise = rng.normal(0.0, 1.0, length + kernel_size - 1)
    kernel = np.hanning(kernel_size)
    kernel /= np.sum(kernel)
    return np.convolve(noise, kernel, mode="valid")


def one_pole_lowpass(signal: np.ndarray, cutoff_hz: float, sample_rate: int = SAMPLE_RATE) -> np.ndarray:
    if cutoff_hz <= 0.0:
        return np.zeros_like(signal)
    alpha = 1.0 - math.exp((-2.0 * math.pi * cutoff_hz) / sample_rate)
    filtered = np.empty_like(signal)
    accumulator = 0.0
    for index, sample in enumerate(signal):
        accumulator += alpha * (sample - accumulator)
        filtered[index] = accumulator
    return filtered


def highpass_from_lowpass(signal: np.ndarray, cutoff_hz: float, sample_rate: int = SAMPLE_RATE) -> np.ndarray:
    return signal - one_pole_lowpass(signal, cutoff_hz, sample_rate)


def stereoize(left: np.ndarray, right: np.ndarray) -> np.ndarray:
    return np.stack((left, right), axis=1)


def pan_stereo(mono_signal: np.ndarray, pan: float) -> np.ndarray:
    pan_clamped = max(-1.0, min(1.0, pan))
    angle = (pan_clamped + 1.0) * (math.pi / 4.0)
    left = mono_signal * math.cos(angle)
    right = mono_signal * math.sin(angle)
    return stereoize(left, right)


def additive_pad(note_hz: float, timeline: np.ndarray, detune_cents: tuple[float, ...], phase_offset: float) -> np.ndarray:
    layer = np.zeros_like(timeline)
    for detune_index, cents in enumerate(detune_cents):
        ratio = 2.0 ** (cents / 1200.0)
        wave = 0.62 * sine_wave(note_hz * ratio, timeline, phase_offset + detune_index * 0.7)
        wave += 0.38 * triangle_wave(note_hz * ratio * 0.5, timeline, phase_offset * 0.5 + detune_index * 1.1)
        layer += wave
    layer /= max(len(detune_cents), 1)
    return layer


def add_pad_chord(
    stereo_buffer: np.ndarray,
    note_numbers: tuple[int, ...],
    start_seconds: float,
    duration_seconds: float,
    amplitude: float,
    pan_values: tuple[float, ...],
) -> None:
    start_index = int(start_seconds * SAMPLE_RATE)
    end_index = min(stereo_buffer.shape[0], start_index + int(duration_seconds * SAMPLE_RATE))
    if end_index <= start_index:
        return
    local_timeline = np.arange(end_index - start_index, dtype=np.float32) / SAMPLE_RATE
    local_time = np.linspace(0.0, 1.0, local_timeline.size, endpoint=False, dtype=np.float32)
    envelope = np.sin(np.pi * local_time) ** 0.85
    for note_index, note_number in enumerate(note_numbers):
        pad = additive_pad(
            midi_to_hz(note_number),
            local_timeline,
            (-7.0, 0.0, 6.0),
            phase_offset=0.8 * (note_index + 1),
        )
        pad *= envelope * amplitude * (0.88 + (0.04 * note_index))
        pad = one_pole_lowpass(pad, 1_900.0 + (note_index * 180.0))
        stereo_buffer[start_index:end_index] += pan_stereo(pad, pan_values[note_index % len(pan_values)])


def add_sub_drone(
    stereo_buffer: np.ndarray,
    note_number: int,
    amplitude: float,
    lowpass_hz: float,
    beat_length_seconds: float,
) -> None:
    timeline = np.arange(stereo_buffer.shape[0], dtype=np.float32) / SAMPLE_RATE
    tremolo = 0.82 + (0.18 * sine_wave(1.0 / (beat_length_seconds * 8.0), timeline, phase=0.35))
    signal = additive_pad(midi_to_hz(note_number), timeline, (-4.0, 0.0, 4.0), phase_offset=0.0)
    signal = one_pole_lowpass(signal * tremolo * amplitude, lowpass_hz)
    stereo_buffer += pan_stereo(signal, 0.0)


def add_filtered_air(stereo_buffer: np.ndarray, amplitude: float, cutoff_hz: float, seed: int, width: float) -> None:
    length = stereo_buffer.shape[0]
    base = smooth_noise(length, seed, 1_201)
    shimmer = highpass_from_lowpass(base, cutoff_hz * 0.18)
    bed = one_pole_lowpass(base, cutoff_hz)
    left = one_pole_lowpass(bed + (0.18 * shimmer), cutoff_hz * (0.92 + width * 0.08))
    right = one_pole_lowpass(np.roll(bed, 173) - (0.14 * shimmer), cutoff_hz * (1.08 - width * 0.08))
    stereo_buffer[:, 0] += left * amplitude
    stereo_buffer[:, 1] += right * amplitude


def add_pulse(
    stereo_buffer: np.ndarray,
    note_number: int,
    start_seconds: float,
    length_seconds: float,
    amplitude: float,
    pan: float,
    harmonic_blend: float,
) -> None:
    start_index = int(start_seconds * SAMPLE_RATE)
    end_index = min(stereo_buffer.shape[0], start_index + int(length_seconds * SAMPLE_RATE))
    if end_index <= start_index:
        return
    local_timeline = np.arange(end_index - start_index, dtype=np.float32) / SAMPLE_RATE
    envelope = np.exp(-3.6 * local_timeline)
    tone = 0.7 * sine_wave(midi_to_hz(note_number), local_timeline)
    tone += harmonic_blend * triangle_wave(midi_to_hz(note_number + 12), local_timeline)
    tone = one_pole_lowpass(tone, 2_400.0) * envelope * amplitude
    stereo_buffer[start_index:end_index] += pan_stereo(tone, pan)


def add_bell(
    stereo_buffer: np.ndarray,
    note_number: int,
    start_seconds: float,
    length_seconds: float,
    amplitude: float,
    pan: float,
) -> None:
    start_index = int(start_seconds * SAMPLE_RATE)
    end_index = min(stereo_buffer.shape[0], start_index + int(length_seconds * SAMPLE_RATE))
    if end_index <= start_index:
        return
    local_timeline = np.arange(end_index - start_index, dtype=np.float32) / SAMPLE_RATE
    envelope = np.exp(-2.8 * local_timeline)
    frequency = midi_to_hz(note_number)
    tone = 0.72 * sine_wave(frequency, local_timeline)
    tone += 0.23 * sine_wave(frequency * 2.01, local_timeline, phase=0.4)
    tone += 0.09 * sine_wave(frequency * 3.97, local_timeline, phase=0.85)
    tone = one_pole_lowpass(tone, 2_100.0) * envelope * amplitude
    stereo_buffer[start_index:end_index] += pan_stereo(tone, pan)


def add_kick_hit(
    stereo_buffer: np.ndarray,
    start_seconds: float,
    amplitude: float,
    pan: float = 0.0,
) -> None:
    length_seconds = 0.62
    start_index = int(start_seconds * SAMPLE_RATE)
    end_index = min(stereo_buffer.shape[0], start_index + int(length_seconds * SAMPLE_RATE))
    if end_index <= start_index:
        return
    local_timeline = np.arange(end_index - start_index, dtype=np.float32) / SAMPLE_RATE
    envelope = np.exp(-7.0 * local_timeline)
    sweep = 72.0 - (26.0 * np.minimum(local_timeline * 8.0, 1.0))
    tone = np.sin(2.0 * np.pi * np.cumsum(sweep) / SAMPLE_RATE)
    noise = one_pole_lowpass(smooth_noise(local_timeline.size, int(start_seconds * 1000.0) + 7, 97), 680.0)
    signal = (tone * 0.88 + noise * 0.12) * envelope * amplitude
    stereo_buffer[start_index:end_index] += pan_stereo(signal, pan)


def add_war_drum_hit(
    stereo_buffer: np.ndarray,
    start_seconds: float,
    note_number: int,
    amplitude: float,
    pan: float,
) -> None:
    length_seconds = 0.85
    start_index = int(start_seconds * SAMPLE_RATE)
    end_index = min(stereo_buffer.shape[0], start_index + int(length_seconds * SAMPLE_RATE))
    if end_index <= start_index:
        return
    local_timeline = np.arange(end_index - start_index, dtype=np.float32) / SAMPLE_RATE
    envelope = np.exp(-4.9 * local_timeline)
    fundamental = sine_wave(midi_to_hz(note_number), local_timeline)
    body = triangle_wave(midi_to_hz(note_number + 7) * 0.5, local_timeline, phase=0.2)
    noise = one_pole_lowpass(smooth_noise(local_timeline.size, int(start_seconds * 977.0) + note_number, 81), 1_100.0)
    signal = (fundamental * 0.66 + body * 0.24 + noise * 0.10) * envelope * amplitude
    stereo_buffer[start_index:end_index] += pan_stereo(signal, pan)


def add_staccato_ostinato(
    stereo_buffer: np.ndarray,
    note_numbers: tuple[int, ...],
    beat_times: np.ndarray,
    amplitude: float,
    pan: float,
) -> None:
    for index, start_seconds in enumerate(beat_times):
        note_number = note_numbers[index % len(note_numbers)]
        add_pulse(
            stereo_buffer,
            note_number,
            float(start_seconds),
            0.42,
            amplitude * (1.0 if index % 4 == 0 else 0.78),
            pan,
            harmonic_blend=0.22,
        )


def add_loop_wrap(signal: np.ndarray, overlap_seconds: float) -> np.ndarray:
    overlap_samples = int(overlap_seconds * SAMPLE_RATE)
    if overlap_samples <= 0 or overlap_samples >= signal.shape[0]:
        return signal
    wrapped = signal.copy()
    fade_out = np.linspace(1.0, 0.0, overlap_samples, endpoint=False, dtype=np.float32)
    fade_in = 1.0 - fade_out
    wrapped[:overlap_samples] = (wrapped[:overlap_samples] * fade_in[:, None]) + (wrapped[-overlap_samples:] * fade_out[:, None])
    wrapped[-overlap_samples:] = wrapped[:overlap_samples]
    return wrapped


def rotate_to_natural_loop_boundary(signal: np.ndarray) -> tuple[np.ndarray, int]:
    mono = np.mean(signal, axis=1)
    if mono.size < 4:
        return signal, 0

    previous = np.roll(mono, 1)
    slope = mono - previous
    previous_slope = np.roll(slope, 1)
    energy_window = max(64, int(SAMPLE_RATE * 0.04))
    energy_kernel = np.ones(energy_window, dtype=np.float32) / float(energy_window)
    local_energy = np.convolve(np.square(mono), energy_kernel, mode="same")
    cut_cost = (
        (np.abs(mono - previous) * 0.70)
        + (np.abs(slope - previous_slope) * 0.20)
        + (np.sqrt(local_energy) * 0.10)
    )
    best_cut_index = int(np.argmin(cut_cost[1:])) + 1
    return np.roll(signal, -best_cut_index, axis=0), best_cut_index


def gentle_master(signal: np.ndarray, peak_limit: float = 0.88) -> np.ndarray:
    centered = signal - np.mean(signal, axis=0, keepdims=True)
    saturated = np.tanh(centered * 1.35)
    peak = float(np.max(np.abs(saturated)))
    if peak <= 1e-6:
        return saturated.astype(np.float32)
    return (saturated * (peak_limit / peak)).astype(np.float32)


def spectral_centroid(stereo_signal: np.ndarray) -> float:
    mono = np.mean(stereo_signal, axis=1)
    fft = np.fft.rfft(mono)
    magnitudes = np.abs(fft)
    if not np.any(magnitudes):
        return 0.0
    freqs = np.fft.rfftfreq(mono.size, d=1.0 / SAMPLE_RATE)
    return float(np.sum(freqs * magnitudes) / np.sum(magnitudes))


def loop_boundary_jump(stereo_signal: np.ndarray) -> tuple[float, float]:
    mono = np.mean(stereo_signal, axis=1)
    if mono.size < 4:
        return 0.0, 0.0
    sample_jump = abs(float(mono[0] - mono[-1]))
    slope_jump = abs(float((mono[1] - mono[0]) - (mono[-1] - mono[-2])))
    return sample_jump, slope_jump


def build_ui_hub_track(duration_seconds: float) -> np.ndarray:
    total_samples = int(duration_seconds * SAMPLE_RATE)
    stereo_buffer = np.zeros((total_samples, 2), dtype=np.float32)
    add_filtered_air(stereo_buffer, amplitude=0.028, cutoff_hz=1_900.0, seed=101, width=0.68)
    add_sub_drone(stereo_buffer, note_number=38, amplitude=0.16, lowpass_hz=340.0, beat_length_seconds=0.92)

    chord_events = (
        (0.0, 7.0, (50, 57, 62, 65)),
        (7.0, 7.0, (46, 53, 57, 62)),
        (14.0, 7.0, (43, 50, 57, 60)),
        (21.0, 7.0, (45, 52, 57, 60)),
    )
    for start_seconds, chord_duration, notes in chord_events:
        add_pad_chord(stereo_buffer, notes, start_seconds, chord_duration, 0.14, (-0.42, -0.14, 0.14, 0.42))

    beat_times = np.arange(0.0, duration_seconds, 1.75, dtype=np.float32)
    roots = (38, 34, 31, 33)
    for pulse_index, start_seconds in enumerate(beat_times):
        root = roots[(pulse_index // 4) % len(roots)]
        add_pulse(
            stereo_buffer,
            note_number=root + (12 if pulse_index % 8 == 4 else 0),
            start_seconds=float(start_seconds),
            length_seconds=1.1,
            amplitude=0.062 if pulse_index % 4 == 0 else 0.045,
            pan=-0.18 if pulse_index % 2 == 0 else 0.18,
            harmonic_blend=0.16,
        )

    bell_events = (
        (3.5, 69, -0.24),
        (10.5, 72, 0.22),
        (17.5, 74, -0.18),
        (24.5, 72, 0.18),
    )
    for start_seconds, note_number, pan in bell_events:
        add_bell(stereo_buffer, note_number, start_seconds, 3.1, 0.05, pan)

    stereo_buffer = add_loop_wrap(stereo_buffer, overlap_seconds=2.6)
    stereo_buffer = one_pole_lowpass(stereo_buffer[:, 0], 3_300.0)[:, None] * np.array([[1.0, 0.0]], dtype=np.float32) + one_pole_lowpass(stereo_buffer[:, 1], 3_100.0)[:, None] * np.array([[0.0, 1.0]], dtype=np.float32)
    return gentle_master(stereo_buffer)


def build_run_end_track(duration_seconds: float) -> np.ndarray:
    total_samples = int(duration_seconds * SAMPLE_RATE)
    stereo_buffer = np.zeros((total_samples, 2), dtype=np.float32)
    add_filtered_air(stereo_buffer, amplitude=0.022, cutoff_hz=1_350.0, seed=303, width=0.34)
    add_sub_drone(stereo_buffer, note_number=38, amplitude=0.13, lowpass_hz=300.0, beat_length_seconds=1.25)

    chord_events = (
        (0.0, 10.0, (50, 57, 62)),
        (10.0, 10.0, (48, 55, 60)),
    )
    for start_seconds, chord_duration, notes in chord_events:
        add_pad_chord(stereo_buffer, notes, start_seconds, chord_duration, 0.12, (-0.30, 0.0, 0.30))

    bell_events = (
        (1.0, 74, -0.15),
        (5.0, 69, 0.20),
        (9.0, 72, -0.10),
        (12.5, 74, 0.14),
        (16.0, 69, -0.20),
    )
    for start_seconds, note_number, pan in bell_events:
        add_bell(stereo_buffer, note_number, start_seconds, 3.8, 0.06, pan)

    for pulse_index, start_seconds in enumerate(np.arange(0.0, duration_seconds, 4.0, dtype=np.float32)):
        add_pulse(
            stereo_buffer,
            note_number=38 if pulse_index % 2 == 0 else 36,
            start_seconds=float(start_seconds),
            length_seconds=1.8,
            amplitude=0.038,
            pan=0.0,
            harmonic_blend=0.10,
        )

    stereo_buffer = add_loop_wrap(stereo_buffer, overlap_seconds=2.2)
    left = one_pole_lowpass(stereo_buffer[:, 0], 2_300.0)
    right = one_pole_lowpass(stereo_buffer[:, 1], 2_180.0)
    return gentle_master(stereoize(left, right), peak_limit=0.84)


def build_combat_track(duration_seconds: float) -> np.ndarray:
    total_samples = int(duration_seconds * SAMPLE_RATE)
    stereo_buffer = np.zeros((total_samples, 2), dtype=np.float32)
    add_filtered_air(stereo_buffer, amplitude=0.016, cutoff_hz=1_450.0, seed=707, width=0.56)
    add_sub_drone(stereo_buffer, note_number=38, amplitude=0.17, lowpass_hz=420.0, beat_length_seconds=0.625)

    chord_events = (
        (0.0, 6.0, (50, 57, 62)),
        (6.0, 6.0, (46, 53, 58)),
        (12.0, 6.0, (43, 50, 55)),
        (18.0, 6.0, (45, 52, 57)),
    )
    for start_seconds, chord_duration, notes in chord_events:
        add_pad_chord(stereo_buffer, notes, start_seconds, chord_duration, 0.15, (-0.34, 0.0, 0.34))

    beat_length = 0.625
    beat_times = np.arange(0.0, duration_seconds, beat_length, dtype=np.float32)
    ostinato_cycle = (50, 57, 62, 57, 46, 53, 58, 53)
    add_staccato_ostinato(stereo_buffer, ostinato_cycle, beat_times, amplitude=0.065, pan=-0.08)
    add_staccato_ostinato(stereo_buffer, tuple(note - 12 for note in ostinato_cycle), beat_times + (beat_length * 0.5), amplitude=0.042, pan=0.12)

    for beat_index, start_seconds in enumerate(beat_times):
        if beat_index % 2 == 0:
            add_kick_hit(stereo_buffer, float(start_seconds), amplitude=0.18)
        if beat_index % 4 == 2:
            add_war_drum_hit(stereo_buffer, float(start_seconds + (beat_length * 0.15)), note_number=38, amplitude=0.13, pan=-0.24)
            add_war_drum_hit(stereo_buffer, float(start_seconds + (beat_length * 0.32)), note_number=41, amplitude=0.12, pan=0.24)

    accent_times = (2.5, 8.5, 14.5, 20.5)
    accent_notes = (69, 70, 67, 69)
    for start_seconds, note_number in zip(accent_times, accent_notes):
        add_bell(stereo_buffer, note_number, start_seconds, 1.9, 0.032, 0.0)

    stereo_buffer = add_loop_wrap(stereo_buffer, overlap_seconds=2.0)
    left = one_pole_lowpass(stereo_buffer[:, 0], 2_900.0)
    right = one_pole_lowpass(stereo_buffer[:, 1], 2_780.0)
    return gentle_master(stereoize(left, right), peak_limit=0.9)


def write_track(output_signal: np.ndarray, master_path: Path, runtime_path: Path) -> None:
    master_path.parent.mkdir(parents=True, exist_ok=True)
    runtime_path.parent.mkdir(parents=True, exist_ok=True)
    temp_wav_path = master_path.with_suffix(".tmp.wav")
    sf.write(temp_wav_path, output_signal, SAMPLE_RATE, format="WAV", subtype="PCM_16")
    ffmpeg_binary = imageio_ffmpeg.get_ffmpeg_exe()
    command = [
        ffmpeg_binary,
        "-y",
        "-loglevel",
        "error",
        "-i",
        str(temp_wav_path),
        "-c:a",
        "libvorbis",
        "-q:a",
        "5",
        str(master_path),
    ]
    subprocess.run(command, check=True)
    temp_wav_path.unlink(missing_ok=True)
    shutil.copyfile(master_path, runtime_path)


def main() -> None:
    for track in TRACKS:
        builder = globals()[track["builder"]]
        signal = builder(track["duration_seconds"])
        signal, loop_cut_index = rotate_to_natural_loop_boundary(signal)
        master_path = SOURCE_DIR / track["master_name"]
        runtime_path = RUNTIME_DIR / f"{track['asset_name']}.ogg"
        write_track(signal, master_path, runtime_path)
        sample_jump, slope_jump = loop_boundary_jump(signal)
        print(
            f"{track['asset_name']}: duration={track['duration_seconds']:.1f}s "
            f"centroid={spectral_centroid(signal):.1f}Hz "
            f"loop_cut={loop_cut_index} sample_jump={sample_jump:.6f} "
            f"slope_jump={slope_jump:.6f} master={master_path.name}"
        )


if __name__ == "__main__":
    main()
