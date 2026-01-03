#!/usr/bin/env python3
import json

# 正確なファイル位置での修正マッピング
correct_fixes = {
    "junior_high_2.json": {
        "strike": "打つ(強打)",
        "most": "ほとんど(最も)",
        "post": "郵便(投函)",
        "front": "前(方向)",
        "bicycle": "自転車(bicycle)",
        "hat": "帽子(ハット)",
    },
    "junior_high_1.json": {
        "bike": "自転車(bike)",
        "true": "ほんとうの(真実)",
        "most": "ほとんど(最も)",  # junior_high_1にもmostがある
    }
}

for filename, word_map in correct_fixes.items():
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

print("すべて修正完了")
