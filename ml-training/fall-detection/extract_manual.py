# ml-training/fall-detection/extract_manual.py

import os
import zipfile
from tqdm import tqdm

def extract_sisfall():
    """
    Extract manually downloaded SisFall.zip
    """
    print("="*70)
    print("📦 Manual SisFall Dataset Extraction")
    print("="*70)
    print()
    
    zip_path = 'downloads/sisfall.zip'
    extract_path = '../data/raw/fall/'
    
    # Check if file exists
    if not os.path.exists(zip_path):
        print(f"❌ File not found!")
        print()
        print(f"Expected location: {os.path.abspath(zip_path)}")
        print()
        print("Please download SisFall.zip and place it in:")
        print(f"   {os.path.abspath('downloads/')}")
        print()
        print("Download from:")
        print("   🔗 https://zenodo.org/record/2530848")
        print("   🔗 https://ieee-dataport.org/open-access/sisfall-fall-and-movement-dataset")
        return
    
    # Check file size
    file_size = os.path.getsize(zip_path) / (1024 * 1024)
    print(f"✅ Found: {os.path.basename(zip_path)}")
    print(f"📊 File size: {file_size:.2f} MB")
    
    if file_size < 100:
        print(f"\n⚠️  Warning: File seems too small!")
        print(f"   Current: {file_size:.2f} MB")
        print(f"   Expected: ~1,200 MB")
        print()
        response = input("Continue anyway? (y/n): ")
        if response.lower() != 'y':
            print("Cancelled.")
            return
    
    print(f"\n📁 Extracting to: {os.path.abspath(extract_path)}")
    print()
    
    os.makedirs(extract_path, exist_ok=True)
    
    try:
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            file_list = zip_ref.namelist()
            print(f"📊 Files to extract: {len(file_list)}")
            print()
            
            # Extract with progress
            for file in tqdm(file_list, desc="Extracting", unit="file"):
                zip_ref.extract(file, extract_path)
        
        print("\n✅ Extraction complete!")
        
        # Find SisFall directory
        sisfall_dir = None
        search_paths = [
            '../data/raw/fall/SisFall',
            '../data/raw/fall/SisFall_dataset',
            '../data/raw/fall/'
        ]
        
        for path in search_paths:
            if os.path.exists(path):
                contents = os.listdir(path)
                if any(d.startswith('SA') or d.startswith('SE') for d in contents):
                    sisfall_dir = path
                    break
                # Check one level deeper
                for item in contents:
                    subpath = os.path.join(path, item)
                    if os.path.isdir(subpath):
                        subcontents = os.listdir(subpath)
                        if any(d.startswith('SA') or d.startswith('SE') for d in subcontents):
                            sisfall_dir = subpath
                            break
                if sisfall_dir:
                    break
        
        if sisfall_dir:
            # Count subjects and files
            subjects = sorted([
                d for d in os.listdir(sisfall_dir) 
                if os.path.isdir(os.path.join(sisfall_dir, d)) 
                and (d.startswith('SA') or d.startswith('SE'))
            ])
            
            total_files = 0
            fall_files = 0
            adl_files = 0
            
            for root, dirs, files in os.walk(sisfall_dir):
                for f in files:
                    if f.endswith('.txt'):
                        total_files += 1
                        if any(f'D{i:02d}' in f for i in range(1, 20)):
                            fall_files += 1
                        elif any(f'F{i:02d}' in f for i in range(1, 16)):
                            adl_files += 1
            
            print("\n" + "="*70)
            print("✅ DATASET READY!")
            print("="*70)
            print(f"\n📊 Dataset Statistics:")
            print(f"   Location: {os.path.abspath(sisfall_dir)}")
            print(f"   Subjects: {len(subjects)}")
            print(f"   Total recordings: {total_files}")
            print(f"   - Fall recordings: {fall_files}")
            print(f"   - ADL recordings: {adl_files}")
            print()
            
            print("👥 Subjects found:")
            for i, subject in enumerate(subjects):
                if i < 10 or i >= len(subjects) - 5:
                    print(f"   - {subject}")
                elif i == 10:
                    print(f"   ... ({len(subjects) - 15} more) ...")
            
            print()
            print("🎯 Next steps:")
            print("   1. python 2_extract_features.py")
            print("   2. python 3_create_balanced_dataset.py")
            print("   3. python 4_train_fall_model.py")
            
        else:
            print("\n⚠️  Could not locate SisFall subject folders")
            print(f"\nExtracted to: {os.path.abspath(extract_path)}")
            print("\nPlease verify the folder structure manually.")
            
    except zipfile.BadZipFile:
        print("\n❌ Error: Not a valid ZIP file")
        print("   Download might be corrupted. Please re-download.")
    except Exception as e:
        print(f"\n❌ Extraction failed: {e}")

if __name__ == "__main__":
    extract_sisfall()