# 7. 画面・UXメモ

| ID              | 画面 / ダイアログ          | Figma (例)                       | 主要 UI 要素・インタラクション                                                       |
| --------------- | ------------------- | ------------------------------- | ----------------------------------------------------------------------- |
| **SCR-ONB**     | **オンボーディング**        | figma.com/file/XXXXX?node-id=0  | 3 枚スワイプ → 権限(PermissionSheet) → 「開始」                                    |
| **SCR-LOGIN**   | **ログイン/アカウント作成**    | figma.com/file/XXXXX?node-id=1  | Email+PW / OAuth ボタン、PW再設定リンク                                           |
| **SCR-DASH**    | **ダッシュボード**         | figma.com/file/XXXXX?node-id=2  | メトリックカード（横スクロール）・7日折れ線・FAB「＋」・オフラインバッジ(●赤)                              |
| **SCR-ADD**     | **クイック入力**          | figma.com/file/XXXXX?node-id=3  | 数値キーパッド・カテゴリピッカー(Chip)・日時変更(Picker)・**音声入力Btn** 🎤                      |
| **SCR-CAT**     | **カテゴリ管理**          | figma.com/file/XXXXX?node-id=4  | 追加/Edit/Delete・カラーパレット・単位入力・並べ替え(Drag)                                  |
| **SCR-HIST**    | **履歴 & グラフ**        | figma.com/file/XXXXX?node-id=5  | 日付レンジPicker・グラフ種(Line/Bar/Heat)Toggle・**移動平均7/14/30** Chip・値リスト         |
| **SCR-GRAPH**   | グラフ設定エディタ           | figma.com/file/XXXXX?node-id=6  | 窓長 input・集計関数 Select・カテゴリ複数選択・保存                                        |
| **SCR-SET**     | **設定**              | figma.com/file/XXXXX?node-id=7  | 同期ON/OFF(Switch)・**バックアップ/リストア(zip)**・CSV出力・リマインダー時刻 List・ライセンス/GDPRリンク |
| **DIA-MERGE**   | 同期競合マージ             | figma.com/file/XXXXX?node-id=8  | 差分ハイライト・A/B選択 or 平均計算                                                   |
| **DIA-RATE**    | API利用量 / Rate-Limit | figma.com/file/XXXXX?node-id=9  | 残リクエスト数・リセット時間 Progress                                                 |
| **FLOW-BACKUP** | バックアップ作成ウィザード       | figma.com/file/XXXXX?node-id=10 | 進捗バー・保存先選択・完了Toast                                                      |
| **DIA-EXPORT**  | CSV/JSONエクスポート      | figma.com/file/XXXXX?node-id=11 | 日付範囲 Picker・フォーマット選択・サイズ表示                                              |

> **デザイントークン**  
> プライマリ #0061FF セカンダリ #FF6C00 背景 #F8F9FB フォント Roboto / SF Pro  
> コンポーネント角丸12dp、軽いシャドウ、ダークモードは動的カラー対応。
