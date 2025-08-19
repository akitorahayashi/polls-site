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
# 再現性のためバージョンを固定し、キャッシュ無効化でレイヤサイズを削減
RUN pip install --no-cache-dir pipx \
    && pipx install "poetry==1.8.3"

# poetry.lockとpyproject.tomlをコピー
COPY poetry.lock pyproject.toml ./

# Poetryの設定と依存関係のインストール
# RUNコマンド内で一時的にPATHを設定することで、後段のENVとまとめてレイヤを削減
RUN export PATH="/root/.local/bin:${PATH}" && \
    poetry config virtualenvs.create true && \
    poetry config virtualenvs.in-project true && \
    poetry install --no-root --without dev --no-interaction --no-ansi

# アプリケーション実行に必要なPATHをまとめて設定
ENV PATH="/app/.venv/bin:/root/.local/bin:${PATH}"

# --- アプリケーションコードのコピー ---
COPY . .

# --- ポートの開放 ---
EXPOSE 8000

# --- コンテナ起動コマンド ---
CMD ["gunicorn", "polls-site.wsgi:application", "--bind", "0.0.0.0:8000"]