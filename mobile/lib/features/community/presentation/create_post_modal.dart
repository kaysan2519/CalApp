import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/community_repository.dart';

class CreatePostModal extends ConsumerStatefulWidget {
  final String? initialGroupId;

  const CreatePostModal({super.key, this.initialGroupId});

  static Future<bool?> show(BuildContext context, {String? groupId}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePostModal(initialGroupId: groupId),
    );
  }

  @override
  ConsumerState<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends ConsumerState<CreatePostModal> {
  final _contentController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handlePost() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Konten postingan tidak boleh kosong');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.createPost(
        content: text,
        groupId: widget.initialGroupId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Postingan berhasil dibagikan! +15 XP')),
        );
        if (Navigator.canPop(context)) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal membagikan: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bagikan Cerita ke Komunitas',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bagikan pencapaian target nutrisi, sesi latihan gym, atau resep favoritmu hari ini.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('post_content_input'),
            controller: _contentController,
            maxLines: 5,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: 'Tulis sesuatu yang menyemangati...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('submit_post_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _handlePost,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 18),
                      SizedBox(width: 8),
                      Text('Kirim Postingan (+15 XP)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
