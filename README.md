## 概要

Python, Djangoで構築されたシンプルな投票アプリ

## ディレクトリ構成

```text
.  
├── .github/  
├── apps/  
│   └── polls/  
│       ├── migrations/  
│       ├── static/  
│       ├── templates/  
│       ├── tests/  
│       ├── admin.py  
│       ├── apps.py  
│       ├── models.py  
│       ├── urls.py  
│       └── views.py  
├── nginx/  
├── polls-site/  
│   ├── asgi.py  
│   ├── settings.py  
│   ├── urls.py  
│   └── wsgi.py  
├── .env.example  
├── docker-compose.yml  
├── Dockerfile  
├── manage.py  
├── poetry.lock  
└── pyproject.toml
```

## **主な機能**

* **投票機能**: 質問に対して複数の選択肢から投票できます。  
* **結果表示**: 各質問の投票結果を閲覧できます。  
* **質問管理**: Django Adminサイトから質問や選択肢を追加・編集・削除できます。

## **技術スタック**

* **バックエンド**: Django  
* **データベース**: PostgreSQL  
* **Webサーバー**: Nginx, Gunicorn  
* **パッケージ管理**: Poetry  
* **コンテナ**: Docker, Docker Compose  
* **CI/CD**: GitHub Actions  
* **フォーマッター/リンター**: Black, Ruff

## **セットアップ手順**

1. **.envファイルの作成**  
   .env.exampleを参考に.envファイルを作成
   `$ cp .env.example .env`

2. **Dockerコンテナのビルドと起動**  
   以下のコマンドを実行して、Dockerコンテナをビルドし、バックグラウンドで起動 
   `$ docker-compose up --build -d`

3. **データベースのマイグレーション**  
   次のコマンドでデータベースのマイグレーションを実行
   `$ docker-compose exec web poetry run python manage.py migrate`

4. **管理者ユーザーの作成**  
   Django Adminにログインするための管理者ユーザーを作成
   `$ docker-compose exec web poetry run python manage.py createsuperuser`
