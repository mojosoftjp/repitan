#!/usr/bin/env python3
import json
import sys

# 修正マッピング
fixes = {
    "junior_high_2.json": {
        "test": "テスト",
        "dish": "皿(料理)",
        "hit": "打つ(当てる)",
        "idea": "考え(アイデア)",
        "bike": "自転車(bike)",
        "cap": "帽子(キャップ)",
        "bright": "明るい(輝き)",
        "real": "ほんとうの(現実)",
        "mail": "郵便(手紙)",
        "healthy": "健康な(体調)",
        "wake": "目が覚める(起こす)",
        "space": "宇宙(空間)",
        "almost": "ほとんど(大部分)",
        "god": "神(一般)",
        "ago": "前(時間)",
    },
    "junior_high_3.json": {
        "exam": "試験(重要)",
        "plate": "皿(食器)",
        "strike": "打つ(強打)",
        "exercise": "練習する(運動)",
        "thought": "考え(思考)",
        "light": "明るい(光)",
        "true": "ほんとうの(真実)",
        "silent": "静かな(無音)",
        "post": "郵便(投函)",
        "well": "健康な(良好)",
        "awake": "目が覚める(起きている)",
        "universe": "宇宙(全体)",
        "sort": "種類(分類)",
        "God": "神(God)",
        "most": "ほとんど(最も)",
        "front": "前(方向)",
    },
    "junior_high_1.json": {
        "practice": "練習する(反復)",
        "bicycle": "自転車(bicycle)",
        "hat": "帽子(ハット)",
        "quiet": "静かな(穏やか)",
        "kind": "種類(タイプ)",  # kindには「親切な」もあるので注意
    }
}

for filename, word_map in fixes.items():
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        modified = False
        for card in data['cards']:
            if card['english'] in word_map:
                card['japanese'] = word_map[card['english']]
                modified = True
        
        if modified:
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"✅ {filename} 修正完了")
        else:
            print(f"⚠️  {filename} 変更なし")
    except Exception as e:
        print(f"❌ {filename} エラー: {e}")

print("\n修正完了")
