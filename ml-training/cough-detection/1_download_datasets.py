# ml-training/cough-detection/1_download_datasets.py

import os
import urllib.request
import zipfile
from tqdm import tqdm

class DownloadProgressBar(tqdm):
    def update_to(self, b=1, bsize=1, tsize=None):
        if tsize is not None:
            self.total = tsize
        self.update(b * bsize - self.n)

def download_url(url, output_path):
    """Download file with progress bar"""
    with DownloadProgressBar(unit='B', unit_scale=True, miniters=1, desc=url.split('/')[-1]) as t:
        urllib.request.urlretrieve(url, filename=output_path, reporthook=t.update_to)

def main():
    print("🔽 Downloading Cough Detection Datasets...\n")
    
    # Create download directory
    os.makedirs('downloads', exist_ok=True)
    
    # ===== COUGHVID Dataset =====
    print("1️⃣ Downloading COUGHVID dataset...")
    coughvid_url = "https://zenodo.org/record/4498364/files/public_dataset.zip"
    download_url(coughvid_url, 'downloads/coughvid.zip')
    
    print("   Extracting COUGHVID...")
    with zipfile.ZipFile('downloads/coughvid.zip', 'r') as zip_ref:
        zip_ref.extractall('../data/raw/cough/')
    print("   ✅ COUGHVID extracted to data/raw/cough/\n")
    
    # ===== ESC-50 Dataset (Background Noise) =====
    print("2️⃣ Downloading ESC-50 dataset...")
    esc50_url = "https://github.com/karolpiczak/ESC-50/archive/master.zip"
    download_url(esc50_url, 'downloads/esc50.zip')
    
    print("   Extracting ESC-50...")
    with zipfile.ZipFile('downloads/esc50.zip', 'r') as zip_ref:
        zip_ref.extractall('downloads/esc50_temp')
    
    # Move only audio files to noise folder
    import shutil
    audio_folder = 'downloads/esc50_temp/ESC-50-master/audio'
    if os.path.exists(audio_folder):
        for file in os.listdir(audio_folder):
            if file.endswith('.wav'):
                shutil.copy(
                    os.path.join(audio_folder, file),
                    '../data/raw/noise/'
                )
    print("   ✅ ESC-50 extracted to data/raw/noise/\n")
    
    print("=" * 60)
    print("✅ All datasets downloaded successfully!")
    print("=" * 60)
    print(f"📁 Cough samples: {len(os.listdir('../data/raw/cough/'))} files")
    print(f"📁 Noise samples: {len(os.listdir('../data/raw/noise/'))} files")

if __name__ == "__main__":
    main()

