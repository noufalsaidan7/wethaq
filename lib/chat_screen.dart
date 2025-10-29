import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

//const String baseUrl = 'http://192.168.1.28:8080/wethaq';

const String baseUrl = 'http://10.0.2.2/wethaq';

class ChatScreen extends StatefulWidget {
  final String role; // 'Staff' أو 'Parent'
  final int staffUserId;
  final int parentUserId;
  final int childId;
  final String peerName; // اسم الطرف الآخر (يظهر في العنوان)
  final String childName; // اسم الطفل (اختياري للعرض)

  const ChatScreen({
    super.key,
    required this.role,
    required this.staffUserId,
    required this.parentUserId,
    required this.childId,
    required this.peerName,
    required this.childName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const kGreen = Color(0xFF507C5C);
  static const kPanel = Color(0xFFE6F0EA);

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _loading = false;
  bool _sending = false;
  List<Map<String, dynamic>> _messages = [];

  // للرد على رسالة
  int? _replyToId;
  String? _replyPreview;

  // ===== APIs
  Uri get _listUri =>
      Uri.parse('$baseUrl/list_messages.php?staff_user_id=${widget.staffUserId}'
          '&parent_user_id=${widget.parentUserId}'
          '&child_id=${widget.childId}');

  Uri get _sendUri => Uri.parse('$baseUrl/send_message.php');
  Uri get _delUri => Uri.parse('$baseUrl/delete_message.php');

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(_listUri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j is Map && j['status'] == 'success') {
          final items = (j['items'] as List?) ?? const [];
          _messages =
              items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          setState(() {});
          _jumpToBottom();
        } else {
          _snack((j is Map ? j['message'] : 'Failed to load').toString());
        }
      } else {
        _snack('Load failed: ${res.statusCode}');
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);

    try {
      // نرسل كل الحقول المطلوبة + الاسمين المحتملين لحقل الدور
      final body = {
        'staff_user_id': '${widget.staffUserId}',
        'parent_user_id': '${widget.parentUserId}',
        'child_id': '${widget.childId}',
        'body': text,
        'sender_role': widget.role, // للاصدار الجديد
        'role': widget.role, // لاحتمال أن سكربت الـ PHP يستخدم هذا الاسم
        if (_replyToId != null) 'reply_to_message_id': '$_replyToId',
      };

      final res = await http
          .post(_sendUri, body: body)
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j is Map && j['status'] == 'success') {
          _input.clear();
          _replyToId = null;
          _replyPreview = null;
          await _fetch();
        } else {
          _snack((j is Map ? j['message'] : 'Send failed').toString());
        }
      } else {
        // نعرض رد السيرفر ليسهل معرفة السبب (400 مثلاً: حقل ناقص)
        _snack('Send failed: ${res.statusCode}\n${res.body}');
      }
    } catch (e) {
      _snack('Send error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteMessage(int id) async {
    try {
      final res = await http.post(_delUri,
          body: {'message_id': '$id'}).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j is Map && j['status'] == 'success') {
          await _fetch();
        } else {
          _snack((j is Map ? j['message'] : 'Delete failed').toString());
        }
      } else {
        _snack('Delete failed: ${res.statusCode}\n${res.body}');
      }
    } catch (e) {
      _snack('Delete error: $e');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _jumpToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // كشف اتجاه النص (يدعم العربية)
  bool _isRtl(String s) {
    for (final r in s.runes) {
      if ((r >= 0x0600 && r <= 0x06FF) || (r >= 0x0750 && r <= 0x077F)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.peerName.isEmpty ? 'Conversation' : widget.peerName;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final body = (m['body'] ?? '').toString();
                final from = (m['sender_role'] ?? m['role'] ?? '').toString();
                final mine = from == widget.role;
                final time = (m['created_at'] ?? '').toString();
                final isRtl = _isRtl(body);

                return Align(
                  alignment:
                      mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: GestureDetector(
                    onLongPress: () async {
                      await showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.reply),
                                title: const Text('Reply'),
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _replyToId =
                                        int.tryParse('${m['id'] ?? 0}');
                                    _replyPreview = body;
                                  });
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.copy),
                                title: const Text('Copy'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Clipboard.setData(ClipboardData(text: body));
                                  _snack('Copied');
                                },
                              ),
                              if (mine)
                                ListTile(
                                  leading: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  title: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    final id =
                                        int.tryParse('${m['id'] ?? 0}') ?? 0;
                                    if (id > 0) _deleteMessage(id);
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * .78,
                      ),
                      decoration: BoxDecoration(
                        color: mine ? const Color(0xFFDCEFE1) : kPanel,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if ((m['reply_preview'] ?? '').toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(6),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (m['reply_preview']).toString(),
                                textDirection:
                                    _isRtl((m['reply_preview']).toString())
                                        ? TextDirection.rtl
                                        : TextDirection.ltr,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            ),
                          Text(
                            body,
                            textDirection:
                                isRtl ? TextDirection.rtl : TextDirection.ltr,
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(time,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black45)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // شريط الردّ إن وُجد
          if (_replyToId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F6F3),
                border: Border(
                  top: BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _replyPreview ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: _isRtl(_replyPreview ?? '')
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cancel',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(
                        () => {_replyToId = null, _replyPreview = null}),
                  ),
                ],
              ),
            ),

          // الإدخال والإرسال
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF3F3F3),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 14),
                        hintText: 'اكتب رسالة...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send),
                      onPressed: _sending ? null : _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
