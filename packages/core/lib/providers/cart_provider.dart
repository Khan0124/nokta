import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
// Import for PaymentStatus

class CartState {
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double total;
  final String? notes;
  final String? specialInstructions;

  const CartState({
    this.items = const [],
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.deliveryFee = 0.0,
    this.total = 0.0,
    this.notes,
    this.specialInstructions,
  });

  CartState copyWith({
    List<CartItem>? items,
    double? subtotal,
    double? tax,
    double? deliveryFee,
    double? total,
    String? notes,
    String? specialInstructions,
  }) {
    return CartState(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  double get calculatedSubtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get calculatedTax {
    return calculatedSubtotal * 0.15; // 15% tax rate
  }

  double get calculatedDeliveryFee {
    return calculatedSubtotal > 50.0 ? 0.0 : 5.0; // Free delivery over $50
  }

  double get calculatedTotal {
    return calculatedSubtotal + calculatedTax + calculatedDeliveryFee;
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(Product product, {int quantity = 1, String? notes}) {
    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id && item.notes == notes,
    );

    if (existingIndex >= 0) {
      // Update existing item
      final existingItem = state.items[existingIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );

      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = updatedItem;

      state = state.copyWith(items: updatedItems);
    } else {
      // Add new item
      final newItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch,
        product: product,
        quantity: quantity,
        unitPrice: product.price,
        totalPrice: product.price * quantity,
        notes: notes,
      );

      state = state.copyWith(
        items: [...state.items, newItem],
      );
    }

    _updateTotals();
  }

  void removeItem(int itemId) {
    final updatedItems =
        state.items.where((item) => item.id != itemId).toList();
    state = state.copyWith(items: updatedItems);
    _updateTotals();
  }

  void updateItemQuantity(int itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          quantity: quantity,
          totalPrice: item.unitPrice * quantity,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
    _updateTotals();
  }

  void updateItemNotes(int itemId, String? notes) {
    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(notes: notes);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void addModifier(int itemId, CartItemModifier modifier) {
    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        final existingModifiers =
            List<CartItemModifier>.from(item.modifiers ?? []);
        existingModifiers.add(modifier);

        final newTotalPrice = item.unitPrice +
            existingModifiers.fold(0.0, (sum, m) => sum + m.price);

        return item.copyWith(
          modifiers: existingModifiers,
          totalPrice: newTotalPrice * item.quantity,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
    _updateTotals();
  }

  void removeModifier(int itemId, int modifierId) {
    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        final existingModifiers =
            item.modifiers?.where((m) => m.id != modifierId).toList() ?? [];

        final newTotalPrice = item.unitPrice +
            existingModifiers.fold(0.0, (sum, m) => sum + m.price);

        return item.copyWith(
          modifiers: existingModifiers,
          totalPrice: newTotalPrice * item.quantity,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
    _updateTotals();
  }

  void clearCart() {
    state = const CartState();
  }

  void updateNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void updateSpecialInstructions(String? specialInstructions) {
    state = state.copyWith(specialInstructions: specialInstructions);
  }

  void updateDeliveryFee(double deliveryFee) {
    state = state.copyWith(deliveryFee: deliveryFee);
    _updateTotals();
  }

  void _updateTotals() {
    final subtotal = state.calculatedSubtotal;
    final tax = state.calculatedTax;
    final deliveryFee = state.deliveryFee;
    final total = subtotal + tax + deliveryFee;

    state = state.copyWith(
      subtotal: subtotal,
      tax: tax,
      total: total,
    );
  }

  // Checkout functionality
  Future<Order> checkout({
    required int tenantId,
    required int branchId,
    required int customerId,
    required OrderType orderType,
    String? deliveryAddress,
    DateTime? scheduledTime,
    String? notes,
  }) async {
    // Create order from cart items
    final orderItems = state.items.map((cartItem) {
      return OrderItem(
        id: 0, // Will be set by database
        orderId: 0, // Will be set when adding to order
        productId: cartItem.product.id,
        quantity: cartItem.quantity,
        unitPrice: cartItem.unitPrice,
        totalPrice: cartItem.totalPrice,
        modifiers: cartItem.modifiers?.map((modifier) {
          return OrderItemModifier(
            id: 0,
            orderItemId: 0,
            modifierId: modifier.id,
            name: modifier.name,
            price: modifier.price,
          );
        }).toList(),
        notes: cartItem.notes,
      );
    }).toList();

    final order = Order(
      id: 0, // Will be set by database
      tenantId: tenantId,
      branchId: branchId,
      customerId: customerId,
      orderType: orderType,
      status: OrderStatus.pending,
      items: orderItems,
      subtotal: state.subtotal,
      tax: state.tax,
      deliveryFee: state.deliveryFee,
      total: state.total,
      paymentMethod: null, // Will be set during payment
      paymentStatus: PaymentStatus.pending,
      deliveryAddress: deliveryAddress,
      scheduledTime: scheduledTime,
      notes: notes ?? state.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Clear cart after successful checkout
    clearCart();

    return order;
  }

  // Update order after payment
  void updateOrderAfterPayment(Order order, PaymentMethod paymentMethod) {
    final updatedOrder = order.copyWith(
      paymentMethod: paymentMethod,
      paymentStatus: PaymentStatus.completed,
      updatedAt: DateTime.now(),
    );

    // Here you would typically save the updated order to the database
    // For now, we'll just clear the cart
    clearCart();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
