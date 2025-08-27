from django.contrib import admin
from django.urls import include, path

from . import views

urlpatterns = [
    # ヘルスチェック用のエンドポイントを追加
    path("health/", views.health_check, name="health_check"),
    path("polls/", include("polls.urls")),
    path("admin/", admin.site.urls),
]
