import 'dart:async';
import 'dart:io';
import 'package:bargain/chat/Core%20Services/cdn_uploader.dart';
import 'package:bargain/chat/Core%20Services/chat_service.dart';
import 'package:bargain/chat/Core%20Services/message_repository.dart';
import 'package:bargain/chat/Models%20&%20Config/chat_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bargain/services/user_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final String conversationId;
  final String receiverId;

  StreamSubscription<ChatMessage>? _messageSubscription;

  ChatBloc({
    required this.conversationId,
    required this.receiverId,
  }) : super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendMediaMessage>(_onSendMediaMessage);
    on<IncomingMessage>(_onIncomingMessage);

    _messageSubscription = ChatService.instance.messageStream.listen((message) {
      if (message.conversationId == conversationId) {
        add(IncomingMessage(message));
      }
    });
  }

  Future<void> _onLoadMessages(LoadMessages event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    final messages = await MessageRepository.instance.getMessages(conversationId);
    emit(ChatLoaded(messages: messages));
  }

  Future<void> _onSendTextMessage(SendTextMessage event, Emitter<ChatState> emit) async {
    final senderId = UserService().currentUser?.uid;
    if (senderId == null) return;

    final tmpId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    final message = ChatMessage(
      id: tmpId,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      text: event.text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    await MessageRepository.instance.sendMessage(message);
  }

  Future<void> _onSendMediaMessage(SendMediaMessage event, Emitter<ChatState> emit) async {
    final senderId = UserService().currentUser?.uid;
    if (senderId == null) return;

    final mime = CdnUploader.detectMime(event.file);
    final signedInfo = await ChatService.instance.getSignedInfo();
    final uploadedUrl = await CdnUploader.uploadFile(
      file: event.file,
      mime: mime,
      signedInfo: signedInfo,
    );
    if (uploadedUrl == null) return;

    final tmpId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    final message = ChatMessage(
      id: tmpId,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      imageUrl: event.type == MediaType.image ? uploadedUrl : null,
      videoUrl: event.type == MediaType.video ? uploadedUrl : null,
      audioUrl: event.type == MediaType.audio ? uploadedUrl : null,
    );

    await MessageRepository.instance.sendMessage(message);
  }

  void _onIncomingMessage(IncomingMessage event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final current = (state as ChatLoaded).messages;
      emit(ChatLoaded(messages: [event.message, ...current]));
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
