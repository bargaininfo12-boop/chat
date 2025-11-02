// v0.3-ws_event_model · 2025-10-25T05:22 IST
// ws_event_model.dart
//
// Lightweight typed wrapper for WS events.
// Use this or keep Map<String,dynamic> depending on preference.

class WsEvent {
  final String event;
  final Map<String, dynamic>? data;

  WsEvent({required this.event, this.data});

  factory WsEvent.fromMap(Map<String, dynamic> m) {
    return WsEvent(
      event: m['event'] as String? ?? '',
      data: (m['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toMap() => {
    'event': event,
    'data': data ?? {},
  };

  @override
  String toString() => 'WsEvent(event: $event, data: ${data?.keys.toList()})';
}
