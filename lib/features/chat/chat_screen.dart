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

    // Provide mock context-aware retrieval response
    _generateMockResponse(text);
  }

  /// Mock Response Provider Engine
  /// Code structured so this can be swapped with real RAG / On-device AI Retrieval engine.
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
    } else {
      responseText =
          'I checked your remembered items. I found memories matching "$query" in your Vault.';
      title = 'Matching Memory';
      detail = 'Stored safely in private local storage';
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: responseText,
              isUser: false,
              timestamp: DateTime.now(),
              relatedMemoryTitle: title,
              relatedMemoryDetail: detail,
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YaadColors.backgroundLight,
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
                    decoration: const BoxDecoration(
                      color: YaadColors.primary,
                      borderRadius: YaadRadius.borderLg,
                    ),
                    child: const Icon(Icons.forum_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ask YAAD',
                        style: YaadTypography.titleLarge,
                      ),
                      Text(
                        'Your memories, in conversation.',
                        style: TextStyle(
                          fontSize: 13,
                          color: YaadColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: YaadColors.borderLight),

            // Messages Stream
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(YaadSpacing.md),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
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
                      backgroundColor: YaadColors.surfaceSubtleLight,
                      labelStyle: YaadTypography.labelSmall.copyWith(
                        color: YaadColors.primary,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: YaadRadius.borderPill,
                        side: BorderSide(color: YaadColors.borderLight),
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
                  IconButton.filled(
                    onPressed: () => _sendQuery(_inputController.text),
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: YaadColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 48),
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

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
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
                color: YaadColors.primary,
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
                color: isUser ? YaadColors.primary : YaadColors.surfaceLight,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: YaadColors.borderLight),
                boxShadow: isUser ? null : YaadShadows.subtle,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: YaadTypography.bodyMedium.copyWith(
                      color: isUser ? Colors.white : YaadColors.textPrimaryLight,
                    ),
                  ),
                  if (msg.relatedMemoryTitle != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: YaadColors.accentLight,
                        borderRadius: YaadRadius.borderMd,
                        border: Border.all(color: const Color(0x4DD97706)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bookmark_added_outlined, color: YaadColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.relatedMemoryTitle!,
                                  style: YaadTypography.titleSmall.copyWith(fontSize: 13),
                                ),
                                if (msg.relatedMemoryDetail != null)
                                  Text(
                                    msg.relatedMemoryDetail!,
                                    style: YaadTypography.labelSmall.copyWith(
                                      color: YaadColors.textSecondaryLight,
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
