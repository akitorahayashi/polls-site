# --- ベースイメージの指定 ---
# 公式のPython 3.12の軽量版イメージを土台として使用
FROM python:3.12-slim

# --- 環境変数の設定 ---
# Pythonが.pycバイトコードファイルを生成しないようにする
ENV PYTHONDONTWRITEBYTECODE=1
# 標準出力・標準エラー出力をバッファリングせず、ログをリアルタイムで表示
ENV PYTHONUNBUFFERED=1

# --- 作業ディレクトリの作成と設定 ---
WORKDIR /app

# --- 依存関係のインストール ---
RUN pip install pipx && pipx ensurepath && pipx install poetry

# Add pipx's bin directory to the PATH
ENV PATH="/root/.local/bin:${PATH}"

COPY poetry.lock pyproject.toml ./
RUN poetry config virtualenvs.create true \
    && poetry config virtualenvs.in-project true \
    && poetry install --no-root --no-dev

# --- アプリケーションコードのコピー ---
COPY . .

# --- ポートの開放 ---
EXPOSE 8000

# --- コンテナ起動コマンド ---
CMD ["gunicorn", "polls-site.wsgi:application", "--bind", "0.0.0.0:8000"]