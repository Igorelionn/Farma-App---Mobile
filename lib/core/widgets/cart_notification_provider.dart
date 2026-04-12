import 'package:flutter/material.dart';

class CartNotificationProvider extends InheritedWidget {
  final Function(String productName) onProductAdded;

  const CartNotificationProvider({
    super.key,
    required this.onProductAdded,
    required super.child,
  });

  static CartNotificationProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CartNotificationProvider>();
  }

  @override
  bool updateShouldNotify(CartNotificationProvider oldWidget) {
    return false;
  }
}
