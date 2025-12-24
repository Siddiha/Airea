# ml-training/fall-detection/1_extract_kfall.py

import os
import zipfile
from tqdm import tqdm

def extract_kfall():
    """Extract manually downloaded KFall dataset"""
    
    print("="*70)
    print("📦 KFall Dataset Extraction")
    print("="*70)
    print()
    
    # Check for downloaded file
    zip_path = 'downloads/archive.zip'
    
    if not os.path.exists(zip_path):
        print("❌ archive.zip not found!")
        print()
        print(f"Expected location: {os.path.abspath(zip_path)}")
        print()
        print("📥 Download instructions:")
        print("   1. Go to: https://www.kaggle.com/datasets/pitasr/kfall")
        print("   2. Click 'Download' button (top right)")
        print("   3. Save as: downloads/archive.zip")
        print()
        return False
    
    # Check file size
    file_size = os.path.getsize(zip_path) / (1024 * 1024)
    print(f"✅ Found: {os.path.basename(zip_path)}")
    print(f"📊 Size: {file_size:.2f} MB")
    
    if file_size < 50:
        print(f"\n⚠️  Warning: File seems small ({file_size:.2f} MB)")
        print("   Expected: ~200 MB")
        response = input("\nContinue anyway? (y/n): ")
        if response.lower() != 'y':
            return False
    
    # Extract
    print(f"\n📦 Extracting...")
    extract_path = '../data/raw/fall/kfall'
    os.makedirs(extract_path, exist_ok=True)
    
    try:
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            files = zip_ref.namelist()
            print(f"📊 Files to extract: {len(files)}")
            print()
            
            for file in tqdm(files, desc="Extracting", unit="file"):
                zip_ref.extract(file, extract_path)
        
        print("\n✅ Extraction complete!")
        
        # Verify structure
        csv_files = []
        for root, dirs, files in os.walk(extract_path):
            csv_files.extend([f for f in files if f.endswith('.csv')])
        
        print(f"\n📊 Dataset Statistics:")
        print(f"   CSV files found: {len(csv_files)}")
        print(f"   Location: {os.path.abspath(extract_path)}")
        
        if len(csv_files) > 0:
            print("\n🎯 Next step: python 2_extract_features.py")
            return True
        else:
            print("\n⚠️  No CSV files found")
            print("   Check the extracted folder structure")
            return False
            
    except zipfile.BadZipFile:
        print("\n❌ Error: Invalid ZIP file")
        print("   Please re-download from Kaggle")
        return False
    except Exception as e:
        print(f"\n❌ Error: {e}")
        return False

if __name__ == "__main__":
    os.makedirs('downloads', exist_ok=True)
    extract_kfall()