#!/usr/bin/env python3
import json

# 残りの修正マッピング
remaining_fixes = {
    "junior_high_2.json": {
        "real": "ほんとうの(現実)",
        "mail": "郵便(手紙)",
        "ago": "前(時間)",
    },
    "junior_high_3.json": {
        "strike": "打つ(強打)",
        "most": "ほとんど(最も)",
        "bike": "自転車(bike)",
        "true": "ほんとうの(真実)",
        "post": "郵便(投函)",
        "front": "前(方向)",
    },
    "junior_high_1.json": {
        "bicycle": "自転車(bicycle)",
        "hat": "帽子(ハット)",
    }
}

for filename, word_map in remaining_fixes.items():
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        modified = False
        for card in data['cards']:
            if card['english'] in word_map:
                old_jp = card['japanese']
                card['japanese'] = word_map[card['english']]
                print(f"{filename}: {card['english']} | {old_jp} -> {card['japanese']}")
                modified = True
        
        if modified:
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"✅ {filename} 修正完了\n")
        else:
            print(f"⚠️  {filename} 変更なし\n")
    except Exception as e:
        print(f"❌ {filename} エラー: {e}\n")

print("修正完了")
