from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db import transaction
from .models import Cart, CartItem, Order, OrderItem
from .serializer import (
    CartSerializer,
    CartItemSerializer,
    PlaceOrderSerializer,
    OrderSerializer,
)


class CartViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    def get_or_create_cart(self, user):
        cart, _ = Cart.objects.get_or_create(user=user)
        return cart

    def list(self, request):
        cart = self.get_or_create_cart(request.user)
        return Response(CartSerializer(cart).data)

    def create(self, request):
        cart = self.get_or_create_cart(request.user)
        serializer = CartItemSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        product = serializer.validated_data["product"]
        quantity = serializer.validated_data["quantity"]

        cart_item, created = CartItem.objects.get_or_create(
            cart=cart, product=product, defaults={"quantity": quantity}
        )
        if not created:
            cart_item.quantity += quantity
            cart_item.save()

        response_status = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        return Response(CartSerializer(cart).data, status=response_status)

    @action(detail=False, methods=["patch"], url_path="update/(?P<item_id>[^/.]+)")
    def update_item(self, request, item_id=None):
        cart = self.get_or_create_cart(request.user)
        cart_item = get_object_or_404(CartItem, id=item_id, cart=cart)
        try:
            quantity = int(request.data.get("quantity", 0))
        except (TypeError, ValueError):
            quantity = 0

        if quantity < 1:
            return Response(
                {"error": "Quantity must be at least 1"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        cart_item.quantity = quantity
        cart_item.save()
        return Response(CartSerializer(cart).data)

    @action(detail=False, methods=["delete"], url_path="remove/(?P<item_id>[^/.]+)")
    def remove_item(self, request, item_id=None):
        cart = self.get_or_create_cart(request.user)
        cart_item = get_object_or_404(CartItem, id=item_id, cart=cart)
        cart_item.delete()
        return Response(CartSerializer(cart).data)

    @action(detail=False, methods=["delete"], url_path="clear")
    def clear(self, request):
        cart = self.get_or_create_cart(request.user)
        cart.items.all().delete()
        return Response({"message": "Cart cleared"})


class OrderViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    def list(self, request):
        orders = Order.objects.filter(user=request.user).prefetch_related("items")
        return Response(OrderSerializer(orders, many=True).data)

    def retrieve(self, request, pk=None):
        order = get_object_or_404(Order, id=pk, user=request.user)
        return Response(OrderSerializer(order).data)

    @action(detail=False, methods=["post"], url_path="place")
    @transaction.atomic
    def place_order(self, request):
        serializer = PlaceOrderSerializer(
            data=request.data, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)

        cart = request.user.cart
        cart_items = list(cart.items.select_related("product").select_for_update())

        # Validate stock in a single pass
        for cart_item in cart_items:
            if cart_item.product.stock < cart_item.quantity:
                return Response(
                    {"error": f"Not enough stock for '{cart_item.product.name}'"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        order = Order.objects.create(
            user=request.user,
            shipping_address=serializer.validated_data["shipping_address"],
            total_price=cart.total_price,
        )

        # Create order items and deduct stock in one pass
        order_items = []
        for cart_item in cart_items:
            order_items.append(OrderItem(
                order=order,
                product=cart_item.product,
                product_name=cart_item.product.name,
                product_price=cart_item.product.price,
                quantity=cart_item.quantity,
            ))
            cart_item.product.stock -= cart_item.quantity
            cart_item.product.save(update_fields=["stock"])

        OrderItem.objects.bulk_create(order_items)
        cart.items.all().delete()

        return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)
