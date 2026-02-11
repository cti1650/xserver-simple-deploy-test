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
# 鍵がなければ作成
ssh-keygen -t ed25519 -C "your-email@example.com"

# 公開鍵を確認
cat ~/.ssh/id_ed25519.pub
```

### 2. XSERVERでSSH設定

1. サーバーパネル → SSH設定 → ONにする
2. 公開鍵登録 → `~/.ssh/id_ed25519.pub` の内容を登録

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

### 手動実行

Actions → Manual Deploy to XSERVER → Run workflow

## ディレクトリ構成

```
.
├── .env.example    # 環境変数テンプレート
├── .github/
│   └── workflows/
│       ├── auto-deploy.yml
│       └── manual-deploy.yml
├── Makefile        # デプロイコマンド
├── README.md
└── src/            # デプロイ対象ディレクトリ
    └── index.html
```

## 除外ファイル

以下はデプロイ対象外:

- `.git/`
- `.github/`
- `wp-config.php`
- `wp-content/uploads/`
- `wp-content/cache/`
- `wp-content/debug.log`
