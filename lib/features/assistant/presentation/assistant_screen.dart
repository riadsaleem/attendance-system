import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../data/assistant_service.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  static const String routePath = '/assistant';

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  late final AssistantService _service;
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<AssistantMessage> _messages = [];
  bool _thinking = false;

  static const List<String> _initialSuggestions = [
    'إحصائيات اليوم',
    'الغائبين اليوم',
    'الطلاب الذين يحتاجون متابعة',
    'نسبة الحضور',
  ];

  @override
  void initState() {
    super.initState();
    _service = AssistantService(ref.read(supabaseClientProvider));
    _messages.add(const AssistantMessage(
      isFromUser: false,
      text: 'أهلاً! 👋 أنا مساعدك الذكي 🤖\n'
          'اسألني عن أي شيء يخص الحضور والغياب.',
      suggestions: _initialSuggestions,
    ));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final String message = text.trim();
    if (message.isEmpty || _thinking) return;

    _input.clear();
    setState(() {
      _messages.add(AssistantMessage(text: message, isFromUser: true));
      _thinking = true;
    });
    _scrollToEnd();

    try {
      final String reply = await _service.respond(message);
      if (mounted) {
        setState(() {
          _messages.add(AssistantMessage(
            isFromUser: false,
            text: reply,
            suggestions: _initialSuggestions,
          ));
          _thinking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(const AssistantMessage(
            isFromUser: false,
            text: 'تعذر الاتصال، تحقق من الإنترنت وحاول مجدداً 📡',
          ));
          _thinking = false;
        });
      }
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.smart_toy_rounded,
                  size: 20, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 10),
            const Text('المساعد الذكي'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (_thinking && index == _messages.length) {
                  return Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 10),
                          Text('يفكر...',
                              style: TextStyle(
                                  color: theme.hintColor, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }
                final AssistantMessage message = _messages[index];
                return _MessageBubble(
                  theme: theme,
                  message: message,
                  onSuggestion: (s) => _send(s),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(
                        hintText: 'اكتب سؤالك هنا...',
                        prefixIcon: Icon(Icons.chat_bubble_outline_rounded,
                            size: 20),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => _send(_input.text),
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.theme,
    required this.message,
    required this.onSuggestion,
  });

  final ThemeData theme;
  final AssistantMessage message;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isFromUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment:
              isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8),
            decoration: BoxDecoration(
              color: isUser
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadiusDirectional.only(
                topStart: const Radius.circular(18),
                topEnd: const Radius.circular(18),
                bottomStart: Radius.circular(isUser ? 18 : 4),
                bottomEnd: Radius.circular(isUser ? 4 : 18),
              ),
              border: isUser
                  ? null
                  : Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withOpacity(0.5)),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: isUser
                    ? Colors.white
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        if (!isUser && message.suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: message.suggestions
                  .map(
                    (s) => ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      onPressed: () => onSuggestion(s),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
