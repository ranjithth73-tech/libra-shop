from rest_framework import viewsets, filters, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from .models import Category, Product
from .serializer import (
    CategorySerializer,
    ProductListSerializer,
    ProductDetailSerializer,
)
from .filters import ProductFilter

# Create your views here.


class CategoryViewSet(viewsets.ModelViewSet):
    """
    list:   GET  /api/categories/       — list all categories
    create: POST /api/categories/       — create category (admin only)
    retrieve: GET /api/categories/{id}/ — single category
    """

    queryset = Category.objects.all()
    serializer_class = CategorySerializer

    def get_permissions(self):
        if self.action in ["list", "retrieve"]:
            return [permissions.AllowAny()]
        return [permissions.IsAdminUser()]


class ProductViewSet(viewsets.ModelViewSet):
    """
    list:     GET /api/products/              — list products (paginated)
    retrieve: GET /api/products/{id}/         — single product detail

    ## Filtering
    - ?search=nike                → search by name or description
    - ?min_price=100&max_price=500 → filter by price range
    - ?category=1                 → filter by category id
    - ?in_stock=true              → only in-stock products
    - ?ordering=price             → sort ascending
    - ?ordering=-price            → sort descending
    - ?page=2                     → page 2 of results
    """

    queryset = Product.objects.filter(is_active=True).select_related("category")
    filter_backends = [
        DjangoFilterBackend,
        filters.SearchFilter,
        filters.OrderingFilter,
    ]

    filterset_class = ProductFilter
    search_fields = ["name", "description"]
    ordering_fields = ["price", "created_at", "name"]
    ordering = ["-created_at"]

    def get_serializer_class(self):
        if self.action == "list":
            return ProductListSerializer
        return ProductDetailSerializer

    def get_permissions(self):
        if self.action in ["list", "retrieve"]:
            return [permissions.AllowAny()]
        return [permissions.IsAdminUser()]

    @action(
        detail=False, methods=["get"], url_path="by-category/(?P<category_id>[^/.]+)"
    )
    def by_category(self, request, category_id=None):
        products = self.get_queryset().filter(category__id=category_id)
        page = self.paginate_queryset(products)
        if page is not None:
            serializer = ProductListSerializer(page, many=True, context={"request": request})
            return self.get_paginated_response(serializer.data)
        serializer = ProductListSerializer(products, many=True, context={"request": request})
        return Response(serializer.data)
