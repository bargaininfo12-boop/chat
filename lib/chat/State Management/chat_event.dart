part of 'chat_bloc.dart';

abstract class ChatEvent {}

class LoadMessages extends ChatEvent {}

class SendTextMessage extends ChatEvent {
  final String text;
  SendTextMessage(this.text);
}

class SendMediaMessage extends ChatEvent {
  final File file;
  final MediaType type;
  SendMediaMessage({required this.file, required this.type});
}

class IncomingMessage extends ChatEvent {
  final ChatMessage message;
  IncomingMessage(this.message);
}
