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
# pipxをインストールし、pipx経由でpoetryをインストール
RUN pip install pipx && pipx install poetry

# pipxの実行パスを環境変数に追加
ENV PATH="/root/.local/bin:${PATH}"

# poetry.lockとpyproject.tomlをコピー
COPY poetry.lock pyproject.toml ./
# Poetryの設定と依存関係のインストール
# --no-root: プロジェクト自体はインストールしない
# --only main: mainの依存関係のみインストール
RUN poetry config virtualenvs.create true \
    && poetry config virtualenvs.in-project true \
    && poetry install --no-root --only main

# Poetryの仮想環境をPATHに通す
ENV PATH="/app/.venv/bin:${PATH}"

# --- アプリケーションコードのコピー ---
COPY . .

# --- ポートの開放 ---
EXPOSE 8000

# --- コンテナ起動コマンド ---
CMD ["gunicorn", "polls-site.wsgi:application", "--bind", "0.0.0.0:8000"]