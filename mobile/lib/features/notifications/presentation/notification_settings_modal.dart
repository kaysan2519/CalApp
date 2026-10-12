import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_repository.dart';
import '../domain/notification_models.dart';

class NotificationSettingsModal extends ConsumerStatefulWidget {
  const NotificationSettingsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationSettingsModal(),
    );
  }

  @override
  ConsumerState<NotificationSettingsModal> createState() => _NotificationSettingsModalState();
}

class _NotificationSettingsModalState extends ConsumerState<NotificationSettingsModal> {
  bool _isLoading = true;
  NotificationPreferencesModel _prefs = NotificationPreferencesModel();
  HealthSensorData _sensorData = HealthSensorData();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      final p = await repo.getPreferences();
      final s = await repo.getHealthSensorData();
      if (mounted) {
        setState(() {
          _prefs = p;
          _sensorData = s;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePref(String key, dynamic value) async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      final updated = await repo.updatePreferences({key: value});
      if (mounted) {
        setState(() => _prefs = updated);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: bottomInset + 20,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.notifications_active, color: theme.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pengingat & Sensor Sehat',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _isLoading
                ? const Center(child: Text('Memuat preferensi...'))
                : ListView(
                    children: [
                      // Sensor Health Status Card (F20)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(20),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.blue.withAlpha(50)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_walk, color: Colors.blueAccent, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pelacak Aktivitas (Sensor F20)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Langkah Hari Ini: ${_sensorData.stepsToday} langkah (~${_sensorData.activeCaloriesKcal} kkal)',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Jadwal Pengingat Ramah (Non-Shaming)',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      SwitchListTile(
                        key: const Key('toggle_breakfast_reminder'),
                        title: const Text('Pengingat Sarapan (07:30)'),
                        subtitle: const Text('Isi energi sebelum memulai hari yang produktif', style: TextStyle(fontSize: 11)),
                        value: _prefs.breakfastReminder,
                        onChanged: (val) => _updatePref('breakfastReminder', val),
                      ),
                      SwitchListTile(
                        key: const Key('toggle_lunch_reminder'),
                        title: const Text('Pengingat Makan Siang (12:30)'),
                        subtitle: const Text('Penuhi kebutuhan protein dan nutrisi siang hari', style: TextStyle(fontSize: 11)),
                        value: _prefs.lunchReminder,
                        onChanged: (val) => _updatePref('lunchReminder', val),
                      ),
                      SwitchListTile(
                        key: const Key('toggle_dinner_reminder'),
                        title: const Text('Pengingat Makan Malam (19:00)'),
                        subtitle: const Text('Nikmati makan malam seimbang tanpa rasa bersalah', style: TextStyle(fontSize: 11)),
                        value: _prefs.dinnerReminder,
                        onChanged: (val) => _updatePref('dinnerReminder', val),
                      ),
                      SwitchListTile(
                        key: const Key('toggle_water_reminder'),
                        title: const Text('Pengingat Hidrasi Air Minum'),
                        subtitle: Text('Setiap ${_prefs.waterIntervalHours} jam sekali untuk tubuh bugar', style: const TextStyle(fontSize: 11)),
                        value: _prefs.waterReminder,
                        onChanged: (val) => _updatePref('waterReminder', val),
                      ),
                      SwitchListTile(
                        key: const Key('toggle_gentle_tone'),
                        title: const Text('Gaya Bahasa Santun & Suportif'),
                        subtitle: const Text('Pemberitahuan hangat tanpa memicu rasa cemas atau bersalah', style: TextStyle(fontSize: 11)),
                        value: _prefs.gentleTone,
                        onChanged: (val) => _updatePref('gentleTone', val),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}
}
