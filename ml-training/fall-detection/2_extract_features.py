# ml-training/fall-detection/2_extract_features.py

import os
import numpy as np
import pandas as pd
from tqdm import tqdm
from utils.motion_features import extract_kfall_features

def load_kfall_labels(kfall_base_dir):
    """Load labels from Excel files"""
    
    label_dir = os.path.join(kfall_base_dir, 'label_data')
    
    if not os.path.exists(label_dir):
        print(f"❌ label_data not found at: {os.path.abspath(label_dir)}")
        return None
    
    label_files = [f for f in os.listdir(label_dir) if f.endswith(('.xlsx', '.xls'))]
    
    print(f"📋 Found {len(label_files)} Excel label files")
    
    if len(label_files) == 0:
        return None
    
    all_labels = []
    for label_file in tqdm(label_files, desc="Loading labels"):
        try:
            df = pd.read_excel(os.path.join(label_dir, label_file))
            all_labels.append(df)
        except Exception as e:
            print(f"⚠️  Error reading {label_file}: {e}")
    
    if len(all_labels) == 0:
        return None
    
    labels_df = pd.concat(all_labels, ignore_index=True)
    
    print(f"✅ Loaded {len(labels_df)} labeled recordings")
    print(f"📊 Columns: {labels_df.columns.tolist()}")
    print()
    print("📋 Sample labels:")
    print(labels_df.head(10))
    print()
    
    return labels_df

def build_label_mapping(labels_df):
    """Build filename -> label mapping from KFall label structure"""
    
    print("🗺️  Building label mapping from Task Code + Trial ID...")
    
    label_map = {}
    
    # Track current task code
    current_task = None
    
    for idx, row in labels_df.iterrows():
        try:
            # Get task code (handle NaN by using previous task)
            task_code = row.get('Task Code (Task ID)', None)
            if pd.notna(task_code):
                current_task = str(task_code).strip()
            
            # Get trial ID
            trial_id = row.get('Trial ID', None)
            
            if current_task is None or pd.isna(trial_id):
                continue
            
            # Extract just the task code (e.g., "F01" from "F01 (20)")
            task_parts = current_task.split('(')[0].strip()
            
            # Determine if fall or ADL
            # F codes = Falls, A codes = ADLs
            is_fall = task_parts.startswith('F')
            
            # Build possible filename patterns
            # KFall uses formats like: SA01_F01_T01.csv or F01_T01.csv
            trial_str = f"T{int(trial_id):02d}"
            
            possible_names = [
                f"{task_parts}_{trial_str}",           # F01_T01
                f"{task_parts}_T{int(trial_id)}",      # F01_T1
                f"SA01_{task_parts}_{trial_str}",      # SA01_F01_T01
                f"SA{int(trial_id):02d}_{task_parts}", # SA01_F01
            ]
            
            for name in possible_names:
                label_map[name] = 1 if is_fall else 0
                
        except Exception as e:
            continue
    
    print(f"✅ Created {len(label_map)} label mappings")
    
    # Count falls vs ADLs
    falls = sum(1 for v in label_map.values() if v == 1)
    adls = sum(1 for v in label_map.values() if v == 0)
    
    print(f"📊 Label distribution:")
    print(f"   Falls: {falls} ({100*falls/len(label_map):.1f}%)")
    print(f"   ADLs:  {adls} ({100*adls/len(label_map):.1f}%)")
    print()
    
    # Show sample mappings
    print("📋 Sample filename mappings:")
    for i, (key, val) in enumerate(list(label_map.items())[:10]):
        label_str = "FALL" if val == 1 else "ADL"
        print(f"   {key} → {label_str}")
    print()
    
    return label_map

def process_kfall_dataset():
    """Process KFall dataset"""
    
    print("="*70)
    print("🔧 KFall Feature Extraction")
    print("="*70)
    print()
    
    kfall_base_dir = '../data/raw/fall/kfall/kFall Dataset'
    
    if not os.path.exists(kfall_base_dir):
        print(f"❌ Dataset not found at: {os.path.abspath(kfall_base_dir)}")
        return
    
    print(f"✅ Dataset found")
    print()
    
    # Load labels
    labels_df = load_kfall_labels(kfall_base_dir)
    
    if labels_df is None:
        print("❌ Failed to load labels!")
        return
    
    # Build label mapping
    label_map = build_label_mapping(labels_df)
    
    if len(label_map) == 0:
        print("❌ No labels created!")
        return
    
    # Find sensor files
    sensor_dir = os.path.join(kfall_base_dir, 'sensor_data')
    
    if not os.path.exists(sensor_dir):
        print(f"❌ sensor_data not found")
        return
    
    all_files = []
    for root, dirs, files in os.walk(sensor_dir):
        for file in files:
            if file.endswith('.csv'):
                all_files.append(os.path.join(root, file))
    
    print(f"📂 Found {len(all_files)} sensor CSV files")
    
    # Show sample filenames
    print("\n📋 Sample sensor filenames:")
    for filepath in all_files[:10]:
        print(f"   {os.path.basename(filepath)}")
    print()
    
    # Process files
    fall_features = []
    adl_features = []
    matched = 0
    unmatched = 0
    
    print("🔄 Processing sensor files...")
    
    for filepath in tqdm(all_files, desc="Extracting features"):
        try:
            filename = os.path.basename(filepath)
            filename_no_ext = os.path.splitext(filename)[0]
            
            # Try to match with label map
            label = None
            
            # Try exact match
            if filename_no_ext in label_map:
                label = label_map[filename_no_ext]
                matched += 1
            else:
                # Try fuzzy matching
                for key in label_map.keys():
                    if key in filename_no_ext or filename_no_ext in key:
                        label = label_map[key]
                        matched += 1
                        break
            
            if label is None:
                unmatched += 1
                continue
            
            # Read CSV
            data = pd.read_csv(filepath)
            
            # Find accel and gyro columns
            accel_cols = []
            gyro_cols = []
            
            for col in data.columns:
                col_lower = str(col).lower()
                if any(p in col_lower for p in ['acc', 'accel']):
                    accel_cols.append(col)
                elif any(p in col_lower for p in ['gyro', 'gyr']):
                    gyro_cols.append(col)
            
            # Fallback: first 6 columns
            if len(accel_cols) == 0 and len(data.columns) >= 6:
                accel_cols = data.columns[:3].tolist()
                gyro_cols = data.columns[3:6].tolist()
            
            if len(accel_cols) >= 3 and len(gyro_cols) >= 3:
                accel = data[accel_cols[:3]].values.astype(float)
                gyro = data[gyro_cols[:3]].values.astype(float)
                
                features = extract_kfall_features(accel, gyro, label)
                
                if features is not None:
                    if label == 1:
                        fall_features.append(features)
                    else:
                        adl_features.append(features)
        
        except Exception as e:
            continue
    
    print()
    print("="*70)
    print("📊 PROCESSING SUMMARY")
    print("="*70)
    print(f"✅ Matched: {matched}")
    print(f"❌ Unmatched: {unmatched}")
    print()
    print(f"✅ Falls extracted: {len(fall_features)}")
    print(f"✅ ADLs extracted: {len(adl_features)}")
    print()
    
    if len(fall_features) == 0 or len(adl_features) == 0:
        print("❌ Not enough data!")
        
        if matched == 0:
            print("\n💡 DEBUG: No files matched!")
            print("   Checking one sensor file...")
            
            if len(all_files) > 0:
                sample_file = os.path.basename(all_files[0])
                print(f"   Sample sensor file: {sample_file}")
                print(f"   Sample label keys: {list(label_map.keys())[:5]}")
        
        return
    
    # Save
    os.makedirs('../data/processed', exist_ok=True)
    
    fall_features = np.array(fall_features)
    adl_features = np.array(adl_features)
    
    np.save('../data/processed/fall_features.npy', fall_features[:, :-1])
    np.save('../data/processed/fall_labels.npy', fall_features[:, -1])
    np.save('../data/processed/adl_features.npy', adl_features[:, :-1])
    np.save('../data/processed/adl_labels.npy', adl_features[:, -1])
    
    print("="*70)
    print("✅ FEATURE EXTRACTION COMPLETE!")
    print("="*70)
    print()
    print(f"💾 Fall features: {fall_features.shape}")
    print(f"💾 ADL features: {adl_features.shape}")
    print()
    print("🎯 Next: python 3_create_balanced_dataset.py")

if __name__ == "__main__":
    process_kfall_dataset()