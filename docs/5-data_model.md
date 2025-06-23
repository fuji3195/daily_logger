# 5. データモデル (SQL例)

```sql
/*-----------------------------------------------------------
  0. 前提：ユーザーテーブル（参考）
-----------------------------------------------------------*/
CREATE TABLE users (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email       TEXT UNIQUE NOT NULL,
  password_h  TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

/*-----------------------------------------------------------
  1. Unit マスタ  ― 係数 + オフセットで基準単位へ変換
-----------------------------------------------------------*/
CREATE TABLE unit_master (
  id        SERIAL PRIMARY KEY,
  name      TEXT UNIQUE NOT NULL,     -- 表示用: 'kg', 'lbs', 'celsius'
  base_name TEXT NOT NULL,            -- グループ共通基準: 'kg', 'celsius'
  factor    NUMERIC NOT NULL,         -- 変換係数
  offset    NUMERIC DEFAULT 0         -- 温度などオフセット
);
/* 例データ
INSERT INTO unit_master (name, base_name, factor, offset) VALUES
 ('kg',        'kg',        1,       0),
 ('lbs',       'kg',        0.453592,0),
 ('celsius',   'celsius',   1,       0),
 ('fahrenheit','celsius',   0.5556, -17.7778);
*/

/*-----------------------------------------------------------
  2. Category  ― ユーザー定義の計測項目
-----------------------------------------------------------*/
CREATE TABLE category (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  unit_id      INT  NOT NULL REFERENCES unit_master(id),
  color_hex    CHAR(7) DEFAULT '#0061FF',
  period_type  TEXT CHECK (period_type IN ('hourly','daily','weekly','irregular'))
                      DEFAULT 'daily',
  created_at   TIMESTAMPTZ DEFAULT now(),
  updated_at   TIMESTAMPTZ DEFAULT now(),
  UNIQUE (user_id, name)
);

/*-----------------------------------------------------------
  3. Entry  ― 実データ本体（数値／テキスト／真偽値に対応）
-----------------------------------------------------------*/
CREATE TABLE entry (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category_id   UUID NOT NULL REFERENCES category(id) ON DELETE CASCADE,
  ts            TIMESTAMPTZ NOT NULL,
  value_num     NUMERIC(18,4),
  value_text    TEXT,
  value_bool    BOOLEAN,
  /* スナップショット列（カテゴリ設定変更後も表示を維持） */
  unit_name     TEXT,     -- 例: 'kg'
  color_hex     CHAR(7),
  memo          TEXT,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now(),
  CHECK (value_num IS NOT NULL
         OR value_text IS NOT NULL
         OR value_bool IS NOT NULL)
);

/*-----------------------------------------------------------
  4. Graph Definition  ― ユーザーが保存するグラフ設定
-----------------------------------------------------------*/
CREATE TABLE graph_definition (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT,
  type          TEXT CHECK (type IN ('line','bar','heatmap')),
  agg_func      TEXT CHECK (agg_func IN ('avg','sum','min','max')),
  window_days   SMALLINT DEFAULT 7,   -- 7,14,30…  クエリで上書き可
  bucket_days   SMALLINT DEFAULT 1,   -- 集計粒度（日）
  category_ids  UUID[]   NOT NULL
);

/*-----------------------------------------------------------
  5. Reminder  ― デイリー通知
-----------------------------------------------------------*/
CREATE TABLE reminder (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  hour      SMALLINT CHECK (hour BETWEEN 0 AND 23),
  minute    SMALLINT CHECK (minute BETWEEN 0 AND 59),
  enabled   BOOLEAN DEFAULT TRUE,
  UNIQUE (user_id, hour, minute)
);

/*-----------------------------------------------------------
  6. Sync Queue  ― オフライン差分同期用
-----------------------------------------------------------*/
CREATE TABLE sync_queue (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID,
  endpoint    TEXT,
  payload     JSONB,
  retry_count INT  DEFAULT 0,
  last_error  TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

/*-----------------------------------------------------------
  7. インデックス
-----------------------------------------------------------*/
CREATE INDEX idx_entry_cat_ts  ON entry(user_id, category_id, ts DESC);
CREATE INDEX idx_entry_ts      ON entry(ts DESC);
CREATE INDEX idx_sync_retry    ON sync_queue(retry_count, created_at);

/*-----------------------------------------------------------
  8. 移動平均ビュー（プリセット 7 / 14 / 30 日）
     TimescaleDB を使用しない場合は pg_cron 等で定期 REFRESH
-----------------------------------------------------------*/
CREATE MATERIALIZED VIEW entry_avg_7d  AS
SELECT user_id, category_id,
       date_trunc('day', ts) AS day,
       avg(value_num) AS avg_7d
FROM entry
WHERE ts > now() - INTERVAL '7 days'
GROUP BY 1,2,3;

CREATE MATERIALIZED VIEW entry_avg_14d AS
SELECT user_id, category_id,
       date_trunc('day', ts) AS day,
       avg(value_num) AS avg_14d
FROM entry
WHERE ts > now() - INTERVAL '14 days'
GROUP BY 1,2,3;

CREATE MATERIALIZED VIEW entry_avg_30d AS
SELECT user_id, category_id,
       date_trunc('day', ts) AS day,
       avg(value_num) AS avg_30d
FROM entry
WHERE ts > now() - INTERVAL '30 days'
GROUP BY 1,2,3;


```
