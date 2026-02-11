# ==============================
# 基本設定
# ==============================
ENV_FILE := .env
SRC_DIR := src

EXCLUDES := \
	--exclude '.git/' \
	--exclude '.github/' \
	--exclude 'wp-config.php' \
	--exclude 'wp-content/uploads/' \
	--exclude 'wp-content/cache/' \
	--exclude 'wp-content/debug.log'

RSYNC_BASE := rsync -av \
	-e "ssh -p $$SSH_PORT" \
	$(EXCLUDES)

# ==============================
# util
# ==============================
.PHONY: env-check
env-check:
	@test -f $(ENV_FILE) || (echo ".env が存在しません"; exit 1)

define load-env
	set -a; . $(ENV_FILE); set +a;
endef

define confirm
	@read -p "⚠️  $(1) 続行しますか？ [y/N]: " ans; \
	if [ "$$ans" != "y" ]; then echo "Abort."; exit 1; fi
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
