from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import Cart, CartItem, Order, OrderItem
from .serializer import (
    CartSerializer,
    CartItemSerializer,
    PlaceOrderSerializer,
    OrderSerializer,
)
from products.models import Product

# Create your views here.


class CartViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    def get_or_create_cart(self, user):
        cart, created = Cart.objects.get_or_create(user=user)
        return cart

    def list(self, request):
        cart = self.get_or_create_cart(request.user)
        serializer = CartSerializer(cart)
        return Response(serializer.data)

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

        return Response(CartSerializer(cart).data, status=status.HTTP_200_OK)

    @action(detail=False, methods=["patch"], url_path="update/(?P<item_id>[^/.]+)")
    def update_item(self, request, item_id=None):
        cart = self.get_or_create_cart(request.user)
        cart_item = get_object_or_404(CartItem, id=item_id, cart=cart)
        quantity = request.data.get("quantity")

        if not quantity or int(quantity) < 1:
            return Response(
                {"error": "Quantity must be at least 1"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        cart_item.quantity = int(quantity)
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
        orders = Order.objects.filter(user=request.user)
        serializer = OrderSerializer(orders, many=True)
        return Response(serializer.data)

    def retrieve(self, request, pk=None):
        order = get_object_or_404(Order, id=pk, user=request.user)
        serializer = OrderSerializer(order)
        return Response(serializer.data)

    @action(detail=False, methods=["post"], url_path="place")
    def place_order(self, request):
        serializer = PlaceOrderSerializer(
            data=request.data, context={"request": request}
        )

        serializer.is_valid(raise_exception=True)

        cart = request.user.cart

        for cart_item in cart.items.select_related("product"):
            if cart_item.product.stock < cart_item.quantity:
                return Response(
                    {"error": f"Not enough stock for {cart_item.product.name}"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        order = Order.objects.create(
            user=request.user,
            shipping_address=serializer.validated_data["shipping_address"],
            total_price=cart.total_price,
        )

        for cart_item in cart.items.select_related("product"):
            OrderItem.objects.create(
                order=order,
                product=cart_item.product,
                product_name=cart_item.product.name,
                product_price=cart_item.product.price,
                quantity=cart_item.quantity,
            )

        for cart_item in cart.items.select_related("product"):
            product = cart_item.product
            product.stock -= cart_item.quantity
            product.save()

        cart.items.all().delete()

        return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)
