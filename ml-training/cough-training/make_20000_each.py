import os
import argparse
import random
import librosa
import numpy as np
import soundfile as sf

# --- CONFIGURATION ---
NOISE_DIR = './dataset/negative_class'
COUGH_DIR = './dataset/cough_dataset'
TARGET_NOISE_TOTAL = 20000
TARGET_COUGH_TOTAL = 20000
RANDOM_SEED = 42


def _ensure_mono(audio):
    if audio.ndim == 1:
        return audio
    return np.mean(audio, axis=1)


def _normalize(audio):
    peak = np.max(np.abs(audio)) + 1e-9
    audio = audio / peak
    return np.clip(audio, -1.0, 1.0)


def _augment_audio(y, sr):
    aug_type = random.choice(["stretch", "pitch", "gain", "shift", "noise", "combo"])

    if aug_type == "stretch":
        rate = random.uniform(0.88, 1.12)
        y_aug = librosa.effects.time_stretch(y, rate=rate)
    elif aug_type == "pitch":
        steps = random.uniform(-1.5, 1.5)
        y_aug = librosa.effects.pitch_shift(y, sr=sr, n_steps=steps)
    elif aug_type == "gain":
        gain = random.uniform(0.65, 1.35)
        y_aug = y * gain
    elif aug_type == "shift":
        max_shift = int(0.15 * len(y))
        shift = random.randint(-max_shift, max_shift)
        y_aug = np.roll(y, shift)
    elif aug_type == "noise":
        noise_level = random.uniform(0.003, 0.02)
        y_aug = y + np.random.normal(0.0, noise_level, len(y))
    else:
        gain = random.uniform(0.75, 1.25)
        steps = random.uniform(-1.0, 1.0)
        y_aug = librosa.effects.pitch_shift(y * gain, sr=sr, n_steps=steps)
        y_aug = y_aug + np.random.normal(0.0, random.uniform(0.002, 0.01), len(y_aug))

    return _normalize(y_aug)


def _load_audio(file_path):
    y, sr = librosa.load(file_path, sr=None, mono=False)
    y = _ensure_mono(y)
    y = _normalize(y)
    return y, sr


def _top_up_class_samples(class_dir, target_total, output_prefix):
    existing_files = [f for f in os.listdir(class_dir) if f.lower().endswith((".wav", ".mp3"))]
    current_count = len(existing_files)
    needed = target_total - current_count

    print(f"\n📁 Class: {class_dir}")
    print(f"📊 Current count: {current_count}")
    print(f"🎯 Target count:  {target_total}")
    print(f"➕ Need:          {max(needed, 0)}")

    if needed <= 0:
        print("✅ Target already met.")
        return

    if current_count == 0:
        print("❌ No source files found to augment.")
        return

    generated = 0
    cycle_index = 0

    while generated < needed:
        src_name = existing_files[cycle_index % current_count]
        src_path = os.path.join(class_dir, src_name)

        try:
            y, sr = _load_audio(src_path)
            y_aug = _augment_audio(y, sr)

            out_name = f"{output_prefix}_{generated:05d}.wav"
            out_path = os.path.join(class_dir, out_name)
            sf.write(out_path, y_aug, sr)

            generated += 1
            cycle_index += 1

            if generated % 500 == 0:
                print(f"✅ Generated {generated}/{needed} ...")
        except Exception:
            cycle_index += 1
            continue

    print(f"🚀 Finished {class_dir}: generated {generated} files.")


def finalize_dataset_balance(target_noise_total=TARGET_NOISE_TOTAL, target_cough_total=TARGET_COUGH_TOTAL):
    random.seed(RANDOM_SEED)
    np.random.seed(RANDOM_SEED)

    _top_up_class_samples(NOISE_DIR, target_noise_total, "aug_noise")
    _top_up_class_samples(COUGH_DIR, target_cough_total, "aug_cough")

    print("\n✅ Dataset expansion complete.")
    print(f"   Negative target: {target_noise_total}")
    print(f"   Cough target:    {target_cough_total}")


def _resolve_targets_from_args():
    parser = argparse.ArgumentParser(
        description="Expand cough/noise dataset to target totals per class."
    )
    parser.add_argument(
        "--noise-target",
        type=int,
        default=int(os.getenv("TARGET_NOISE_TOTAL", TARGET_NOISE_TOTAL)),
        help="Target total files for negative_class.",
    )
    parser.add_argument(
        "--cough-target",
        type=int,
        default=int(os.getenv("TARGET_COUGH_TOTAL", TARGET_COUGH_TOTAL)),
        help="Target total files for cough_dataset.",
    )

    args = parser.parse_args()
    return args.noise_target, args.cough_target


if __name__ == "__main__":
    noise_target, cough_target = _resolve_targets_from_args()
    finalize_dataset_balance(noise_target, cough_target)