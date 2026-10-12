import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/ai_repository.dart';
import '../domain/ai_food_models.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  final List<CoachChatMessage> _messages = [
    CoachChatMessage(
      id: 'welcome',
      text: 'Halo! Saya Cal AI Coach Anda. Saya dapat melihat ringkasan nutrisi dan latihan harian Anda untuk memberikan saran yang relevan dan praktis. Ada yang bisa saya bantu hari ini?',
      isUser: false,
      disclaimer: 'Peringatan: Saran AI Coach hanya untuk panduan gaya hidup sehat dan bukan pengganti konsultasi medis profesional.',
      timestamp: DateTime.now(),
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage([String? quickText]) async {
    final text = (quickText ?? _messageController.text).trim();
    if (text.isEmpty || _isLoading) return;

    if (quickText == null) {
      _messageController.clear();
    }

    final userMsg = CoachChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final aiRepo = ref.read(aiRepositoryProvider);
      final response = await aiRepo.sendCoachMessage(text);
      final coachReply = response['message'] as String? ?? 'Maaf, saya tidak dapat menjawab saat ini.';
      final disclaimer = response['disclaimer'] as String?;

      if (mounted) {
        setState(() {
          _messages.add(CoachChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: coachReply,
            isUser: false,
            disclaimer: disclaimer,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(CoachChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: 'Mohon maaf, terjadi kendala saat menghubungi AI Coach. Silakan coba kembali sesaat lagi.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Cal AI Coach', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Medical disclaimer strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.warning.withValues(alpha: 0.12),
            child: const Row(
              children: [
                Icon(Icons.health_and_safety_outlined, size: 16, color: AppColors.warning),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Panduan kebiasaan sehat berbasis data Anda. Bukan saran medis resmi.',
                    style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!msg.isUser) ...[
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.fitness_center_rounded, size: 16, color: Colors.black),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: msg.isUser ? AppColors.primary : AppColors.darkSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: msg.isUser ? null : Border.all(color: AppColors.darkBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.text,
                                style: TextStyle(
                                  color: msg.isUser ? Colors.black : Colors.white,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              if (msg.disclaimer != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  msg.disclaimer!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                    color: msg.isUser ? Colors.black54 : AppColors.darkTextSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (msg.isUser) ...[
                        const SizedBox(width: 8),
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.darkSurface,
                          child: Icon(Icons.person, size: 16, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          if (_isLoading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text('Cal Coach sedang mengetik...', style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ],

          // Quick suggestions carousel
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                ActionChip(
                  label: const Text('Sisa kalori hari ini?'),
                  onPressed: () => _sendMessage('Berapa sisa kalori saya untuk hari ini?'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Rekomendasi protein'),
                  onPressed: () => _sendMessage('Beri rekomendasi menu tinggi protein yang mudah didapat'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Camilan sehat lokal'),
                  onPressed: () => _sendMessage('Apa camilan sehat rendah kalori khas Indonesia?'),
                ),
              ],
            ),
          ),

          // Message input bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.darkSurface,
              border: Border(top: BorderSide(color: AppColors.darkBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Tanyakan nutrisi atau pola latihan...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: _isLoading ? null : () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
