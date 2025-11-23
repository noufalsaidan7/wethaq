import 'package:flutter_test/flutter_test.dart';

/// نموذج رسالة محادثة (يشبه JSON اللي يرجع من PHP)
class ChatMessage {
  final int id;
  final int staffUserId;
  final int parentUserId;
  final int childId;
  final String body;
  final String senderRole; // 'Staff' أو 'Parent'
  final int? replyToMessageId;
  final String? replyPreview;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.staffUserId,
    required this.parentUserId,
    required this.childId,
    required this.body,
    required this.senderRole,
    required this.createdAt,
    this.replyToMessageId,
    this.replyPreview,
  });
}

/// محاكاة لسيرفر PHP الخاص بالمحادثة:
/// send_message.php
/// list_messages.php
/// delete_message.php
class MockChatApi {
  int _nextId = 1;
  final List<ChatMessage> _messages = [];

  /// يحاكي send_message.php
  ChatMessage sendMessage({
    required int staffUserId,
    required int parentUserId,
    required int childId,
    required String body,
    required String senderRole,
    int? replyToMessageId,
  }) {
    String? replyPreview;

    if (replyToMessageId != null) {
      final original = _messages
          .where((m) => m.id == replyToMessageId)
          .cast<ChatMessage?>()
          .firstWhere((m) => m != null, orElse: () => null);
      if (original != null) {
        replyPreview = original.body.length > 50
            ? original.body.substring(0, 50)
            : original.body;
      }
    }

    final msg = ChatMessage(
      id: _nextId++,
      staffUserId: staffUserId,
      parentUserId: parentUserId,
      childId: childId,
      body: body,
      senderRole: senderRole,
      replyToMessageId: replyToMessageId,
      replyPreview: replyPreview,
      createdAt: DateTime.now(),
    );

    _messages.add(msg);
    return msg;
  }

  /// يحاكي list_messages.php
  List<ChatMessage> listMessages({
    required int staffUserId,
    required int parentUserId,
    required int childId,
  }) {
    final result = _messages.where((m) {
      return m.staffUserId == staffUserId &&
          m.parentUserId == parentUserId &&
          m.childId == childId;
    }).toList();

    // ترتيب حسب وقت الإنشاء (أقدم -> أحدث)
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  /// يحاكي delete_message.php
  bool deleteMessage(int messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return false;
    _messages.removeAt(index);
    return true;
  }

  int get totalMessagesCount => _messages.length;
}

void main() {
  group('MockChatApi basic operations', () {
    late MockChatApi api;

    setUp(() {
      api = MockChatApi();
    });

    test('إرسال رسالة واحدة يزيد العداد ويحفظ نفس البيانات', () {
      final msg = api.sendMessage(
        staffUserId: 10,
        parentUserId: 20,
        childId: 30,
        body: 'Hello from parent',
        senderRole: 'Parent',
      );

      expect(api.totalMessagesCount, 1);
      expect(msg.id, 1);
      expect(msg.body, 'Hello from parent');
      expect(msg.senderRole, 'Parent');
      expect(msg.replyToMessageId, isNull);
    });

    test('إرسال أكثر من رسالة يعطي IDs متزايدة', () {
      final m1 = api.sendMessage(
        staffUserId: 1,
        parentUserId: 2,
        childId: 3,
        body: 'First',
        senderRole: 'Parent',
      );
      final m2 = api.sendMessage(
        staffUserId: 1,
        parentUserId: 2,
        childId: 3,
        body: 'Second',
        senderRole: 'Staff',
      );

      expect(m1.id, 1);
      expect(m2.id, 2);
      expect(api.totalMessagesCount, 2);
    });

    test('listMessages يرجع فقط رسائل نفس المحادثة', () {
      // محادثة 1
      api.sendMessage(
        staffUserId: 10,
        parentUserId: 20,
        childId: 30,
        body: 'Msg 1',
        senderRole: 'Parent',
      );
      api.sendMessage(
        staffUserId: 10,
        parentUserId: 20,
        childId: 30,
        body: 'Msg 2',
        senderRole: 'Staff',
      );

      // محادثة مختلفة
      api.sendMessage(
        staffUserId: 99,
        parentUserId: 88,
        childId: 77,
        body: 'Other chat',
        senderRole: 'Parent',
      );

      final list = api.listMessages(
        staffUserId: 10,
        parentUserId: 20,
        childId: 30,
      );

      expect(list.length, 2);
      expect(list[0].body, 'Msg 1');
      expect(list[1].body, 'Msg 2');
    });

    test('deleteMessage يحذف الرسالة من القائمة', () {
      final m1 = api.sendMessage(
        staffUserId: 1,
        parentUserId: 2,
        childId: 3,
        body: 'To be deleted',
        senderRole: 'Parent',
      );
      api.sendMessage(
        staffUserId: 1,
        parentUserId: 2,
        childId: 3,
        body: 'Another',
        senderRole: 'Staff',
      );

      final ok = api.deleteMessage(m1.id);

      expect(ok, isTrue);
      expect(api.totalMessagesCount, 1);

      final list = api.listMessages(
        staffUserId: 1,
        parentUserId: 2,
        childId: 3,
      );
      expect(list.length, 1);
      expect(list[0].body, 'Another');
    });

    test('replyToMessageId و replyPreview يتم تعبيتها عند الرد على رسالة',
        () async {
      final original = api.sendMessage(
        staffUserId: 1,
        parentUserId: 2,
        childId: 3,
        body: 'This is the original long message body',
        senderRole: 'Parent',
      );

      final reply = api.sendMessage(
        staffUserId: 1,
        parentUserId: 2,
        childId: 3,
        body: 'Reply message here',
        senderRole: 'Staff',
        replyToMessageId: original.id,
      );

      expect(reply.replyToMessageId, original.id);
      expect(reply.replyPreview, isNotNull);
      expect(reply.replyPreview, contains('original'));
    });
  });
}
