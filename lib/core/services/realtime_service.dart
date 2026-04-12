import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

typedef RealtimeCallback = void Function(Map<String, dynamic> payload);

class RealtimeService {
  static RealtimeChannel? _productsChannel;
  static final _productChangeController =
      StreamController<RealtimeProductEvent>.broadcast();

  static Stream<RealtimeProductEvent> get productChanges =>
      _productChangeController.stream;

  static void subscribeToProducts() {
    _productsChannel?.unsubscribe();

    _productsChannel = SupabaseService.client
        .channel('public:products')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          callback: (payload) {
            final event = RealtimeProductEvent(
              type: _mapEventType(payload.eventType),
              newRecord: payload.newRecord,
              oldRecord: payload.oldRecord,
            );
            _productChangeController.add(event);
          },
        )
        .subscribe();
  }

  static void unsubscribeFromProducts() {
    _productsChannel?.unsubscribe();
    _productsChannel = null;
  }

  static RealtimeEventType _mapEventType(PostgresChangeEvent event) {
    switch (event) {
      case PostgresChangeEvent.insert:
        return RealtimeEventType.insert;
      case PostgresChangeEvent.update:
        return RealtimeEventType.update;
      case PostgresChangeEvent.delete:
        return RealtimeEventType.delete;
      default:
        return RealtimeEventType.update;
    }
  }

  static void dispose() {
    unsubscribeFromProducts();
    _productChangeController.close();
  }
}

enum RealtimeEventType { insert, update, delete }

class RealtimeProductEvent {
  final RealtimeEventType type;
  final Map<String, dynamic> newRecord;
  final Map<String, dynamic> oldRecord;

  const RealtimeProductEvent({
    required this.type,
    required this.newRecord,
    required this.oldRecord,
  });
}
