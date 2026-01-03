# リピたん セッション引き継ぎ

## 最終更新: 2026-01-03 セッション9

---

## アプリ情報

| 項目 | 値 |
|------|-----|
| **アプリ名** | リピたん |
| **英語表記** | Repitan |
| **Bundle ID** | biz.mojosoft.repitan |
| **Team ID** | 79KR66X3Z6 |
| **iOS** | 17.0+ |

---

## 現在のステータス

**フェーズ**: Phase 3 リリース準備中

**ビルド状態**: 動作確認済み（2026-01-01）

---

## 完了した作業

### Phase 1 MVP（完了）

#### Models（10ファイル）
| ファイル | 説明 | 状態 |
|---------|------|------|
| CardStatus.swift | enum定義（CardStatus, AnswerMethod, SessionType） | ✅ |
| DeckCategoryManager.swift | カテゴリ管理 | ✅ |
| Deck.swift | デッキ（単語帳）モデル | ✅ |
| Card.swift | 単語カードモデル（SM-2パラメータ + 過去形・過去分詞対応） | ✅ |
| ReviewHistory.swift | 復習履歴 | ✅ |
| StudySession.swift | 学習セッション | ✅ |
| DailyStats.swift | 日次統計 | ✅ |
| UserSettings.swift | ユーザー設定（hasCompletedOnboarding, useSpeechRecognition追加） | ✅ |
| Achievement.swift | 実績 | ✅ |
| AppError.swift | エラー定義（invalidCSVFormat, saveFailed追加） | ✅ |

#### Services（7ファイル）
| ファイル | 説明 | 状態 |
|---------|------|------|
| SM2Algorithm.swift | SM-2アルゴリズム（学習ステップ付き） | ✅ |
| StreakCalculator.swift | ストリーク計算 | ✅ |
| DailyStatsManager.swift | 日次統計管理 | ✅ |
| TTSManager.swift | Text-to-Speech（発音再生） | ✅ |
| BuiltInDeckLoader.swift | 教科書デッキ読み込み | ✅ |
| SpeechRecognizer.swift | 音声認識サービス | ✅ |
| CSVImporter.swift | CSVインポートサービス（過去形・過去分詞対応） | ✅ |

#### Extensions（3ファイル）
| ファイル | 説明 | 状態 |
|---------|------|------|
| Color+Extensions.swift | rpカラー定義（14色 + エイリアス） | ✅ |
| Font+Extensions.swift | rpフォント定義（拡張済み） | ✅ |
| ButtonStyles.swift | ボタンスタイル | ✅ |

#### Views（14ファイル）
| ファイル | 説明 | 状態 |
|---------|------|------|
| RepitanApp.swift | アプリエントリポイント（DB自動リセット付き） | ✅ |
| ContentView.swift | TabView（オンボーディング分岐） | ✅ |
| HomeView.swift | ダッシュボード | ✅ |
| StudySessionView.swift | 学習セッション選択 | ✅ |
| TestView.swift | テスト画面（3段階評価 + 音声認識 + 不規則動詞表示） | ✅ |
| SessionCompleteView.swift | セッション完了 | ✅ |
| CardsView.swift | デッキ一覧 | ✅ |
| DeckDetailView.swift | デッキ詳細（CSVインポートメニュー追加） | ✅ |
| CreateDeckView.swift | デッキ作成 | ✅ |
| AddCardView.swift | カード追加 | ✅ |
| CSVImportView.swift | CSVインポート画面 | ✅ |
| SettingsView.swift | 設定画面（音声認識トグル追加） | ✅ |
| OnboardingView.swift | オンボーディング | ✅ |

#### Resources
- Assets.xcassets（カラーセット14色、AppIcon枠）
- Decks/new_horizon_1.json（96単語）

---

### Phase 2 進捗

#### 完了
| 機能 | 状態 |
|------|------|
| オンボーディング画面 | ✅ |
| - ウェルカム画面 | ✅ |
| - 学年選択（中1〜3） | ✅ |
| - 教科書選択（NH/SS/BS） | ✅ |
| - 完了画面 | ✅ |
| 教科書データ（New Horizon 1年） | ✅ |
| - 96単語（12ユニット分） | ✅ |
| BuiltInDeckLoader更新 | ✅ |
| - loadDeckForTextbook() | ✅ |
| 音声認識機能 | ✅ |
| - SpeechRecognizer.swift | ✅ |
| - 音声権限リクエスト（マイク+音声認識） | ✅ |
| - TestViewへの統合（マイクボタン） | ✅ |
| - レーベンシュタイン距離による類似度判定 | ✅ |
| - 設定画面から有効/無効切替 | ✅ |
| - 確認ステップ付きやり直し機能 | ✅ |
| CSVインポート機能 | ✅ |
| - CSVImporter.swift | ✅ |
| - CSVImportView.swift | ✅ |
| - ヘッダー自動認識（日本語対応） | ✅ |
| - 重複スキップ機能 | ✅ |
| - DeckDetailViewからアクセス | ✅ |

#### 未完了（Phase 2）
| 機能 | 優先度 | 備考 |
|------|--------|------|
| 課金機能（StoreKit 2） | 中 | v1.0では見送り |
| 親向けレポート | 低 | v2.0以降 |
| CloudKit同期 | 低 | v2.0以降 |

---

### Phase 3 進捗（2026-01-01 セッション3）

#### 完了
| 機能 | 状態 | 詳細 |
|------|------|------|
| 通知機能 | ✅ | NotificationManager.swift追加 |
| - 復習リマインダー | ✅ | 学習ステップ完了時に自動スケジュール |
| - 日次リマインダー | ✅ | 毎朝9時に復習数を通知 |
| - 毎日のリマインダー | ✅ | 繰り返し通知（設定から有効化） |
| - まとめ通知 | ✅ | 同時刻の復習を1つにまとめる |
| - 設定画面連携 | ✅ | ON/OFF、時刻変更可能 |
| ホーム画面復習カウント修正 | ✅ | review/masteredのみカウント（learning/relearning除外） |
| ホーム画面統計リアルタイム更新 | ✅ | sheet onDismissで再読み込み |
| ヘルプ画面 | ✅ | HelpView.swift + help.html |
| - HTML形式ヘルプ | ✅ | WKWebViewで表示 |
| - 複数パス検索 | ✅ | findHelpHTML()で4パターン検索 |
| - 学習フローSVG図解 | ✅ | help.html内に埋め込み |
| オンボーディング画像変更 | ✅ | SplashImage（repitan_maru.png）使用 |
| スプラッシュ画面無効化 | ✅ | UILaunchScreen_Generation = YES |
| 学年別単語帳データ | ✅ | 教科書別→学年別に変更 |
| - junior_high_1.json | ✅ | 中1レベル単語帳 |
| - junior_high_2.json | ✅ | 中2レベル単語帳（不規則動詞含む） |
| 用語統一「デッキ→単語帳」 | ✅ | 全13ファイル変更 |

---

### Phase 3.5 進捗（2026-01-01 セッション4）

#### 完了
| 機能 | 状態 | 詳細 |
|------|------|------|
| 単語帳新規作成時の自動選択無効化 | ✅ | deck.isActive = false |
| 単語帳削除機能 | ✅ | 確認アラート付き削除 |
| - ビルトイン単語帳保護 | ✅ | isBuiltInフラグでシステム単語帳削除不可 |
| - 削除確認アラート | ✅ | 単語帳名とカード数を表示 |
| 活用形モード発音対応 | ✅ | 自動再生時に過去形・過去分詞も発音 |
| - 順次発音機能 | ✅ | TTSManager.speakSequence()追加 |
| - モード連動 | ✅ | presentOnly/presentAndPast/allFormsに応じて発音 |
| 「答えを見る」正誤判定対応 | ✅ | 空欄でも活用形判定＋発音実行 |

#### 変更ファイル一覧（Phase 3.5 / セッション4）

| ファイル | 変更内容 |
|---------|---------|
| CreateDeckView.swift | 新規作成時にdeck.isActive = false設定 |
| DeckDetailView.swift | 単語帳削除機能追加（アラート、ビルトイン保護） |
| TTSManager.swift | speakSequence()メソッド追加（順次発音） |
| TestView.swift | revealAnswer()に活用形判定・発音追加 |
| SPECIFICATION.md | セクション21「更新履歴」追加 |
| help.html | 「活用形出題モード」「単語帳の削除」セクション追加 |

---

### Phase 3.6 進捗（2026-01-02 セッション5）

#### 完了
| 機能 | 状態 | 詳細 |
|------|------|------|
| 活用形結果表示改善 | ✅ | ユーザー入力値を正確に表示 |
| - ConjugationResultType拡張 | ✅ | presentInput/pastInput/pastParticipleInput追加 |
| - FormResultRow改善 | ✅ | ユーザー入力を表示、不正解時は正解も併記 |
| Enterキー自動判定復活 | ✅ | 最後のフィールドでEnter押下で判定実行 |
| 復習通知スケジュール修正 | ✅ | 学習時に復習通知がスケジュールされない問題を修正 |
| - scheduleNotificationIfEnabled追加 | ✅ | SM2Algorithmに公開メソッド追加 |
| - TestViewから通知スケジュール呼び出し | ✅ | handleRating/recordAutoRatingで通知スケジュール |
| 朝の通知文言改善 | ✅ | 復習0件時は「新しい単語を学習しましょう！」に変更 |
| - scheduleDailySummaryNotification拡張 | ✅ | reviewCountパラメータ追加 |
| - HomeViewで復習件数を反映 | ✅ | 画面表示時に翌日の通知を更新 |

#### 変更ファイル一覧（Phase 3.6 / セッション5）

| ファイル | 変更内容 |
|---------|---------|
| TestView.swift | ConjugationResultTypeにユーザー入力フィールド追加、FormResultRowでユーザー入力表示、onSubmitで自動判定復活、復習通知スケジュール追加 |
| SM2Algorithm.swift | scheduleNotificationIfEnabled()公開メソッド追加 |
| NotificationManager.swift | scheduleDailySummaryNotification()にreviewCountパラメータ追加、復習0件時の文言変更 |
| HomeView.swift | updateDailySummaryNotification()追加、画面表示時に翌日の復習通知を更新 |

---

### Phase 3.7 進捗（2026-01-02 セッション6）

#### 完了
| 機能 | 状態 | 詳細 |
|------|------|------|
| ヘルプ画面キャラクター画像 | ✅ | Base64埋め込みで表示 |
| - loadHTMLWithEmbeddedImage() | ✅ | SplashImageをBase64変換してHTML内に埋め込み |
| - help.htmlヘッダー | ✅ | キャラクター画像表示、サブタイトル白色 |
| ホーム画面吹き出しUI | ✅ | StreakCardをキャラクター＋吹き出しデザインに変更 |
| - RepitanCharacter.imageset | ✅ | repitan_only.png（テキストなし版）追加 |
| - SpeechBubble | ✅ | 吹き出しコンポーネント（色指定可能） |
| - BubbleTail | ✅ | 左向き三角形シェイプ（吹き出しの尻尾） |
| - 薄いオレンジ背景 | ✅ | Color.rpStreak.opacity(0.15) |
| GitHub Pages公開 | ✅ | Apple審査用Webページ |
| - index.html | ✅ | ランディングページ（中高生向けアピール） |
| - privacy.html | ✅ | プライバシーポリシー |
| - support.html | ✅ | サポートページ（FAQ） |
| - help.html | ✅ | ヘルプページ（間隔反復学習説明） |

#### 公開URL

| ページ | URL |
|--------|-----|
| トップページ | https://mojosoftjp.github.io/repitan/ |
| プライバシーポリシー | https://mojosoftjp.github.io/repitan/privacy.html |
| サポート | https://mojosoftjp.github.io/repitan/support.html |
| ヘルプ | https://mojosoftjp.github.io/repitan/help.html |

#### App Store Connect設定用

| 項目 | URL |
|------|-----|
| プライバシーポリシーURL | https://mojosoftjp.github.io/repitan/privacy.html |
| サポートURL | https://mojosoftjp.github.io/repitan/support.html |

#### 変更ファイル一覧（Phase 3.7 / セッション6）

| ファイル | 変更内容 |
|---------|---------|
| HomeView.swift | StreakCard吹き出しUI、SpeechBubble/BubbleTailコンポーネント追加、Triangle削除 |
| HelpView.swift | loadHTMLWithEmbeddedImage()追加（Base64画像埋め込み） |
| help.html | ヘッダーにキャラクター画像追加、サブタイトル白色 |
| RepitanCharacter.imageset/Contents.json | repitan_only.png設定 |
| **docs/** | **GitHub Pages用（新規フォルダ）** |
| docs/index.html | ランディングページ |
| docs/privacy.html | プライバシーポリシー |
| docs/support.html | サポートページ |
| docs/help.html | ヘルプページ |
| docs/images/app_icon.png | アプリアイコン |
| docs/images/repitan_maru.png | キャラクター画像 |

---

### Phase 3.8 進捗（2026-01-02 セッション7）

#### 完了
| 機能 | 状態 | 詳細 |
|------|------|------|
| 中3レベル単語帳 | ✅ | junior_high_3.json（400単語） |
| - 名詞 | ✅ | 200語（科目、職業、自然、抽象概念等） |
| - 動詞 | ✅ | 50語（不規則動詞含む） |
| - 形容詞 | ✅ | 100語（比較級・最上級対応単語） |
| - 序数 | ✅ | 22語（first〜twenty-second） |
| - 副詞・接続詞等 | ✅ | 28語 |
| オンボーディング中3対応 | ✅ | 学年選択に中3追加 |
| カード管理中3表示 | ✅ | 既存ユーザーへの自動追加機能 |
| 新単語帳自動追加機能 | ✅ | loadMissingBuiltInDecks() |

#### 変更ファイル一覧（Phase 3.8 / セッション7）

| ファイル | 変更内容 |
|---------|---------|
| junior_high_3.json | **新規作成** - 中3レベル単語帳（400単語） |
| DeckCategoryManager.swift | 中3カテゴリ追加（junior_high_3, "中3レベル", "📙"） |
| BuiltInDeckLoader.swift | gradeFilesとgradesに中3追加 |
| OnboardingView.swift | availableGradesに3追加（[1, 2, 3]） |
| RepitanApp.swift | loadMissingBuiltInDecks()追加（既存ユーザー向け新単語帳自動追加） |
| project.pbxproj | junior_high_3.json追加 |

#### 新単語帳自動追加機能（loadMissingBuiltInDecks）

アプリ更新後、既存ユーザー（オンボーディング完了済み）にも新しい組み込み単語帳を自動追加する機能。

```
[アプリ起動]
    ↓
[setupInitialData()]
    ↓
[loadMissingBuiltInDecks()]
    ↓
[オンボーディング完了済み？] → No → 終了（オンボーディング時に読み込まれる）
    ↓ Yes
[既存の組み込み単語帳を取得]
    ↓
[全学年カテゴリと比較]
    ↓
[不足カテゴリを特定]
    ↓
[不足単語帳を非アクティブで追加] → ユーザーがカード管理から選択可能
```

---

### Phase 3.9 進捗（2026-01-03 セッション8）

#### 完了
| 機能 | 状態 | 詳細 |
|------|------|------|
| 直接復習モード | ✅ | ホーム画面から直接TestViewを開く |
| - showDirectReview状態追加 | ✅ | fullScreenCoverで表示 |
| - prepareReviewCards() | ✅ | 復習カードを優先度順に準備 |
| 単語修正 | ✅ | junior_high_3.json |
| - realize | ✅ | 「理解する」→「気づく、実現する」 |
| - raise | ✅ | 「持ち上げる」→「(高く)持ち上げる、高める」 |
| 判定表示バグ修正 | ✅ | TestView.swift |
| - 条件ロジック修正 | ✅ | 結果有無で分岐（selfReportチェック削除） |
| 間違った単語の日本語表示 | ✅ | TypingResultView / FormResultRow |
| - findJapaneseMeaning() | ✅ | 英単語からカード検索 |
| - 過去形・過去分詞対応 | ✅ | 「〜の過去形」「〜の過去分詞」表示 |
| 単語の曖昧性解消 | ✅ | JSONファイル修正 |
| - 「円」 | ✅ | yen → 円(通貨)、circle → 円(形状) |
| - 「しかし」 | ✅ | but → しかし・でも、however → しかしながら |
| 学習ステップ修正 | ✅ | 通知が1分→3分に来るよう修正 |
| - UserSettings.swift | ✅ | init()を[3, 20]に修正 |
| - migrateOldLearningSteps() | ✅ | 既存ユーザーの設定を強制更新 |
| 単語帳バージョン管理システム | ✅ | アプリ更新で単語帳を自動更新 |
| - Deck.builtInVersion | ✅ | バージョン追跡用プロパティ |
| - checkAndUpdateDeck() | ✅ | バージョン比較・更新メソッド |
| - セマンティックバージョン比較 | ✅ | compareVersions()で1.0.0形式を比較 |
| - 学習進捗保持更新 | ✅ | updateExistingCards()で進捗維持 |

#### 変更ファイル一覧（Phase 3.9 / セッション8）

| ファイル | 変更内容 |
|---------|---------|
| HomeView.swift | 直接復習モード追加（showDirectReview, reviewCardsToStudy, prepareReviewCards, fullScreenCover） |
| TestView.swift | 判定表示ロジック修正、@Query allCardsInDB追加、TypingResultView/ConjugationResultView/FormResultRowにallCards渡し、findJapaneseMeaning()追加 |
| junior_high_1.json | but→「しかし、でも」修正、バージョン1.1.0 |
| junior_high_2.json | yen→「円(通貨)」修正、バージョン1.1.0 |
| junior_high_3.json | realize/raise/circle/however修正、バージョン1.1.0 |
| Deck.swift | builtInVersionプロパティ追加 |
| BuiltInDeckLoader.swift | バージョン管理システム追加（checkAndUpdateDeck, shouldUpdateDeck, compareVersions, updateExistingCards） |
| UserSettings.swift | init()のlearningSteps/relearningSteps値修正 |
| RepitanApp.swift | migrateOldLearningSteps()追加、checkBuiltInDeckUpdates()追加 |

#### 直接復習モードの仕組み

```
[ホーム画面「復習を始める」ボタン]
    ↓
[prepareReviewCards()]
    ↓
[カード優先度: learningCards → reviewDueCards → pendingLearningCards]
    ↓
[重複除去（Set<UUID>使用）]
    ↓
[fullScreenCover → TestView(cards: reviewCardsToStudy, sessionType: .review)]
```

#### 間違った単語の日本語表示機能

タイピングや活用形入力で間違った単語を入力した場合、その単語がデータベースに存在すれば日本語訳を括弧付きで表示。

- 原形で一致: カードのjapaneseを表示
- 過去形で一致: 「〜の過去形」と表示
- 過去分詞で一致: 「〜の過去分詞」と表示

#### 単語帳バージョン管理システム

アプリを削除しなくても、組み込み単語帳の変更（誤字修正、新単語追加等）を自動的に反映する機能。

```
[アプリ起動]
    ↓
[setupInitialData()]
    ↓
[checkBuiltInDeckUpdates()]
    ↓
[各JSONファイルを読み込み]
    ↓
[既存の単語帳とバージョン比較] → shouldUpdateDeck()
    ↓ バージョンが新しい場合
[updateExistingCards()] → 学習進捗は保持したまま日本語訳等を更新
    ↓
[deck.builtInVersion を更新]
```

- **セマンティックバージョニング**: 1.0.0 < 1.0.1 < 1.1.0 < 2.0.0
- **学習進捗保持**: 英単語をキーにして照合、日本語訳・発音記号等のみ更新
- **新規カード追加**: JSONに新しい単語があれば自動追加

---

#### GitHubリポジトリ

- **リポジトリ**: https://github.com/mojosoftjp/repitan
- **認証**: Fine-grained Personal Access Token（Contents: Read and write）

#### 変更ファイル一覧（Phase 3 / セッション3）

| ファイル | 変更内容 |
|---------|---------|
| NotificationManager.swift | **新規作成** - 通知管理サービス |
| HelpView.swift | **新規作成** - ヘルプ画面（WKWebView） |
| help.html | **新規作成** - HTMLヘルプ（SVG図解含む） |
| junior_high_1.json | **新規作成** - 中1レベル単語帳 |
| junior_high_2.json | **新規作成** - 中2レベル単語帳 |
| LaunchScreen.storyboard | **新規作成** - ランチスクリーン（未使用） |
| HomeView.swift | 復習カウント修正、統計リアルタイム更新、「単語帳」表記 |
| StudySessionView.swift | 復習カウント修正、「単語帳」表記 |
| SettingsView.swift | ヘルプへのリンク追加 |
| OnboardingView.swift | 画像をSplashImageに変更、「単語帳」表記 |
| BuiltInDeckLoader.swift | 学年別読み込み対応、「単語帳」表記 |
| CardsView.swift | 「単語帳」表記（マイ単語帳、新しい単語帳を作成等） |
| CreateDeckView.swift | 「単語帳名」「新しい単語帳」表記 |
| DeckDetailView.swift | 「単語帳」表記 |
| CSVImportView.swift | 「単語帳」表記 |
| CSVImporter.swift | 「単語帳」表記（コメント） |
| DeckCategoryManager.swift | 「単語帳カテゴリ管理」表記 |
| AppError.swift | 「単語帳が見つかりません」表記 |
| Deck.swift | 「単語帳（単語帳）」表記 |
| help.html | 「単語帳」表記（全セクション） |
| project.pbxproj | 新規ファイル追加、LaunchScreen設定 |

#### 残りのPhase（リリースまで）

| Phase | 内容 | 優先度 |
|-------|------|--------|
| **Phase 4: テスト＆バグ修正** | | **高** |
| - 全機能の動作確認 | 通知、学習、統計、ヘルプ等 | 必須 |
| - エッジケーステスト | 0件時の表示、長文対応等 | 必須 |
| - パフォーマンス確認 | 大量カード時の動作 | 必須 |
| **Phase 5: ストア準備** | | **高** |
| - AppIcon完成 | 1024x1024 + 各サイズ | 必須 |
| - スクリーンショット作成 | 6.7インチ、5.5インチ | 必須 |
| - App Store説明文 | 日本語 | 必須 |
| - プライバシーポリシー | URL準備 | 必須 |
| - 利用規約 | URL準備 | 必須 |
| **Phase 6: 審査提出** | | **高** |
| - Archive作成 | Release build | 必須 |
| - App Store Connect設定 | メタデータ入力 | 必須 |
| - TestFlight（任意） | ベータテスト | 推奨 |
| - 審査提出 | | 必須 |

---

## ファイル構成

```
/Volumes/MyData/Xcode/Projects/Repitan/
├── SPECIFICATION.md          # 詳細設計書（v2）
├── SESSION_HANDOFF.md        # このファイル
├── Repitan.xcodeproj/        # Xcodeプロジェクト
└── Repitan/
    ├── App/                  # 2ファイル
    │   ├── RepitanApp.swift  ← DB自動リセット機能
    │   └── ContentView.swift
    ├── Models/               # 10ファイル
    │   ├── CardStatus.swift
    │   ├── DeckCategoryManager.swift  ← 「単語帳カテゴリ管理」
    │   ├── Deck.swift                 ← 「単語帳」表記
    │   ├── Card.swift
    │   ├── ReviewHistory.swift
    │   ├── StudySession.swift
    │   ├── DailyStats.swift
    │   ├── UserSettings.swift         ← useSpeechRecognition追加
    │   ├── Achievement.swift
    │   └── AppError.swift             ← 「単語帳が見つかりません」
    ├── Services/             # 8ファイル（+1）
    │   ├── SM2Algorithm.swift
    │   ├── StreakCalculator.swift
    │   ├── DailyStatsManager.swift
    │   ├── TTSManager.swift
    │   ├── BuiltInDeckLoader.swift    ← 学年別読み込み対応
    │   ├── SpeechRecognizer.swift
    │   ├── CSVImporter.swift
    │   └── NotificationManager.swift  ← **新規** 通知管理
    ├── Extensions/           # 3ファイル
    │   ├── Color+Extensions.swift
    │   ├── Font+Extensions.swift
    │   └── ButtonStyles.swift
    ├── Views/
    │   ├── Home/            # 1ファイル
    │   │   └── HomeView.swift         ← 統計リアルタイム更新
    │   ├── Study/           # 3ファイル
    │   │   ├── StudySessionView.swift ← 復習カウント修正
    │   │   ├── TestView.swift
    │   │   └── SessionCompleteView.swift
    │   ├── Cards/           # 5ファイル
    │   │   ├── CardsView.swift        ← 「単語帳」表記
    │   │   ├── DeckDetailView.swift
    │   │   ├── CreateDeckView.swift   ← 「単語帳」表記
    │   │   ├── AddCardView.swift
    │   │   └── CSVImportView.swift    ← 「単語帳」表記
    │   ├── Settings/        # 2ファイル（+1）
    │   │   ├── SettingsView.swift     ← ヘルプリンク追加
    │   │   └── HelpView.swift         ← **新規** ヘルプ画面
    │   └── Onboarding/      # 1ファイル
    │       └── OnboardingView.swift   ← SplashImage使用
    └── Resources/
        ├── Assets.xcassets/
        ├── LaunchScreen.storyboard    ← **新規**（自動生成に置換）
        ├── Decks/
        │   ├── junior_high_1.json     ← 中1レベル
        │   ├── junior_high_2.json     ← 中2レベル
        │   ├── junior_high_3.json     ← **新規** 中3レベル（400単語）
        │   └── new_horizon_1.json     ← 旧データ（未使用）
        └── Help/
            └── help.html              ← **新規** HTMLヘルプ
```

**総ファイル数**: 37 Swiftファイル + 4 JSONファイル + 1 HTMLファイル

---

## 重要な設計決定

1. **iOS 17.0+** - SwiftData使用
2. **MVVM** - アーキテクチャ
3. **SM-2アルゴリズム（改良版）** - Ankiスタイルの学習ステップ
4. **3段階評価** - 全然ダメ(😰)/少し考えた(🤔)/完璧(😊)
5. **学習ステップ**: 新規 → 3分後 → 20分後 → 卒業(1日後)
6. **命名規則**: 色・フォント接頭辞は`rp`（Repitan）
7. **音声認識**: Speech Framework + 類似度80%以上で正解判定
8. **CSVフォーマット**: japanese,english,phonetic,example,exampleJapanese（ヘッダー自動認識、日本語対応）

---

## CSVインポート仕様

### 列構成

| 列名 | 必須 | 説明 | 例 |
|------|------|------|-----|
| japanese | ✅ | 日本語（意味） | 重要な |
| english | ✅ | 英単語 | important |
| phonetic | - | 発音記号 | /ɪmˈpɔːrtənt/ |
| example | - | 例文（英語） | This is important. |
| exampleJapanese | - | 例文（日本語訳） | これは重要です。 |
| pastTense | - | 過去形（不規則動詞用） | ran |
| pastParticiple | - | 過去分詞（不規則動詞用） | run |
| pastTensePhonetic | - | 過去形の発音記号 | /ræn/ |
| pastParticiplePhonetic | - | 過去分詞の発音記号 | /rʌn/ |

### 対応ヘッダー名

| 英語 | 日本語（代替） |
|------|---------------|
| japanese | 日本語, 意味, 和訳 |
| english | 英語, 単語, word |
| phonetic | 発音記号, 発音 |
| example | 例文, 例文（英語） |
| exampleJapanese | 例文（日本語）, 例文日本語 |
| pastTense | past_tense, 過去形 |
| pastParticiple | past_participle, 過去分詞 |
| pastTensePhonetic | past_tense_phonetic, 過去形発音 |
| pastParticiplePhonetic | past_participle_phonetic, 過去分詞発音 |

### サンプルCSV（基本）

```csv
japanese,english,phonetic,example,exampleJapanese
重要な,important,/ɪmˈpɔːrtənt/,This is important.,これは重要です。
美しい,beautiful,/ˈbjuːtɪfəl/,She is beautiful.,彼女は美しい。
```

### サンプルCSV（不規則動詞）

```csv
japanese,english,phonetic,pastTense,pastParticiple,pastTensePhonetic,pastParticiplePhonetic
走る,run,/rʌn/,ran,run,/ræn/,/rʌn/
行く,go,/ɡoʊ/,went,gone,/went/,/ɡɔːn/
食べる,eat,/iːt/,ate,eaten,/eɪt/,/ˈiːtən/
```

### 機能

- ヘッダー自動認識（日本語対応）
- ヘッダーなしモード切替可能
- 重複カード自動スキップ
- 引用符対応（カンマを含む値）
- エラー件数表示
- **不規則動詞対応**: 過去形・過去分詞を個別に発音再生可能

---

## 音声認識フロー

```
[設定で音声認識モードON]
    ↓
[テスト画面でマイクボタン表示]
    ↓
[マイクボタンタップ] → 権限リクエスト（初回）
    ↓
[音声入力] → リアルタイム文字表示
    ↓
[停止 or 5秒タイムアウト]
    ↓
[確認画面表示] ← 認識結果を表示
    ↓
[「これで判定」or「やり直し」ボタン]
    ↓
    ├─[これで判定] → 類似度判定 → 80%以上で正解 → 答え表示
    └─[やり直し] → マイクボタンに戻り再入力
```

### 確認画面の機能
- 認識結果を大きく表示
- 正解と一致している場合は緑色で「正解と一致しています」表示
- 「やり直し」ボタン: 再度音声入力（間違って認識された場合）
- 「これで判定」ボタン: 認識結果で正誤判定を実行

---

## CSVインポートフロー

```
[デッキ詳細画面 + ボタン]
    ↓
[メニュー表示] → CSVインポート選択
    ↓
[CSVImportView表示]
    ↓
[ファイル選択] → ファイルピッカー
    ↓
[ヘッダー解析] → 列マッピング
    ↓
[カード作成] → 重複スキップ
    ↓
[結果表示] → 成功/スキップ/エラー件数
```

---

## オンボーディングフロー

```
[初回起動]
    ↓
[ウェルカム画面] - アプリ紹介
    ↓
[学年選択] - 中1/中2/中3
    ↓
[教科書選択] - NEW HORIZON/SUNSHINE/BLUE SKY
    ↓
[完了画面] - 選択内容表示
    ↓
[メイン画面] - TabView
```

---

## 動作確認項目

- [x] アプリ起動
- [x] サンプルデッキ自動生成（DEBUG時）
- [x] ホーム画面表示
- [x] カード管理画面
- [x] デッキ作成
- [x] カード追加
- [x] 学習セッション選択
- [x] テスト画面（3段階評価）
- [x] SM-2アルゴリズムによるスケジューリング
- [x] TTS発音再生
- [x] セッション完了画面
- [x] 設定画面
- [ ] オンボーディング（要ビルド確認）
- [ ] 教科書デッキ読み込み（要ビルド確認）
- [ ] 音声認識（要ビルド確認）
- [ ] CSVインポート（要ビルド確認）

---

## 次回セッションでやること

### Phase 4: テスト＆バグ修正（優先度：高）
1. **全機能の動作確認**
   - 通知機能（復習リマインダー、日次リマインダー）
   - ヘルプ画面表示
   - 学習フロー（新規→学習中→復習→完了）
   - 統計のリアルタイム更新

2. **エッジケーステスト**
   - カード0件時の表示
   - 長い単語・例文の表示
   - オフライン時の動作

3. **パフォーマンス確認**
   - 500語以上での動作速度

### Phase 5: ストア準備（優先度：高）
4. **AppIcon完成**
   - 1024x1024 マスター画像
   - Assets.xcassetsへの設定

5. **スクリーンショット作成**
   - iPhone 15 Pro Max（6.7インチ）: 5枚
   - iPhone 8 Plus（5.5インチ）: 5枚
   - 推奨画面: ホーム、学習、テスト、統計、単語帳管理

6. **ストア情報準備**
   - App Store説明文（日本語）
   - プライバシーポリシーURL
   - 利用規約URL
   - キーワード設定

### Phase 6: 審査提出
7. **Archive作成＆提出**

---

## ヘルプ用スクリーンショット（未作成）

help.htmlで使用する画像（プレースホルダー状態）:

| ファイル名 | 内容 | 撮影シミュレータ |
|-----------|------|-----------------|
| home_screen.png | ホーム画面 | iPhone 15 Pro |
| study_modes.png | 学習モード選択 | iPhone 15 Pro |
| statistics.png | 統計画面 | iPhone 15 Pro |
| deck_management.png | 単語帳管理画面 | iPhone 15 Pro |

※ learning_flow.pngはSVGで作成済み（埋め込み）

配置先: `/Volumes/MyData/Xcode/Projects/Repitan/Repitan/Resources/Help/images/`

---

## 開始コマンド

次回セッション開始時:

```
SESSION_HANDOFF.mdを読んで、Phase 4のテスト＆バグ修正から進めてください
```

---

## Info.plist設定

音声認識に必要な権限:
```
NSMicrophoneUsageDescription = "英単語の発音を認識するためにマイクを使用します"
NSSpeechRecognitionUsageDescription = "英単語の発音をチェックするために音声認識を使用します"
```

---

## 参考情報

- **ターゲット**: 中学1〜3年生
- **教科書対応**: New Horizon, Sunshine, Blue Sky
- **収益化**: AdMob広告 + 広告削除課金（¥480）
- **課金Product ID**: biz.mojosoft.repitan.removeads

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-31 12:00 | Phase 1 MVP完了 |
| 2025-12-31 12:30 | オンボーディング画面追加 |
| 2025-12-31 13:00 | 教科書データ（NH1年）追加 |
| 2025-12-31 14:00 | 音声認識機能追加 |
| 2025-12-31 15:00 | CSVインポート機能追加 |
| 2025-12-31 16:00 | 不規則動詞対応（過去形・過去分詞）追加 |
| 2025-12-31 17:00 | 音声認識やり直し機能追加（確認ステップ付き） |
| **2026-01-01 セッション3** | **Phase 3 完了** |
| | - 通知機能追加（NotificationManager.swift） |
| | - 復習カウント修正（review/masteredのみ） |
| | - ホーム統計リアルタイム更新（onDismiss） |
| | - ヘルプ画面追加（HelpView.swift + help.html） |
| | - 学習フローSVG図解作成 |
| | - オンボーディング画像変更（SplashImage） |
| | - スプラッシュ画面無効化 |
| | - 学年別単語帳データ作成（中1・中2） |
| | - 用語統一「デッキ→単語帳」（13ファイル） |
| **2026-01-01 セッション4** | **Phase 3.5 機能追加** |
| | - 単語帳新規作成時の自動選択無効化 |
| | - 単語帳削除機能追加（確認アラート付き） |
| | - 活用形モード発音対応（順次発音） |
| | - 「答えを見る」時の正誤判定対応 |
| | - SPECIFICATION.md更新履歴追加 |
| | - help.html活用形・削除機能説明追加 |
| **2026-01-02 セッション5** | **Phase 3.6 バグ修正** |
| | - 活用形結果表示改善（ユーザー入力値を表示） |
| | - ConjugationResultTypeにユーザー入力フィールド追加 |
| | - FormResultRowで不正解時は正解も併記 |
| | - Enterキー自動判定機能を復活 |
| **2026-01-02 セッション6** | **Phase 3.7 UI改善 + Web公開** |
| | - ヘルプ画面キャラクター画像対応（Base64埋め込み） |
| | - ホーム画面StreakCard吹き出しUI |
| | - キャラクター＋吹き出しデザイン |
| | - BubbleTailシェイプ追加 |
| | - GitHub Pages公開（Apple審査用） |
| | - https://mojosoftjp.github.io/repitan/ |
| **2026-01-02 セッション7** | **Phase 3.8 中3レベル単語帳追加** |
| | - junior_high_3.json作成（400単語） |
| | - 名詞200語、動詞50語、形容詞100語、序数22語、副詞等28語 |
| | - DeckCategoryManager.swift: 中3カテゴリ追加 |
| | - BuiltInDeckLoader.swift: 中3読み込み対応 |
| | - OnboardingView.swift: 学年選択に中3追加 |
| | - RepitanApp.swift: 既存ユーザー向け新単語帳自動追加機能 |
| | - loadMissingBuiltInDecks()関数追加 |
| **2026-01-03 セッション8** | **Phase 3.9 UX改善 + バグ修正** |
| | - HomeView: 「復習を始める」ボタンで直接TestViewを開く機能追加 |
| | - HomeView: showDirectReview, reviewCardsToStudy追加 |
| | - HomeView: prepareReviewCards()で復習カードを準備 |
| | - HomeView: fullScreenCoverで直接レビューモード表示 |
| | - junior_high_3.json: 単語修正（realize: 気づく、raise: 高く持ち上げる） |
| | - TestView: 判定表示ロジック修正（結果有無で条件分岐） |
| | - TestView: @Query allCardsInDB追加（間違った単語の日本語検索用） |
| | - TypingResultView: findJapaneseMeaning()追加 |
| | - ConjugationResultView: allCardsパラメータ追加 |
| | - FormResultRow: findJapaneseMeaning()追加（過去形・過去分詞も検索）|
| | - 単語修正：「円」の曖昧性解消（円(通貨)/円(形状)） |
| | - 単語修正：「しかし」の曖昧性解消（しかし・でも/しかしながら） |
| | - 学習ステップ修正：通知が1分→3分に来るよう修正 |
| | - UserSettings.swift: init()の学習ステップを[3, 20]に修正 |
| | - RepitanApp.swift: migrateOldLearningSteps()追加（既存ユーザーの設定も強制更新） |
| | - 単語帳バージョン管理システム追加 |
| | - Deck.swift: builtInVersionプロパティ追加 |
| | - BuiltInDeckLoader.swift: checkAndUpdateDeck(), shouldUpdateDeck(), compareVersions(), updateExistingCards()追加 |
| | - RepitanApp.swift: checkBuiltInDeckUpdates()追加 |
| | - JSONファイルバージョン更新：1.0.0 → 1.1.0 |
| **2026-01-03 セッション9** | **Phase 3.10 復習タイミング修正 + UX改善 + 重複日本語訳修正** |
| | - **復習タイミングの最適化** |
| | - TestView: scheduleSessionNotifications()を大幅修正 |
| | - learningDueDateをセッション完了時点から計算するように変更 |
| | - 間違えた単語の復習は学習セッション終了から3分後に設定 |
| | - 各カードの学習ステップに応じた待機時間を個別計算 |
| | - **復習候補0の時の制御強化** |
| | - HomeView: reviewReadyCount追加（待機中を除く復習可能カード数） |
| | - 「復習を始める」ボタンは復習可能カードがある場合のみ表示 |
| | - prepareReviewCards()から待機中カード除外 |
| | - StudySessionView: 復習モードのcanStartStudyから待機中除外 |
| | - prepareCards()の復習モードから待機中カード除外 |
| | - **学習モード選択画面の自動更新** |
| | - StudySessionView: currentTime状態変数追加 |
| | - すべてのカード計算で現在時刻をcurrentTimeから参照 |
| | - onAppear: 画面表示時に現在時刻を更新 |
| | - onReceive(willEnterForeground): アプリ復帰時に更新 |
| | - onReceive(Timer): 10秒ごとに自動更新 |
| | - 待機中カウントがリアルタイムに近い形で更新される |
| | - **重複する日本語訳の完全修正（82単語）** |
| | - 全重複ペア（27組以上）をすべて修正完了 |
| | - movie/film, fast/quick, speak/talk, big/loud等 |
| | - JSONバージョン更新: 1.3.0, 1.4.0, 1.7.0 |
| | - アプリ削除不要：起動時に自動更新される |
| | - 学習進捗は完全に保持される |
| **5. タイピング入力時の回答時間による自動評価** | **TestView.swift** |
| | - 回答時間を計測し、想起の努力度を評価に反映 |
| | - 3秒未満: Easy評価 → 4日後（即卒業） |
| | - 3秒以上: Hard評価 → 20分後（ステップ2へ） |
| | - 記憶科学（Desirable Difficulty理論）に基づく最適化 |
| | - ユーザー負担なし（自動判定） |

---

## セッション9 詳細: 復習タイミング修正 + UX改善 + 重複日本語訳修正 + 回答時間評価

### 実施日時
2026-01-03

### 背景・問題点

#### 問題1: 復習タイミングの不適切な設定
- **現象**: 間違えた単語の`learningDueDate`が「間違えた瞬間」から3分後に設定されていた
- **問題**: 学習セッション中に複数の単語を間違えると、それぞれ異なる時刻に復習可能になる
- **期待動作**: 学習セッション完了後に、まとめて復習タイマーがスタートすべき

#### 問題2: 復習候補が0でも復習できてしまう
- **現象**: 待機中カード（`pendingLearningCards`）のみで復習可能カードがない場合でも「復習を始める」が表示される
- **問題**: 復習を開始しても待機中カードしかなく、学習効果が低い
- **期待動作**: 復習可能なカード（`learningCards` + `reviewDueCards`）がある場合のみボタン表示

#### 問題3: 学習モード選択画面の待機中カウントが更新されない
- **現象**: 画面を開いたまま3分経過しても、待機中カウントが更新されない
- **問題**: アプリをバックグラウンドから復帰させても、古いカウントが表示される
- **期待動作**: 時刻経過やアプリ復帰時に自動的にカウントが更新される

### 修正内容

#### 修正1: 復習タイミングの最適化

**ファイル**: `Repitan/Views/Study/TestView.swift`

**変更箇所**: `scheduleSessionNotifications()` 関数（413-465行目）

**修正前**:
```swift
// 通知のみセッション完了時から計算
// learningDueDateは間違えた瞬間から計算（SM2Algorithm内）
```

**修正後**:
```swift
private func scheduleSessionNotifications() {
    let learningCards = cards.filter { card in
        card.status == .learning || card.status == .relearning
    }

    guard !learningCards.isEmpty else { return }

    let learningSteps = userSettings?.learningSteps ?? [3, 20]
    let relearningSteps = userSettings?.relearningSteps ?? [20]
    let sessionEndTime = Date()

    // セッション完了時点から各カードのlearningDueDateを再計算
    for card in learningCards {
        let steps = (card.status == .relearning) ? relearningSteps : learningSteps
        let stepIndex = max(0, card.learningStep)
        let minutesToWait: Int

        if stepIndex >= steps.count {
            minutesToWait = steps.first ?? 3
        } else {
            minutesToWait = steps[stepIndex]
        }

        // セッション完了時点から計算
        card.learningDueDate = Calendar.current.date(
            byAdding: .minute,
            value: minutesToWait,
            to: sessionEndTime
        )
    }

    // 通知スケジュール（変更なし）
    // ...
}
```

**効果**:
- 学習セッション中に間違えた単語すべてが、セッション終了後にまとめて復習タイマーがスタート
- 例: セッション中に10:00, 10:02, 10:04に間違えた → セッション終了が10:05 → すべて10:08に復習可能

---

#### 修正2: 復習候補0の時の制御強化

**ファイル1**: `Repitan/Views/Home/HomeView.swift`

**追加プロパティ** (82-85行目):
```swift
/// 今すぐ復習可能なカード数（待機中を除く）
private var reviewReadyCount: Int {
    reviewDueCards.count + learningCards.count
}
```

**変更箇所1**: 「復習を始める」ボタン表示条件 (112行目)
```swift
// 修正前
if reviewDueCount > 0 || learningCardsCount > 0 {

// 修正後
if reviewReadyCount > 0 {
```

**変更箇所2**: `prepareReviewCards()` (165-188行目)
```swift
// 修正前: 待機中カードも追加していた
for card in sortedPendingCards.prefix(reviewLimit - cards.count) {
    // ...
}

// 修正後: 待機中カードを除外
// 削除
```

**ファイル2**: `Repitan/Views/Study/StudySessionView.swift`

**変更箇所1**: `canStartStudy` (164-166行目)
```swift
case .review:
    // 修正前
    return !reviewDueCards.isEmpty || !learningCards.isEmpty || !pendingLearningCards.isEmpty

    // 修正後（待機中を除外）
    return !reviewDueCards.isEmpty || !learningCards.isEmpty
```

**変更箇所2**: `prepareCards()` の復習モード (185-205行目)
```swift
// 修正前: 待機中カードも追加
for card in sortedPendingCards.prefix(reviewLimit - cards.count) {
    // ...
}

// 修正後: 待機中カードの追加処理を削除
// コメント追加: 「待機中カードは含めない」
```

**効果**:
- 復習可能なカード（今すぐ学習できる）がない場合、「復習を始める」ボタンが非表示
- 学習モード選択画面の復習モードも無効化される
- おまかせモードは従来通り待機中カードも含む

---

#### 修正3: 学習モード選択画面の自動更新

**ファイル**: `Repitan/Views/Study/StudySessionView.swift`

**追加プロパティ** (15行目):
```swift
@State private var currentTime = Date()
```

**変更箇所**: すべてのカード計算プロパティ (34, 55, 64行目)
```swift
// 修正前
return dueDate <= Date()
return dueDate > Date()

// 修正後
return dueDate <= currentTime
return dueDate > currentTime
```

**追加**: 自動更新ロジック (160-171行目)
```swift
.onAppear {
    // 画面表示時に現在時刻を更新
    currentTime = Date()
}
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
    // アプリがフォアグラウンドになったときに現在時刻を更新
    currentTime = Date()
}
.onReceive(Timer.publish(every: 10, on: .main, in: .common).autoconnect()) { _ in
    // 10秒ごとに現在時刻を更新（待機中カードの時刻チェック用）
    currentTime = Date()
}
```

**効果**:
- 画面を開いたまま3分経過 → 待機中カウントが減り、復習可能カウントが増える
- アプリをバックグラウンドから復帰 → 最新のカウントが表示される
- 10秒ごとに自動更新されるため、リアルタイムに近い表示

---

### 影響範囲

**変更ファイル**:
1. `Repitan/Views/Study/TestView.swift` - scheduleSessionNotifications()
2. `Repitan/Views/Home/HomeView.swift` - reviewReadyCount, ボタン表示条件, prepareReviewCards()
3. `Repitan/Views/Study/StudySessionView.swift` - currentTime, canStartStudy, prepareCards(), 自動更新ロジック

**影響を受ける機能**:
- 復習タイミング（学習セッション完了後の待機時間）
- ホーム画面の「復習を始める」ボタン表示制御
- 学習モード選択画面の復習モード有効/無効制御
- 学習モード選択画面のカード数表示（自動更新）

**影響を受けない機能**:
- おまかせモード（待機中カードも含む動作は維持）
- 新規学習モード
- SM-2アルゴリズムのコア計算ロジック
- 通知機能（表示内容は従来通り）

---

### テスト推奨項目

#### テスト1: 復習タイミング
1. 新規カードを5枚学習し、すべて「全然ダメ」評価
2. セッション完了時刻を記録（例: 10:05）
3. 3分後（10:08）に通知が来ることを確認
4. 学習モード選択画面で待機中が0になり、復習可能が5になることを確認

#### テスト2: 復習候補0の制御
1. すべてのカードを学習済みにする
2. セッション完了直後、「復習を始める」ボタンが非表示になることを確認
3. 学習モード選択画面の復習モードが無効（グレーアウト）になることを確認
4. おまかせモードは有効のままであることを確認

#### テスト3: 自動更新
1. 学習モード選択画面を開く
2. 待機中カウントがあることを確認（例: 待機中5枚）
3. 画面を開いたまま3分待つ
4. 待機中カウントが減り、復習可能カウントが増えることを確認
5. アプリをバックグラウンド → 3分後に復帰 → カウントが更新されることを確認

---

### 注意事項

1. **待機中カードの扱い**:
   - 復習モード: 待機中カードを含まない（今回の変更）
   - おまかせモード: 待機中カードを含む（従来通り）

2. **タイマーのパフォーマンス**:
   - 10秒ごとの更新は軽量な処理（Dateの比較のみ）
   - バッテリー消費への影響は最小限

3. **既存データへの影響**:
   - 既存の`learningDueDate`はセッション完了時に再計算されるため、互換性あり
   - データベーススキーマ変更なし

---

### 修正4: 重複する日本語訳の完全修正

**背景**: 同じ日本語訳を持つ異なる英単語が27組以上存在し、学習時に混乱を招く問題があった。

**修正内容**:

すべての重複する日本語訳に区別用の補足を追加し、学習時に明確に区別できるようにしました。

**修正数**: 82単語

**主な修正例**:
- movie / film → 映画(娯楽) / 映画(作品)
- fast / quick → 速い(スピード) / 速い(素早い)
- speak / talk → 話す(演説) / 話す(会話)
- big / loud → 大きい(サイズ) / 大きい(音量)
- exam / test → 試験(重要) / テスト
- month / moon → 月(暦) / 月(天体)
- ago / front → 前(時間) / 前(方向)
- その他多数（全82単語）

**修正ファイル**:
- junior_high_1.json: version 1.2.0 → 1.3.0
- junior_high_2.json: version 1.3.0 → 1.4.0
- junior_high_3.json: version 1.6.0 → 1.7.0

**自動更新機能**:
- アプリ削除不要：既存のバージョン管理システムにより自動更新
- 起動時に`RepitanApp.checkBuiltInDeckUpdates()`が実行
- バージョン番号を比較し、新しい場合のみ更新
- `BuiltInDeckLoader.updateExistingCards()`で日本語訳のみ更新
- **学習進捗（復習スケジュール、正解率等）は完全に保持**

**検証**:
- 重複チェック: 0件（すべて修正完了） ✅
- JSON構文チェック: すべてのファイル正常 ✅
- バージョン番号: 更新済み ✅

---

### 修正5: タイピング入力時の回答時間による自動評価

**背景・問題点**:
- タイピング入力では、正解時に全て「完璧！(Easy)」評価になっていた
- 「少し考えて正解」と「即答で正解」が区別されていなかった
- 記憶科学（Desirable Difficulty理論）に基づくと、想起の努力度が反映されていない
- 結果：すべて4日後の復習になり、早期の記憶定着機会を逃していた

**修正内容**:

**ファイル**: `Repitan/Views/Study/TestView.swift`

**追加・変更箇所**:

1. **タイピング開始時刻の記録** (30行目):
```swift
@State private var typingStartTime: Date?
```

2. **TypingResultTypeの拡張** (46-48行目):
```swift
enum TypingResultType {
    case correct(responseTime: TimeInterval)  // 回答時間を記録
    case incorrect(typed: String)
}
```

3. **TypingInputViewに開始時刻を渡す** (1363行目):
```swift
struct TypingInputView: View {
    let startTime: Date?  // 追加
    // ...
}
```

4. **回答時間の計算と自動評価** (1410-1418行目):
```swift
private func checkAnswer() {
    // 回答時間を計算
    let responseTime: TimeInterval
    if let start = startTime {
        responseTime = Date().timeIntervalSince(start)
    } else {
        responseTime = 0
    }

    if trimmedInput == expected {
        onResult(.correct(responseTime: responseTime))
    }
}
```

5. **評価基準の適用** (656-668行目):
```swift
// 回答時間に基づいて評価を決定
// 3秒未満: 即答 → easy（完璧！）→ 4日後
// 3秒以上: 少し考えた → hard（少し考えた）→ 20分後
let rating: SM2Algorithm.SimpleRating
if isCorrect {
    rating = responseTime < 3.0 ? .easy : .hard
    print("Response time: \(String(format: "%.1f", responseTime))s")
    print("Rating: \(rating == .easy ? "Easy (完璧！)" : "Hard (少し考えた)")")
} else {
    rating = .again
}
```

6. **recordAutoRating関数のシグネチャ変更** (685行目):
```swift
// 修正前
private func recordAutoRating(for card: Card, isCorrect: Bool, answerMethod: AnswerMethod)

// 修正後
private func recordAutoRating(for card: Card, rating: SM2Algorithm.SimpleRating, answerMethod: AnswerMethod)
```

**科学的根拠**:
- **Desirable Difficulty理論**（Bjork & Bjork, 2011）: 努力して思い出す過程が記憶定着を強化
- **想起の努力度**: タイピング時間で客観的に測定可能
- **最適な復習間隔**: 困難を感じた項目は短い間隔（20分）、簡単だった項目は長い間隔（4日）

**評価基準**:

| 回答時間 | 評価 | 想起状態 | 次回復習 | 学習ステップ |
|---------|------|---------|---------|-------------|
| < 3秒 | Easy (😊 完璧！) | 即答、定着済み | 4日後 | 即卒業 |
| ≥ 3秒 | Hard (🤔 少し考えた) | 努力して想起 | 20分後 | ステップ2へ |
| 不正解 | Again (😰 全然ダメ) | 想起失敗 | 3分後 | ステップ1へ戻る |

**学習フローの例**:

```
新規カード「apple」を学習:
1. タイピング: 1.5秒で正解 → Easy評価 → 即卒業 → 4日後に復習
2. 4日後の復習: 間違い → Again評価 → 再学習モード → 20分後
3. 20分後: 5秒で正解 → Hard評価 → 再学習完了 → 元の間隔で復習

新規カード「beautiful」を学習:
1. タイピング: 7秒で正解 → Hard評価 → 学習ステップ2へ → 20分後
2. 20分後: 2秒で正解 → Easy評価 → 卒業 → 1日後に復習
```

**効果**:
1. ✅ 想起の努力度が学習スケジュールに正確に反映される
2. ✅ 定着不十分な単語は早期に再復習される（20分後）
3. ✅ 完全に定着した単語は効率的にスキップされる（4日後）
4. ✅ 記憶科学に基づいた最適な学習サイクル
5. ✅ ユーザーの負担増加なし（自動判定）

**対象モード**:
- ✅ タイピング入力（通常モード）
- ✅ タイピング入力（活用形モード）：全て正解した場合のみEasy評価
- ✅ 音声認識：従来通りEasy/Again評価（即答扱い）
- ✅ 頭で考えて：従来通り手動評価（ユーザー判断）

#### 修正 #6: GitHub Pages更新（2026-01-03）

**問題点**:
- https://mojosoftjp.github.io/repitan/ のドキュメントが古い
- タイピング入力の時間判定機能が説明されていない

**修正内容**:

1. **docs/help.html更新**:
   - 「回答方法別の自動評価」セクションを追加（604-666行目）
   - 回答方法の比較表を追加（💭頭で考えて / ⌨️入力して / 🎤声で）
   - タイピングモードの時間判定詳細説明（3秒閾値、科学的根拠）
   - 音声モードの評価説明
   - 目次リンクを「評価と回答方法」に変更

2. **docs/index.html更新**:
   - 機能セクションに新カード「時間判定による自動評価」を追加（1132-1138行目）
   - タイピング入力の3秒閾値と科学的根拠を簡潔に説明

**更新ファイル**:
- `docs/help.html` - 回答方法セクション追加、目次更新
- `docs/index.html` - 機能カード追加

**公開URL**:
- トップページ: https://mojosoftjp.github.io/repitan/
- ヘルプ: https://mojosoftjp.github.io/repitan/help.html

**効果**:
- ユーザーがWebから最新機能を確認できる
- App Store審査時にも最新機能が明記される

---
