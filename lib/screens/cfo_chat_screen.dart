// lib/screens/cfo_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/expense.dart';
import '../services/ai_service.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  Message(this.text, this.isUser) : timestamp = DateTime.now();
}

class CFOChatScreen extends StatefulWidget {
  final AIService aiService;
  final List<Expense> expenses;

  const CFOChatScreen({
    super.key,
    required this.aiService,
    required this.expenses,
  });

  @override
  State<CFOChatScreen> createState() => _CFOChatScreenState();
}

class _CFOChatScreenState extends State<CFOChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isTyping = false;

  final _suggestions = [
    '💸 How much did I spend this month?',
    '🧾 Which expenses are tax deductible?',
    '📊 What\'s my biggest spending category?',
    '🔮 Predict my expenses next month',
    '⚠️ Any unusual spending patterns?',
    '💡 How can I reduce my expenses?',
  ];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(Message(
      'Hello! I\'m your AI CFO 👋\n\nI\'ve analyzed your expense data and I\'m ready to give you CFO-level insights. Ask me anything about your spending, tax savings, cash flow predictions, or cost optimization.',
      false,
    ));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();

    setState(() {
      _messages.add(Message(text, true));
      _isTyping = true;
    });

    _scrollToBottom();

    final response =
        await widget.aiService.chatWithCFO(text, widget.expenses);

    setState(() {
      _messages.add(Message(response, false));
      _isTyping = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppGradients.goldGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: AppColors.background, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI CFO',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Powered by Gemini',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length +
                  (_isTyping ? 1 : 0) +
                  (_messages.length == 1 ? 1 : 0),
              itemBuilder: (context, index) {
                // Show suggestions after welcome message
                if (_messages.length == 1 && index == 1) {
                  return _buildSuggestions();
                }

                final msgIndex =
                    (_messages.length == 1 && index > 1) ? index - 1 : index;

                if (_isTyping && msgIndex == _messages.length) {
                  return _buildTypingIndicator();
                }

                if (msgIndex >= _messages.length) return const SizedBox.shrink();
                return _buildMessage(_messages[msgIndex]);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessage(Message msg) {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment:
              msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!msg.isUser) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppGradients.goldGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: AppColors.background, size: 16),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: msg.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? AppColors.goldGlow
                          : AppColors.surfaceCard,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft:
                            Radius.circular(msg.isUser ? 18 : 4),
                        bottomRight:
                            Radius.circular(msg.isUser ? 4 : 18),
                      ),
                      border: Border.all(
                        color: msg.isUser
                            ? AppColors.gold.withOpacity(0.3)
                            : const Color(0xFF2A2A3E),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: msg.isUser
                            ? AppColors.goldLight
                            : AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(msg.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (msg.isUser) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK QUESTIONS',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map((s) => GestureDetector(
                      onTap: () => _sendMessage(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF2A2A3E)),
                        ),
                        child: Text(
                          s,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppGradients.goldGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: AppColors.background, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border:
                  Border.all(color: const Color(0xFF2A2A3E)),
            ),
            child: _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A3E)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2A2A3E)),
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ask your AI CFO anything...',
                  hintStyle: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                onSubmitted: _sendMessage,
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppGradients.goldGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.send_rounded,
                  color: AppColors.background, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      )..repeat(reverse: true),
    );

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].forward();
      });
    }

    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: -6).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _animations[i].value),
            child: Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}
