FROM python:3.12-slim

# Pythonが.pycバイトコードファイルを生成しないようにする
ENV PYTHONDONTWRITEBYTECODE=1
# 標準出力・標準エラー出力をバッファリングせず、ログをリアルタイムで表示
ENV PYTHONUNBUFFERED=1

# 作業ディレクトリの作成
WORKDIR /app

# 依存関係のインストール
RUN pip install pipx && pipx install poetry
# Poetryの仮想環境をPATHに通す
ENV PATH="/root/.local/bin:${PATH}"

COPY poetry.lock pyproject.toml ./
RUN poetry config virtualenvs.create true \
    && poetry config virtualenvs.in-project true \
    && poetry install --no-root --only main

# アプリケーションコードのコピー
COPY . .

# ポートの開放
EXPOSE 8000

# コンテナを起動
CMD ["poetry", "run", "gunicorn", "polls-site.wsgi:application", "--bind", "0.0.0.0:8000"]