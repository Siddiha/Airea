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
    with DownloadProgressBar(unit='B', unit_scale=True, 
                            miniters=1, desc=url.split('/')[-1]) as t:
        urllib.request.urlretrieve(url, filename=output_path, 
                                  reporthook=t.update_to)

def main():
    print("🔽 Downloading SisFall Dataset...\n")
    
    # Create directories (relative to ml-training/fall-detection/)
    os.makedirs('../data/raw/fall', exist_ok=True)
    os.makedirs('downloads', exist_ok=True)
    
    # SisFall official download link
    sisfall_url = "http://sistemic.udea.edu.co/~gmn/data/SisFall.zip"
    
    print("📥 Downloading SisFall (this may take 5-10 minutes)...")
    try:
        download_url(sisfall_url, 'downloads/sisfall.zip')
    except Exception as e:
        print(f"❌ Download failed: {e}")
        print("\n🔗 Manual download option:")
        print("   1. Visit: http://sistemic.udea.edu.co/en/research/projects/english-falls/")
        print("   2. Download SisFall.zip")
        print("   3. Place it in ml-training/fall-detection/downloads/")
        return
    
    print("\n📦 Extracting SisFall...")
    with zipfile.ZipFile('downloads/sisfall.zip', 'r') as zip_ref:
        zip_ref.extractall('../data/raw/fall/')
    
    print("\n✅ SisFall dataset ready!")
    
    # Verify structure
    sisfall_dir = '../data/raw/fall/SisFall'
    if os.path.exists(sisfall_dir):
        # Count subjects and files
        subjects = [d for d in os.listdir(sisfall_dir) 
                   if os.path.isdir(os.path.join(sisfall_dir, d))]
        
        total_files = 0
        for root, dirs, files in os.walk(sisfall_dir):
            total_files += len([f for f in files if f.endswith('.txt')])
        
        print(f"\n📊 Dataset Statistics:")
        print(f"   Subjects: {len(subjects)}")
        print(f"   Total recordings: {total_files}")
        print(f"   Location: {os.path.abspath(sisfall_dir)}")

if __name__ == "__main__":
    main()