# XSERVER Simple Deploy

XSERVERへのシンプルなrsyncデプロイツール。

## 必要なもの

- rsync
- SSH鍵（Ed25519推奨）
- XSERVERのSSH接続設定

> **macOSユーザーへ**: 標準のopenrsync（v29）はXSERVERのrsync（v31）とプロトコル互換性がありません。`brew install rsync`でインストールし、Homebrew版が使われるようPATHを設定してください。

## セットアップ

### 1. SSH鍵の準備

```bash
# 鍵がなければ作成（パスフレーズは空のままEnter）
ssh-keygen -t ed25519 -C "your-email@example.com"

# 公開鍵を確認
cat ~/.ssh/id_ed25519.pub
```

> **注意**: GitHub Actionsで使用する場合、パスフレーズは設定しないでください。設定するとCI実行時に入力待ちで停止します。

### 2. XSERVERでSSH設定

1. サーバーパネル → SSH設定 → ONにする
2. 公開鍵登録 → `~/.ssh/id_ed25519.pub` の内容を登録

> **GitHub Actions使用時**: SSH設定で「国外アクセス制限」をOFFにしてください。GitHub ActionsはGitHubのサーバー（国外）から実行されるため、制限がONだと接続できません。

### 3. 環境変数の設定

```bash
cp .env.example .env
```

`.env` を編集:

```
SSH_HOST=sv12345.xserver.jp
SSH_PORT=10022
SSH_USER=youruser
DEPLOY_PATH=/home/youruser/example.com/public_html
```

### 4. 接続確認

```bash
make check
```

## 使い方

| コマンド | 説明 |
|---------|------|
| `make check` | SSH疎通確認 |
| `make diff` | 差分確認 |
| `make dry-push` | デプロイ内容の事前確認 |
| `make push` | ローカル → サーバー反映 |
| `make pull` | サーバー → ローカル取得 |
| `make serve` | ローカルサーバー起動 |
| `make stop` | ローカルサーバー停止 |
| `make clean` | Dockerリソース削除 |

### デプロイの流れ

```bash
# 1. 差分確認
make diff

# 2. ドライラン
make dry-push

# 3. 本番反映
make push
```

## GitHub Actionsでのデプロイ

### Secrets設定

リポジトリの Settings → Secrets and variables → Actions で以下を登録:

| Secret | 値 |
|--------|-----|
| `SSH_HOST` | sv12345.xserver.jp |
| `SSH_PORT` | 10022 |
| `SSH_USER` | youruser |
| `DEPLOY_PATH` | /home/youruser/example.com/public_html |
| `SSH_KEY` | 秘密鍵の内容（`cat ~/.ssh/id_ed25519`） |
| `SLACK_WEBHOOK_URL` | Slack通知用Webhook URL（任意） |

> **Slack Webhook取得方法**: [Slack App](https://api.slack.com/apps)を作成し、「Incoming Webhooks」からWebhook URLを取得してください。Slack Marketplace経由のLegacy Incoming Webhookは[将来廃止予定](https://api.slack.com/changelog/2024-09-legacy-custom-bots-classic-apps-deprecation)のため非推奨です。

### Variables設定（任意）

Slack通知にサービス名やURLを含める場合、Settings → Secrets and variables → Actions → Variables で登録:

| Variable | 値 |
|----------|-----|
| `SERVICE_NAME` | サービス名（例: My Website） |
| `DEPLOY_URL` | デプロイ先URL（例: https://example.com） |

### 手動実行

Actions → Manual Deploy to XSERVER → Run workflow

## ローカル開発

Dockerを使ってローカルで動作確認できます。

```bash
# サーバー起動（http://localhost:8080）
make serve

# サーバー停止
make stop

# 完全削除（イメージ、ボリューム含む）
make clean
```

## ディレクトリ構成

```
.
├── .env.example      # 環境変数テンプレート
├── .github/
│   ├── actions/
│   │   └── xserver-deploy/
│   │       └── action.yml
│   └── workflows/
│       ├── auto-deploy.yml
│       └── manual-deploy.yml
├── docker-compose.yml  # ローカル開発用
├── Makefile          # デプロイコマンド
├── README.md
└── src/              # デプロイ対象ディレクトリ
    └── index.html
```

## 除外ファイル

以下はデプロイ対象外:

- `.git/`
- `.github/`
- `.env`
- `.htaccess`
- `wp-config.php`
- `wp-content/uploads/`
- `wp-content/cache/`
- `wp-content/debug.log`

## サーバー側の環境変数

デプロイ時に`.env`と`.htaccess`は除外されるため、サーバー上の設定は上書きされません。

## 参考

- [GitHub ActionsでXServerに自動デプロイする - Qiita](https://qiita.com/ryotaro-fukushima/items/1dd00f318c521f9959f0)
- [GitHub Actionsとrsyncでデプロイを自動化する - greencider](https://greencd.jp/tech/github-actions-rsync-deploy/)
- [GitHub Actionsを使ってXServerなどレンタルサーバーに自動デプロイしよう - AndHA](https://and-ha.com/coding/github-action-deploy/)
- [XサーバーとGitHub Actionsを組み合わせて「手動アップロード」から卒業する話 - みろベース](https://miro-base.com/blog/xserver-auto-deploy/)
