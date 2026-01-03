# リピたん 開発引き継ぎドキュメント

最終更新: 2026-01-03（セッション9）

## プロジェクト概要

**リピたん** - 中高生向け英単語暗記iOSアプリ
- SM-2アルゴリズムによる間隔反復学習
- SwiftUI + SwiftData

---

## 本日（2026-01-03 セッション9）の作業内容

### 完了した作業

#### 1. 復習タイミングの最適化
**ファイル:** `Repitan/Views/Study/TestView.swift`

**問題点:**
- 間違えた単語の`learningDueDate`が「間違えた瞬間」から3分後に設定されていた
- 学習セッション中に複数の単語を間違えると、それぞれ異なる時刻に復習可能になる

**修正内容:**
- `scheduleSessionNotifications()`関数を修正（413-465行目）
- セッション完了時点から全ての学習中カードの`learningDueDate`を再計算
- 学習セッション中に間違えた単語すべてが、セッション終了後にまとめて復習タイマーがスタート

**効果:**
- 例: セッション中に10:00, 10:02, 10:04に間違えた → セッション終了が10:05 → すべて10:08に復習可能

#### 2. 復習候補が0の時の制御強化
**ファイル:** `Repitan/Views/Home/HomeView.swift`, `Repitan/Views/Study/StudySessionView.swift`

**問題点:**
- 待機中カード（`pendingLearningCards`）のみで復習可能カードがない場合でも「復習を始める」が表示される

**修正内容:**
- HomeView.swift: `reviewReadyCount`プロパティを追加（82-85行目）
- ボタン表示条件を`reviewReadyCount > 0`に変更
- `prepareReviewCards()`から待機中カード部分を削除
- StudySessionView.swift: 復習モードの`canStartStudy`を修正

**効果:**
- 復習可能なカード（`learningCards` + `reviewDueCards`）がある場合のみボタン表示
- 空の復習セッションを防止

#### 3. 学習モード選択画面の自動更新
**ファイル:** `Repitan/Views/Study/StudySessionView.swift`

**問題点:**
- 画面を開いたまま3分経過しても、待機中カウントが更新されない
- アプリをバックグラウンドから復帰させても、古いカウントが表示される

**修正内容:**
- `@State private var currentTime = Date()`を追加（15行目）
- 全てのカード計算で`Date()`ではなく`currentTime`を使用
- `onAppear`, `onReceive(willEnterForeground)`, `onReceive(Timer)`で自動更新

**効果:**
- 10秒ごとに自動更新
- アプリ復帰時に即座に更新
- 待機中カウントがリアルタイムに近い形で更新

#### 4. 重複する日本語訳の完全修正
**ファイル:** `junior_high_1.json`, `junior_high_2.json`, `junior_high_3.json`

**問題点:**
- 同じ日本語訳を持つ異なる英単語が27組以上存在
- 学習時に混乱を招く

**修正内容:**
- 82単語に区別用の補足を追加
- 主な修正例:
  - movie / film → 映画(娯楽) / 映画(作品)
  - fast / quick → 速い(スピード) / 速い(素早い)
  - speak / talk → 話す(演説) / 話す(会話)
  - big / loud → 大きい(サイズ) / 大きい(音量)
  - exam / test → 試験(重要) / テスト
  - その他多数（全82単語）

**バージョン更新:**
- junior_high_1.json: 1.2.0 → 1.3.0
- junior_high_2.json: 1.3.0 → 1.4.0
- junior_high_3.json: 1.6.0 → 1.7.0

**自動更新:**
- アプリ削除不要：起動時に自動更新
- `RepitanApp.checkBuiltInDeckUpdates()`が実行
- 学習進捗（復習スケジュール、正解率等）は完全に保持

#### 5. タイピング入力時の回答時間による自動評価 ✨NEW
**ファイル:** `Repitan/Views/Study/TestView.swift`

**問題点:**
- タイピング入力では、正解時に全て「完璧！(Easy)」評価になっていた
- 「少し考えて正解」と「即答で正解」が区別されていなかった
- 記憶科学（Desirable Difficulty理論）に基づくと、想起の努力度が反映されていない
- すべて4日後の復習になり、早期の記憶定着機会を逃していた

**修正内容:**
- タイピング開始時刻を記録（`typingStartTime`）
- `TypingResultType.correct`に`responseTime`を追加
- `TypingInputView`で回答時間を計算
- `handleTypingResult()`で評価判定を実施

**評価基準:**
- **3秒未満**: Easy評価（😊 完璧！）→ 4日後に復習（即卒業）
- **3秒以上**: Hard評価（🤔 少し考えた）→ 20分後に復習（ステップ2へ）
- **不正解**: Again評価（😰 全然ダメ）→ 3分後に復習

**科学的根拠:**
- Desirable Difficulty理論（Bjork & Bjork, 2011）に基づく
- 想起の努力度をタイピング時間で客観的に測定
- 困難を感じた項目は短い間隔（20分）で復習
- 簡単だった項目は長い間隔（4日）で復習

**効果:**
1. ✅ 想起の努力度が学習スケジュールに正確に反映される
2. ✅ 定着不十分な単語は早期に再復習される（20分後）
3. ✅ 完全に定着した単語は効率的にスキップされる（4日後）
4. ✅ 記憶科学に基づいた最適な学習サイクル
5. ✅ ユーザーの負担増加なし（自動判定）

**対象モード:**
- ✅ タイピング入力（通常モード）
- ✅ タイピング入力（活用形モード）
- ✅ 音声認識：従来通りEasy/Again評価
- ✅ 頭で考えて：従来通り手動評価

#### 6. GitHub Pages更新とGit初期化
**ファイル:** `docs/help.html`, `docs/index.html`, `.gitignore`

**問題点:**
- Webページに回答時間判定機能の説明がなかった
- プロジェクトがGit管理されていなかった

**修正内容:**

**GitHub Pages更新:**
- `docs/help.html`: 「回答方法別の自動評価」セクション追加
- `docs/index.html`: 「時間判定による自動評価」機能カード追加
- 回答方法の比較表（💭頭で考えて / ⌨️入力して / 🎤声で）
- 科学的根拠（Desirable Difficulty理論）の説明
- **評価段階の誤記修正**: "4段階" → "3段階：全然ダメ・少し考えた・完璧！"

**Git初期化:**
- Gitリポジトリ初期化
- `.gitignore`作成（Xcode, ビルド成果物, macOS関連を除外）
- 94ファイル（34,786行）を初回コミット
- GitHubリポジトリ連携: https://github.com/mojosoftjp/repitan
- docs/.gitを削除して通常ディレクトリ化
- GitHub Pagesへpush完了

**公開URL:**
- https://mojosoftjp.github.io/repitan/
- https://mojosoftjp.github.io/repitan/help.html
- https://github.com/mojosoftjp/repitan

#### 7. セッション完了後の通知タイミングと件数バグ修正 🐛FIX
**ファイル:** `Repitan/Views/Study/TestView.swift`

**問題点1（タイミング）:**
- 20分待機中のカードが10語あるのに、3分後に通知が来る
- 通知時刻が常に`learningSteps.first`（3分）で固定されていた

**問題点2（件数不一致）:**
- 3分後に「10語の復習時間になりました」と通知
- しかし実際に復習可能なのは5語のみ（残り5語は20分待ち）
- 通知件数と実際の復習可能件数が不一致

**根本原因:**
- セッション完了時にカードごとに異なる`learningDueDate`が設定される
  - ステップ1のカード（learningStep=0）: セッション終了 + 3分
  - ステップ2のカード（learningStep=1）: セッション終了 + 20分
- 通知は最も早い時刻（3分後）で発火
- しかし通知件数は全カード数（10語）をカウント
- **3分後の通知時点では5語しか復習可能でない**

**修正内容（455-477行目）:**
```swift
// 修正前：全カード数をカウント
let cardCount = learningCards.count  // = 10語
NotificationManager.shared.scheduleSessionLearningNotification(
    cardCount: cardCount,  // ← 全カード数
    dueDate: earliestDueDate
)

// 修正後：通知時刻に実際に復習可能になるカード数のみカウント
let tolerance: TimeInterval = 60  // 1分の誤差許容
let cardsReadyAtEarliestTime = learningCards.filter { card in
    if let dueDate = card.learningDueDate {
        return abs(dueDate.timeIntervalSince(earliestDueDate)) <= tolerance
    }
    return false
}.count  // = 5語（3分後に復習可能なカードのみ）

NotificationManager.shared.scheduleSessionLearningNotification(
    cardCount: cardsReadyAtEarliestTime,  // ← 正確な件数
    dueDate: earliestDueDate
)
```

**効果:**
- ✅ 通知時刻が実際に復習可能になる時刻と一致
- ✅ 通知件数が実際の復習可能件数と完全一致
- ✅ 3分待ち5語 + 20分待ち5語 → 3分後に「5語の復習時間」と正確に通知
- ✅ ユーザーの混乱を完全に解消

#### 8. 起動時のフリーズ問題修正 🐛FIX
**ファイル:** `Repitan/App/RepitanApp.swift`

**問題点:**
- アプリ起動時にフリーズして入力を受け付けない
- UIが数秒間応答しない

**根本原因:**
- `setupInitialData()`がメインスレッドで重い処理を実行
- `checkBuiltInDeckUpdates()`で4つのJSONファイル（約1,500語）を読み込み
- `updateExistingCards()`で全カードを走査して更新チェック
- Task内でも`@MainActor`のためメインスレッドで実行されていた

**修正内容（180-195行目、213-219行目）:**
```swift
// 修正前：Task（メインスレッドで実行）
Task {
    await BuiltInDeckLoader.loadIrregularVerbsDeck(modelContext: context, isActive: false)
}

// 修正後：Task.detached（バックグラウンドスレッドで実行）
Task.detached { [modelContainer] in
    let backgroundContext = ModelContext(modelContainer)
    await BuiltInDeckLoader.loadIrregularVerbsDeck(modelContext: backgroundContext, isActive: false)
}
```

**効果:**
- ✅ アプリ起動時のフリーズを完全解消
- ✅ UIが即座に応答するようになる
- ✅ デッキ更新処理がバックグラウンドで実行
- ✅ ユーザー体験が大幅に改善

### セッション9 作業サマリー

**合計8項目の改善を実施:**
1. ✅ 復習タイミングの最適化（セッション完了時点から再計算）
2. ✅ 復習候補が0の時の制御強化（空セッション防止）
3. ✅ 学習モード選択画面の自動更新（10秒ごと + アプリ復帰時）
4. ✅ 重複する日本語訳の完全修正（82単語、3デッキバージョンアップ）
5. ✅ タイピング入力時の回答時間による自動評価（3秒判定、科学的根拠あり）
6. ✅ GitHub Pages更新とGit初期化（94ファイル、公開URL 3つ）
7. ✅ セッション完了後の通知タイミングと件数バグ修正（正確な件数通知）
8. ✅ 起動時のフリーズ問題修正（バックグラウンド実行化）

**変更ファイル数:** 10ファイル以上
**コミット数:** 7コミット
**主な技術改善:**
- 間隔反復学習アルゴリズムの最適化
- ユーザー体験の大幅改善（フリーズ解消、正確な通知）
- 記憶科学に基づいた学習サイクル実装
- パフォーマンス最適化（非同期処理、スレッド分離）

---

## 過去セッション（2026-01-01 セッション4）の作業内容

### 完了した作業

#### 1. 学習デッキ選択機能の追加
**ファイル:** `Repitan/Views/Cards/CardsView.swift`

**内容:**
- カード管理画面でデッキのアイコンをタップして学習デッキを切り替え可能に
- アクティブなデッキにはチェックマークアイコンを表示
- `DeckSection`に`selectDeck()`関数を追加（他のデッキを非アクティブにして選択デッキをアクティブに）

#### 2. 復習カードの重複問題を修正（セッション3で対応済み）
- `reviewDueCards`からlearning/relearningステータスを除外
- `prepareCards()`で重複除去ロジックを追加

#### 3. アクティブデッキの視覚的表示（セッション3で対応済み）
- カード管理画面で「学習中」バッジを表示
- アクティブデッキにボーダーとハイライト
- 学習モード選択画面でアクティブデッキ名と語数を表示

---

## 過去セッション（2026-01-01 セッション3）の作業内容

### 完了した作業

#### 1. 中2単語デッキJSON作成（完了）
**ファイル:** `Repitan/Resources/Decks/junior_high_2.json`

**内容:**
- 582語（中2英単語.csvより重複・過去形単独エントリを除外・統合）
- 57個の不規則動詞を含む
- 各単語に発音記号、品詞、例文、日本語訳を付与

#### 2. オンボーディング画面の簡素化
- 学年選択を中1・中2の2つのみに変更
- 教科書選択ページを削除（3ページ→2ページに）
- 完了時は`loadDeckForGrade`で学年別デッキを読み込む

#### 3. サンプルデッキの自動作成を削除
- `RepitanApp.swift`から`#if DEBUG`のサンプルデッキ作成を削除
- `BuiltInDeckLoader.swift`から`createSampleDeck`関数を削除

#### 4. カテゴリシステムの簡素化
- `DeckCategoryManager`を学年レベル別（junior_high_1, junior_high_2）+ カスタムのみに変更
- 教科書別・英検別カテゴリを削除
- デッキ作成画面からカテゴリ選択を削除（カスタムデッキは自動的に"custom"）

#### 5. 学習完了画面でキーボードを閉じる
- `SessionCompleteView.swift`の`onAppear`でキーボードを閉じる処理を追加

---

## 未完了の作業（手動で実施が必要）

### JSONファイルをXcodeプロジェクトに追加

**重要**: 以下のファイルはXcodeプロジェクトに追加されていません。手動で追加が必要です。

1. Xcodeを開く
2. `Repitan/Resources/Decks/` フォルダ内の以下のファイルをプロジェクトナビゲータにドラッグ：
   - `junior_high_1.json`
   - `junior_high_2.json`
3. ダイアログで以下を選択：
   - ☑️ Copy items if needed
   - ☑️ Add to targets: Repitan

### アプリのテスト

1. シミュレータでアプリを削除（データベースリセット）
2. アプリをビルド・実行
3. オンボーディングで「中学1年生」または「中学2年生」を選択
4. 学習画面でデッキが読み込まれることを確認

---

## ファイル構成（主要ファイル）

```
Repitan/
├── App/
│   ├── RepitanApp.swift         # サンプルデッキ作成削除済み
│   └── ContentView.swift
├── Models/
│   ├── Card.swift               # pastTense, pastParticiple等追加済み
│   ├── Deck.swift
│   ├── DeckCategoryManager.swift # 学年レベル別に簡素化
│   └── UserSettings.swift
├── Views/
│   ├── Study/
│   │   ├── TestView.swift
│   │   └── SessionCompleteView.swift  # キーボード非表示追加
│   ├── Cards/
│   │   └── CreateDeckView.swift  # カテゴリ選択削除
│   └── Onboarding/
│       └── OnboardingView.swift  # 中1・中2のみ、教科書選択削除
├── Services/
│   └── BuiltInDeckLoader.swift   # createSampleDeck削除
└── Resources/
    ├── Assets.xcassets/
    └── Decks/
        ├── junior_high_1.json    # 中1レベル（約380語）✅ 完成
        └── junior_high_2.json    # 中2レベル（582語）✅ 完成
```

---

## デッキ統計

### junior_high_1.json
- 総カード数: 約380語
- 不規則動詞を含む

### junior_high_2.json
- 総カード数: 582語
- 不規則動詞: 57語
- 品詞内訳:
  - 名詞: 323語
  - 動詞: 135語
  - 形容詞: 83語
  - 副詞: 19語
  - その他: 22語

---

## 過去セッションの改善内容

### セッション1
- 「ホームに戻る」ボタンの修正
- アプリアイコン変更
- 品詞表示機能
- デフォルト回答方法を`.typing`に変更
- 自動評価機能

### セッション2
- BuiltInDeckLoaderの学年レベル別対応
- 中1単語デッキJSON作成

---

## 注意事項

1. **JSONファイルのXcode登録**: 必ず手動でXcodeプロジェクトに追加が必要
2. **データベースリセット**: スキーマ変更時はアプリを削除して再インストールが必要
3. **品詞の色**: `TestView`内の`partOfSpeechColor()`関数で定義

---

## 動作確認済み環境

- Xcode: 16.0+
- iOS: 17.0+
- Swift: 5.9+
