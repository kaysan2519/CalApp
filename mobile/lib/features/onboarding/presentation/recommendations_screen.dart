import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String? _errorCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
      _errorCode = null;
    });
    try {
      final response = await ref.read(apiClientProvider).post('/ai/profile-recommendations');
      final data = Map<String, dynamic>.from(response.data['data']);
      if (mounted) setState(() => _data = data);
    } catch (error) {
      final cause = error is DioException ? error.error : null;
      if (mounted) {
        setState(() {
          _error = cause is ApiException ? cause.message : 'Rekomendasi belum dapat dimuat. Periksa koneksi lalu coba lagi.';
          _errorCode = cause is ApiException ? cause.code : null;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final targets = _data?['nutritionTargets'] as Map<String, dynamic>?;
    final recommendations = _data?['recommendations'] as Map<String, dynamic>?;
    final mealSuggestions = recommendations?['mealSuggestions'] as List<dynamic>? ?? const [];
    final schedule = recommendations?['weeklySchedule'] as List<dynamic>? ?? const [];
    final safetyNotes = recommendations?['safetyNotes'] as List<dynamic>? ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Rencana personal')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Row(children: [Icon(Icons.auto_awesome_outlined, color: AppColors.primary), SizedBox(width: 8), Text('Disusun dari profilmu', style: TextStyle(fontWeight: FontWeight.w800))]),
                        const SizedBox(height: 10),
                        Text(recommendations?['summary']?.toString() ?? '', style: const TextStyle(height: 1.45)),
                      ]),
                    ),
                    const SizedBox(height: 18),
                    Text('Estimasi nutrisi harian', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    _targetsCard(targets),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => context.go('/profile'),
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Tinjau atau ubah target'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Ide makanan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (mealSuggestions.isEmpty)
                      const _EmptyRecommendation(text: 'Belum ada ide makanan pada rekomendasi ini.')
                    else
                      ...mealSuggestions.map((item) => _SuggestionTile(icon: Icons.restaurant_outlined, text: item.toString())),
                    const SizedBox(height: 18),
                    Text('Jadwal latihan mingguan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (schedule.isEmpty)
                      const _EmptyRecommendation(text: 'Belum ada jadwal latihan pada rekomendasi ini.')
                    else
                      ...schedule.map((entry) {
                        final day = Map<String, dynamic>.from(entry as Map);
                        final activities = (day['activities'] as List<dynamic>? ?? const []).map((item) => item.toString()).join(' · ');
                        return _SuggestionTile(icon: Icons.fitness_center_outlined, text: '${day['day']}: ${day['focus']}${activities.isEmpty ? '' : '\n$activities'}');
                      }),
                    if (safetyNotes.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text('Catatan aman', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      ...safetyNotes.map((item) => _SuggestionTile(icon: Icons.health_and_safety_outlined, text: item.toString())),
                    ],
                    const SizedBox(height: 12),
                    Text(_data?['notice']?.toString() ?? 'Tinjau dan sesuaikan rencana dengan kebutuhanmu.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.darkTextSecondary, height: 1.4)),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(onPressed: _generate, icon: const Icon(Icons.refresh_rounded), label: const Text('Buat rekomendasi ulang')),
                    const SizedBox(height: 8),
                    FilledButton(onPressed: () => context.go('/today'), child: const Text('Lanjut ke Cal')),
                  ],
                ),
    );
  }

  Widget _buildError() {
    final notConfigured = _errorCode == 'AI_NOT_CONFIGURED' || _errorCode == 'AI_PROVIDER_AUTH_FAILED';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(notConfigured ? Icons.settings_suggest_outlined : Icons.cloud_off_outlined, size: 44, color: AppColors.warning),
            const SizedBox(height: 12),
            Text(notConfigured ? 'AI belum tersedia' : 'Rekomendasi belum dimuat', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.darkTextSecondary, height: 1.4)),
            const SizedBox(height: 14),
            const Text('Target nutrisi tetap dihitung dari profil oleh aplikasi. Tidak ada hasil AI contoh yang ditampilkan.', textAlign: TextAlign.center),
            const SizedBox(height: 18),
            OutlinedButton.icon(onPressed: _generate, icon: const Icon(Icons.refresh_rounded), label: const Text('Coba lagi')),
            TextButton(onPressed: () => context.go('/today'), child: const Text('Lanjut ke Cal')),
          ]),
        ),
      ),
    );
  }

  Widget _targetsCard(Map<String, dynamic>? targets) {
    if (targets == null) return const _EmptyRecommendation(text: 'Target nutrisi belum tersedia untuk profil ini.');
    String value(String key) => (targets[key] as num?)?.toStringAsFixed(0) ?? '—';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _TargetRow(label: 'Energi', value: '${value('targetCalories')} kkal'),
          const Divider(height: 20),
          _TargetRow(label: 'Protein', value: '${value('targetProteinG')} g'),
          const SizedBox(height: 10),
          _TargetRow(label: 'Karbohidrat', value: '${value('targetCarbsG')} g'),
          const SizedBox(height: 10),
          _TargetRow(label: 'Lemak', value: '${value('targetFatG')} g'),
          const SizedBox(height: 10),
          _TargetRow(label: 'Air', value: '${value('targetWaterMl')} ml'),
          const SizedBox(height: 12),
          Text(targets['isManual'] == true ? 'Target ini sudah kamu atur secara manual.' : 'Estimasi rumus Mifflin–St Jeor; kamu dapat mengubahnya dari profil.', style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
        ]),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]);
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(text, style: const TextStyle(height: 1.35)),
        ),
      );
}

class _EmptyRecommendation extends StatelessWidget {
  const _EmptyRecommendation({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(text, style: const TextStyle(color: AppColors.darkTextSecondary))));
}
