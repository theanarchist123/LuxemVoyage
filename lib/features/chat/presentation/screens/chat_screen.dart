import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/gemini_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  final String? initialContextMessage;
  const ChatScreen({super.key, this.initialContextMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();

  List<ChatMessage> _buildInitialMessages() {
    final user = FirebaseAuth.instance.currentUser;
    final firstName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!.split(' ').first
        : 'Traveller';
    return [
      ChatMessage(
        text: widget.initialContextMessage ?? 
              'Hello, $firstName! I\'m your AI travel concierge. How can I help plan your next adventure?', 
        isUser: false
      ),
    ];
  }

  late final List<ChatMessage> _messages;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages = _buildInitialMessages();
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    setState(() { _messages.add(ChatMessage(text: text, isUser: true)); _isLoading = true; });
    _scrollToBottom();

    try {
      final response = await _geminiService.chat(text);
      if (mounted) {
        setState(() { _messages.add(ChatMessage(text: response, isUser: false)); _isLoading = false; });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: "I apologize, I'm experiencing connectivity issues. Please try again.", isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildBubble(_messages[index])
                        .animate().fadeIn(duration: 250.ms).slideY(begin: 0.06, end: 0);
                  },
                ),
              ),
              if (_isLoading) _buildTypingIndicator(),
              _buildInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.04))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(
              gradient: AppTheme.amberGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(child: Icon(LucideIcons.sparkles, color: AppTheme.primaryBlack, size: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("AI Concierge", style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                Row(children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.accentTeal, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text("Online · Gemini", style: TextStyle(color: AppTheme.accentTeal.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
                ]),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 30, height: 30,
              decoration: const BoxDecoration(
                gradient: AppTheme.amberGradient,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Icon(LucideIcons.sparkles, color: AppTheme.primaryBlack, size: 12)),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                gradient: message.isUser ? AppTheme.amberGradient : null,
                color: message.isUser ? null : AppTheme.surfaceDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                border: message.isUser ? null : Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? AppTheme.primaryBlack : AppTheme.textPrimary,
                  fontSize: 14, height: 1.5, fontWeight: message.isUser ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 56, bottom: 8),
      child: Row(
        children: [
          ...List.generate(3, (i) => Container(
            margin: const EdgeInsets.only(right: 4),
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: AppTheme.accentAmber.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(delay: Duration(milliseconds: 200 * i))
              .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.0, 1.0), duration: 600.ms, delay: Duration(milliseconds: 200 * i))),
          const SizedBox(width: 8),
          Text("Thinking...", style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.8),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.04))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration(
                  hintText: "Ask about any destination...",
                  hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.35)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _handleSubmitted(_textController.text),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.amberGradient,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Icon(LucideIcons.send, color: AppTheme.primaryBlack, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
