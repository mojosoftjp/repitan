#!/usr/bin/env python3
import json

# junior_high_2.jsonのwell（形容詞）とhealthyを修正
with open('junior_high_2.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

modified = False
for card in data['cards']:
    if card['english'] == 'well' and card.get('partOfSpeech') == '形容詞':
        old_jp = card['japanese']
        card['japanese'] = '健康な(良好)'
        print(f"well (形容詞): {old_jp} -> {card['japanese']}")
        modified = True
    elif card['english'] == 'healthy':
        old_jp = card['japanese']
        card['japanese'] = '健康な(体調)'
        print(f"healthy: {old_jp} -> {card['japanese']}")
        modified = True

if modified:
    with open('junior_high_2.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print("✅ 修正完了")
else:
    print("⚠️ 変更なし")
