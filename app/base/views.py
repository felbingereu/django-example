from django.http import HttpRequest, JsonResponse
from django.shortcuts import render


def manifest(request: HttpRequest) -> JsonResponse:
    return JsonResponse(
        {
            "name": "Example for Django",
            "short_name": "Django example",
            "display": "standalone",
        }
    )
