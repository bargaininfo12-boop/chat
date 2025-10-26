// v1.0-chat_bloc · 2025-10-25T10:45 IST
// chat_bloc.dart (fixed: final fields initialization + typed casts)
//
// Notes:
// - Ensure you have these classes available with matching names:
//    - MessageRepository
//    - ChatDatabaseHelper
//    - WsMessageHandler
//    - WsAckHandler (with setOnRemoteInsert & setOnAckForTemp)
// - Ensure chat_database_helper.fetchMessagesForConversation returns Future<List<Map<String,dynamic>>>

import 'dart:async';
import 'dart:io';

import 'package:bargain/chat/services/chat_database_helper.dart';
import 'package:bargain/chat/services/ws_ack_handler.dart';
import 'package:bargain/chat/services/ws_message_handler.dart';
import 'package:bargain/chat/repository/message_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';


/// Events
abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadConversation extends ChatEvent {
  final String conversationId;
  LoadConversation(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class SendText extends ChatEvent {
  final String conversationId;
  final String senderId;
  final String text;
  SendText({required this.conversationId, required this.senderId, required this.text});
  @override
  List<Object?> get props => [conversationId, senderId, text];
}

class SendMedia extends ChatEvent {
  final String conversationId;
  final String senderId;
  final File file;
  final String mime;
  SendMedia({required this.conversationId, required this.senderId, required this.file, required this.mime});
  @override
  List<Object?> get props => [conversationId, senderId, file.path, mime];
}

// Internal events
class _RemoteInserted extends ChatEvent {
  final Map<String, dynamic> payload;
  _RemoteInserted(this.payload);
  @override
  List<Object?> get props => [payload];
}

class _MessageAcked extends ChatEvent {
  final String tempId;
  final String serverId;
  _MessageAcked(this.tempId, this.serverId);
  @override
  List<Object?> get props => [tempId, serverId];
}

class _ProgressUpdated extends ChatEvent {
  final String tempId;
  final int progress;
  _ProgressUpdated(this.tempId, this.progress);
  @override
  List<Object?> get props => [tempId, progress];
}

/// States
abstract class ChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final String conversationId;
  final List<Map<String, dynamic>> messages; // oldest first
  ChatLoaded({required this.conversationId, required this.messages});
  @override
  List<Object?> get props => [conversationId, messages];
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Bloc
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  // final fields must be initialized via constructor
  final MessageRepository repo;
  final ChatDatabaseHelper localDb;
  final WsMessageHandler wsMessageHandler;
  final WsAckHandler wsAckHandler;

  StreamSubscription? _pollSub;

  ChatBloc({
    required this.repo,
    required this.localDb,
    required this.wsMessageHandler,
    required this.wsAckHandler,
  }) : super(ChatInitial()) {
    // register handlers
    on<LoadConversation>(_onLoadConversation);
    on<SendText>(_onSendText);
    on<SendMedia>(_onSendMedia);
    on<_RemoteInserted>(_onRemoteInserted);
    on<_MessageAcked>(_onMessageAcked);
    on<_ProgressUpdated>(_onProgressUpdated);

    // register ws ack callbacks via setters (wsAckHandler exposes setOnRemoteInsert and setOnAckForTemp)
    wsAckHandler.setOnRemoteInsert((row) {
      add(_RemoteInserted(row));
    });

    wsAckHandler.setOnAckForTemp((tempId, serverId) {
      add(_MessageAcked(tempId, serverId));
    });

    // Start handlers if not started elsewhere (defensive)
    try {
      wsMessageHandler.start();
    } catch (_) {}
    try {
      wsAckHandler.start();
    } catch (_) {}
  }

  // ---------------- Handlers ----------------

  Future<void> _onLoadConversation(LoadConversation ev, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      final raw = await localDb.fetchMessagesForConversation(ev.conversationId, limit: 500);
      final List<Map<String, dynamic>> rows = raw.cast<Map<String, dynamic>>();
      emit(ChatLoaded(conversationId: ev.conversationId, messages: rows));

      // periodic refresh (lightweight). Replace with DB listener for better perf.
      _pollSub?.cancel();
      _pollSub = Stream.periodic(const Duration(seconds: 1)).listen((_) async {
        final latestRaw = await localDb.fetchMessagesForConversation(ev.conversationId, limit: 500);
        final List<Map<String, dynamic>> latest = latestRaw.cast<Map<String, dynamic>>();
        final current = state is ChatLoaded ? (state as ChatLoaded).messages : <Map<String, dynamic>>[];
        if (!_listEqualsById(current, latest)) {
          add(_RemoteInserted({'_bulk': true, 'rows': latest}));
        }
      });
    } catch (e) {
      emit(ChatError('Failed to load conversation: $e'));
    }
  }

  Future<void> _onSendText(SendText ev, Emitter<ChatState> emit) async {
    try {
      await repo.sendTextMessage(conversationId: ev.conversationId, senderId: ev.senderId, text: ev.text);
      // repo writes to DB; poller picks up changes
    } catch (e) {
      // optional: log or emit an error state
    }
  }

  Future<void> _onSendMedia(SendMedia ev, Emitter<ChatState> emit) async {
    try {
      await repo.sendMediaMessage(conversationId: ev.conversationId, senderId: ev.senderId, file: ev.file, mime: ev.mime);
    } catch (e) {
      // optional handling
    }
  }

  Future<void> _onRemoteInserted(_RemoteInserted ev, Emitter<ChatState> emit) async {
    final payload = ev.payload;
    // bulk refresh
    if (payload.containsKey('_bulk') && payload['_bulk'] == true) {
      final dynamic rowsDynamic = payload['rows'];
      final List<Map<String, dynamic>> rows = (rowsDynamic is List) ? rowsDynamic.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
      if (state is ChatLoaded) {
        final conv = (state as ChatLoaded).conversationId;
        emit(ChatLoaded(conversationId: conv, messages: rows));
      } else {
        final cid = rows.isNotEmpty ? (rows.first['conversationId'] as String? ?? '') : '';
        emit(ChatLoaded(conversationId: cid, messages: rows));
      }
      return;
    }

    // single insert
    final Map<String, dynamic> row = payload;
    final convId = row['conversationId'] as String?;
    if (state is ChatLoaded) {
      final cur = state as ChatLoaded;
      if (convId != null && convId == cur.conversationId) {
        final updated = List<Map<String, dynamic>>.from(cur.messages)..add(row);
        emit(ChatLoaded(conversationId: cur.conversationId, messages: updated));
        return;
      }
    }

    // if not current, reload typed rows from DB
    final String conv = convId ?? (row['conversationId'] as String? ?? '');
    final raw = await localDb.fetchMessagesForConversation(conv, limit: 500);
    final List<Map<String, dynamic>> rows = raw.cast<Map<String, dynamic>>();
    emit(ChatLoaded(conversationId: conv, messages: rows));
  }

  Future<void> _onMessageAcked(_MessageAcked ev, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final cur = state as ChatLoaded;
      final updated = cur.messages.map((m) {
        if (m['tempId'] == ev.tempId) {
          final copy = Map<String, dynamic>.from(m);
          copy['serverId'] = ev.serverId;
          copy['status'] = 'sent';
          return copy;
        }
        return m;
      }).toList();
      emit(ChatLoaded(conversationId: cur.conversationId, messages: updated));
    }
  }

  Future<void> _onProgressUpdated(_ProgressUpdated ev, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final cur = state as ChatLoaded;
      final updated = cur.messages.map((m) {
        if (m['tempId'] == ev.tempId) {
          final copy = Map<String, dynamic>.from(m);
          copy['uploadProgress'] = ev.progress;
          copy['status'] = ev.progress >= 100 ? (copy['status'] ?? 'sent_optimistic') : 'uploading';
          return copy;
        }
        return m;
      }).toList();
      emit(ChatLoaded(conversationId: cur.conversationId, messages: updated));
    }
  }

  // ---------------- Utilities ----------------

  bool _listEqualsById(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      final aid = a[i]['serverId'] ?? a[i]['tempId'];
      final bid = b[i]['serverId'] ?? b[i]['tempId'];
      if (aid != bid) return false;
    }
    return true;
  }

  @override
  Future<void> close() async {
    await _pollSub?.cancel();
    try {
      await wsMessageHandler.stop();
    } catch (_) {}
    try {
      await wsAckHandler.stop();
    } catch (_) {}
    return super.close();
  }
}
