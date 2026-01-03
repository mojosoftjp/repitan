#!/usr/bin/env python3
import json

files_and_versions = {
    "junior_high_1.json": "1.3.0",  # 1.2.0 -> 1.3.0
    "junior_high_2.json": "1.4.0",  # 1.3.0 -> 1.4.0
    "junior_high_3.json": "1.7.0",  # 1.6.0 -> 1.7.0
}

for filename, new_version in files_and_versions.items():
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        old_version = data.get('version', 'unknown')
        data['version'] = new_version
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        print(f"✅ {filename}: {old_version} -> {new_version}")
    except Exception as e:
        print(f"❌ {filename}: エラー - {e}")

print("\nバージョン更新完了")
