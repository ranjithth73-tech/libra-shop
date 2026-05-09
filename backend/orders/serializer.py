from rest_framework import serializers
from .models import Cart, CartItem, Order, OrderItem
from products.serializer import ProductListSerializer
from products.models import Product


class CartItemSerializer(serializers.ModelSerializer):
    product = ProductListSerializer(read_only=True)
    product_id = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.all(),
        source="product",
        write_only=True,
    )
    total_price = serializers.ReadOnlyField()

    class Meta:
        model = CartItem
        fields = ["id", "product", "product_id", "quantity", "total_price"]

    def validate_quantity(self, value):
        if value < 1:
            raise serializers.ValidationError("Quantity must be at least 1")
        return value


class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)
    total_price = serializers.ReadOnlyField()
    total_items = serializers.ReadOnlyField()

    class Meta:
        model = Cart
        fields = ["id", "items", "total_price", "total_items", "updated_at"]


class OrderItemSerializer(serializers.ModelSerializer):
    total_price = serializers.ReadOnlyField()

    class Meta:
        model = OrderItem
        fields = [
            "id",
            "product",
            "product_name",
            "product_price",
            "quantity",
            "total_price",
        ]


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    user_email = serializers.EmailField(source="user.email", read_only=True)

    class Meta:
        model = Order
        fields = [
            "id",
            "user_email",
            "status",
            "shipping_address",
            "total_price",
            "items",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["total_price", "status", "user_email"]


class PlaceOrderSerializer(serializers.Serializer):
    shipping_address = serializers.CharField()

    def validate(self, data):
        request = self.context["request"]
        try:
            cart = request.user.cart
        except Cart.DoesNotExist:
            raise serializers.ValidationError("You have no cart.")

        if not cart.items.exists():
            raise serializers.ValidationError("Your cart is empty")
        return data
