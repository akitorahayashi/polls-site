from django.http import JsonResponse


def health_check(request):
    """
    アプリケーションの稼働状態を返すシンプルなヘルスチェックビュー。
    """
    return JsonResponse({"status": "ok"})
