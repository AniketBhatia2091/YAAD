import 'package:flutter/material.dart';

import '../../app/theme/color_tokens.dart';
import '../../app/theme/radius_tokens.dart';
import '../../app/theme/shadow_tokens.dart';
import '../../app/theme/spacing_tokens.dart';
import '../../app/theme/typography_tokens.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? relatedMemoryTitle;
  final String? relatedMemoryDetail;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.relatedMemoryTitle,
    this.relatedMemoryDetail,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();

  final List<String> _exampleQueries = const [
    'Where\'s my bike insurance?',
    'When does my earbuds warranty expire?',
    'Show my electricity bills.',
  ];

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      text:
          'Namaste! Ask me anything about your saved bills, IDs, warranties, or medical prescriptions.',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _sendQuery(String text) {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _inputController.clear();
    });

    _generateMockResponse(text);
  }

  void _generateMockResponse(String query) {
    final q = query.toLowerCase();
    String responseText = '';
    String? title;
    String? detail;

    if (q.contains('bike') || q.contains('insurance')) {
      responseText =
          'I found your ICICI Lombard Bike Insurance. It is active and expires in 12 days on September 10, 2026.';
      title = 'Bike Insurance Policy';
      detail = 'ICICI Lombard Policy #3005/1829384 · Renew before Sep 10';
    } else if (q.contains('earbud') || q.contains('warranty')) {
      responseText =
          'Your Boat Rockerz 450 earbuds warranty has 18 days remaining. Invoice date was October 2025.';
      title = 'Earbuds Warranty Certificate';
      detail = 'Boat Rockerz 450 · Invoice INV-92837';
    } else if (q.contains('electricity') || q.contains('bill')) {
      responseText =
          'Your latest BSES Electricity Bill is ₹1,847, due in 2 days on September 5, 2026.';
      title = 'BSES Electricity Bill';
      detail = 'Account: 102938475 · ₹1,847 due Sep 5';
    } else if (q.contains('aadhaar') || q.contains('pan') || q.contains('id')) {
      responseText =
          'Here is your Aadhaar Card. Unique ID ends in 8921 under Self.';
      title = 'Aadhaar Card';
      detail = 'Aadhaar: XXXX XXXX 8921';
    } else {
      responseText =
          'I searched your local memories for "$query". You can see all matching items in the Search tab.';
    }

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
          relatedMemoryTitle: title,
          relatedMemoryDetail: detail,
        ));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? YaadColors.borderDark : YaadColors.borderLight;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Chat Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: YaadSpacing.md, vertical: YaadSpacing.sm),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? YaadColors.goldSurface : YaadColors.primary,
                      borderRadius: YaadRadius.borderLg,
                    ),
                    child: Icon(
                      Icons.forum_outlined,
                      color: isDark ? YaadColors.goldAccent : Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ask YAAD',
                        style: YaadTypography.titleLargeOf(context),
                      ),
                      Text(
                        'Your memories, in conversation.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),

            // Messages Stream
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(YaadSpacing.md),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, isDark);
                },
              ),
            ),

            // Example Prompt Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: YaadSpacing.md, vertical: YaadSpacing.xs),
              child: Row(
                children: _exampleQueries.map((query) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(query),
                      onPressed: () => _sendQuery(query),
                      backgroundColor: isDark ? YaadColors.surfaceDark : YaadColors.surfaceSubtleLight,
                      labelStyle: TextStyle(
                        color: isDark ? YaadColors.creamMuted : YaadColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: YaadRadius.borderPill,
                        side: BorderSide(color: borderColor),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 4),

            // Chat Input Bar
            Padding(
              padding: const EdgeInsets.all(YaadSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      onSubmitted: _sendQuery,
                      decoration: const InputDecoration(
                        hintText: 'Ask about your memories...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: 'Send message',
                    button: true,
                    child: IconButton.filled(
                      onPressed: () => _sendQuery(_inputController.text),
                      icon: const Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: YaadColors.goldPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    final isUser = msg.isUser;
    final cardBg = isUser
        ? (isDark ? YaadColors.goldPrimary : YaadColors.primary)
        : (isDark ? YaadColors.surfaceDark : YaadColors.surfaceLight);
    final borderColor = isDark ? YaadColors.borderDark : YaadColors.borderLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: YaadColors.goldPrimary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('Y', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: borderColor),
                boxShadow: isUser ? null : YaadShadows.subtle,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : (isDark ? YaadColors.textPrimaryDark : YaadColors.textPrimaryLight),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  if (msg.relatedMemoryTitle != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? YaadColors.surfaceRaised : YaadColors.accentLight,
                        borderRadius: YaadRadius.borderMd,
                        border: Border.all(
                          color: isDark ? YaadColors.goldBorder : const Color(0x4DD97706),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bookmark_added_outlined, color: YaadColors.goldAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.relatedMemoryTitle!,
                                  style: YaadTypography.titleSmallOf(context).copyWith(fontSize: 13),
                                ),
                                if (msg.relatedMemoryDetail != null)
                                  Text(
                                    msg.relatedMemoryDetail!,
                                    style: TextStyle(
                                      color: isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
