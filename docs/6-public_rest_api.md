# 6. 公開REST API (OpenAPI 3 抜粋)

```yaml
openapi: 3.1.0
info:
  title: DailyLogger API
  version: 1.0.0
  description: |
    Offline-first personal logging service.
servers:
  - url: https://api.dailylogger.app/v1
    description: Production
  - url: https://stg.api.dailylogger.app/v1
    description: Staging

security:
  - bearerAuth: []

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  parameters:
    Page:
      in: query
      name: page
      schema: { type: integer, minimum: 1, default: 1 }
    PerPage:
      in: query
      name: per_page
      schema: { type: integer, minimum: 1, maximum: 100, default: 20 }

  responses:
    Error400:
      description: Bad Request
      content:
        application/json:
          schema: { $ref: '#/components/schemas/Error' }
    Error401:
      description: Unauthorized
      content:
        application/json:
          schema: { $ref: '#/components/schemas/Error' }
    # … 404, 429, 500 同様に定義

  schemas:
    Error:
      type: object
      required: [code, message]
      properties:
        code: { type: integer, example: 4001 }
        message: { type: string, example: "Invalid parameter" }
        details: { type: object }

    CategoryIn:  # （現行と同じ、省略）
    EntryIn:     # （省略）

paths:
  /auth/login:
    post:
      tags: [Auth]
      summary: JWT ログイン
      requestBody:
        content:
          application/json:
            schema:
              type: object
              required: [email, password]
              properties:
                email: { type: string, format: email }
                password: { type: string, format: password }
      responses:
        '200':
          description: Login Success
          content:
            application/json:
              schema:
                type: object
                properties:
                  access_token: { type: string }
                  refresh_token: { type: string }
        '400': { $ref: '#/components/responses/Error400' }

  /auth/refresh:
    post:
      tags: [Auth]
      summary: アクセストークン再発行
      requestBody:
        content:
          application/json:
            schema:
              type: object
              required: [refresh_token]
              properties:
                refresh_token: { type: string }
      responses:
        '200':
          description: Token pair
          content:
            application/json:
              schema:
                type: object
                properties:
                  access_token: { type: string }
                  refresh_token: { type: string }

  /categories:
    get:
      tags: [Category]
      summary: カテゴリ一覧取得
      parameters: [ { $ref: '#/components/parameters/Page' },
                    { $ref: '#/components/parameters/PerPage' } ]
      responses:
        '200':
          description: Category list
          content:
            application/json:
              schema:
                type: object
                properties:
                  items:
                    type: array
                    items: { $ref: '#/components/schemas/CategoryIn' }
                  total: { type: integer }
        '401': { $ref: '#/components/responses/Error401' }

    post:
      tags: [Category]
      summary: カテゴリ作成
      requestBody:
        content:
          application/json:
            schema: { $ref: '#/components/schemas/CategoryIn' }
      responses:
        '201':
          description: Created
          content:
            application/json:
              schema: { $ref: '#/components/schemas/CategoryIn' }

  /categories/{id}:
    parameters:
      - in: path
        name: id
        required: true
        schema: { type: string, format: uuid }
    put:  # 全更新
      summary: カテゴリ更新
    patch:  # 部分更新
      summary: カテゴリの一部更新
    delete:
      summary: カテゴリ削除
      responses:
        '204': { description: No Content }

  /entries:
    get:
      tags: [Entry]
      summary: エントリ一覧
      parameters:
        - $ref: '#/components/parameters/Page'
        - $ref: '#/components/parameters/PerPage'
        - in: query
          name: category_id
          schema: { type: string, format: uuid }
        - in: query
          name: from
          schema: { type: string, format: date-time }
        - in: query
          name: to
          schema: { type: string, format: date-time }
    post:
      summary: エントリ一括作成
      requestBody:
        content:
          application/json:
            schema:
              type: array
              items: { $ref: '#/components/schemas/EntryIn' }

  /entries/{id}:
    parameters:
      - name: id
        in: path
        required: true
        schema: { type: string, format: uuid }
    put:
      summary: エントリ全更新
    patch:
      summary: エントリの一部更新
    delete:
      summary: エントリ削除
      responses:
        '204': { description: No Content }

  /export/csv:
    get:
      tags: [Export]
      summary: CSV エクスポート
      parameters:
        - in: query
          name: from
          required: true
          schema: { type: string, format: date }
        - in: query
          name: to
          required: true
          schema: { type: string, format: date }
      responses:
        '200':
          description: CSV file
          content:
            text/csv:
              schema: { type: string, format: binary }

  /healthz:
    get:
      tags: [Ops]
      summary: Liveness Probe
      security: []  # no-auth
  /readyz:
    get:
      tags: [Ops]
      summary: Readiness Probe
      security: []  # no-auth
```
