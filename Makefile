# ==============================
# 基本設定
# ==============================
ENV_FILE := .env
SRC_DIR := src

EXCLUDES := --exclude-from=.rsyncignore

# Homebrew rsync を優先（macOS の openrsync はプロトコル互換性問題あり）
RSYNC_CMD := $(shell command -v /opt/homebrew/bin/rsync 2>/dev/null || command -v /usr/local/bin/rsync 2>/dev/null || echo rsync)

RSYNC_BASE := $(RSYNC_CMD) -av \
	-e "ssh -p $$SSH_PORT" \
	--rsync-path=/usr/bin/rsync \
	$(EXCLUDES)

# ==============================
# util
# ==============================
.PHONY: env-check
env-check:
	@if [ -z "$$SSH_HOST" ] && [ ! -f $(ENV_FILE) ]; then \
		echo ".env が存在しないか、環境変数が設定されていません"; exit 1; \
	fi

define load-env
	if [ -f $(ENV_FILE) ]; then set -a; . $(ENV_FILE); set +a; fi;
endef

define confirm
	@if [ "$$CI" != "true" ]; then \
		read -p "⚠️  $(1) 続行しますか？ [y/N]: " ans; \
		if [ "$$ans" != "y" ]; then echo "Abort."; exit 1; fi; \
	fi
endef

# ==============================
# help
# ==============================
.PHONY: help
help:
	@echo ""
	@echo "make check      SSH疎通確認"
	@echo "make diff       差分確認（push想定）"
	@echo "make dry-push   デプロイ内容の事前確認"
	@echo "make push       ローカル → サーバー反映"
	@echo "make pull       サーバー → ローカル取得"
	@echo "make serve      ローカルサーバー起動"
	@echo "make stop       ローカルサーバー停止"
	@echo "make clean      Dockerリソース削除"
	@echo ""

# ==============================
# commands
# ==============================
.PHONY: check
check: env-check
	@$(call load-env) \
	ssh -p $$SSH_PORT -o BatchMode=yes $$SSH_USER@$$SSH_HOST "echo OK"

.PHONY: diff
diff: env-check
	@$(call load-env) \
	$(RSYNC_BASE) --dry-run --itemize-changes \
	$(SRC_DIR)/ \
	$$SSH_USER@$$SSH_HOST:$$DEPLOY_PATH/

.PHONY: dry-push
dry-push: env-check
	@$(call load-env) \
	$(RSYNC_BASE) --dry-run --delete \
	$(SRC_DIR)/ \
	$$SSH_USER@$$SSH_HOST:$$DEPLOY_PATH/

.PHONY: push
push: env-check
	$(call confirm,サーバーへ反映します)
	@$(call load-env) \
	$(RSYNC_BASE) --delete \
	$(SRC_DIR)/ \
	$$SSH_USER@$$SSH_HOST:$$DEPLOY_PATH/

.PHONY: pull
pull: env-check
	$(call confirm,サーバー状態をローカルへ取得します)
	@$(call load-env) \
	$(RSYNC_BASE) \
	$$SSH_USER@$$SSH_HOST:$$DEPLOY_PATH/ \
	$(SRC_DIR)/

# ==============================
# local server
# ==============================
.PHONY: serve
serve:
	docker compose up -d
	@echo "http://localhost:8080"

.PHONY: stop
stop:
	docker compose down

.PHONY: clean
clean:
	docker compose down --rmi all --volumes --remove-orphans
