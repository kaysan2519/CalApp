import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../network/api_client.dart';

final offlineQueueProvider = Provider<OfflineQueue>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OfflineQueue(apiClient: apiClient);
});

class QueuedMutation {
  final String id;
  final String idempotencyKey;
  final String actionType; // 'MEAL_LOG' | 'WORKOUT_SESSION' | 'WATER_LOG'
  final String endpoint;
  final String method; // 'POST' | 'PUT' | 'DELETE'
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  String status; // 'pending' | 'syncing' | 'synced' | 'failed'

  QueuedMutation({
    required this.id,
    required this.idempotencyKey,
    required this.actionType,
    required this.endpoint,
    required this.method,
    required this.payload,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'idempotencyKey': idempotencyKey,
        'actionType': actionType,
        'endpoint': endpoint,
        'method': method,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
      };

  factory QueuedMutation.fromJson(Map<String, dynamic> json) => QueuedMutation(
        id: json['id'],
        idempotencyKey: json['idempotencyKey'],
        actionType: json['actionType'],
        endpoint: json['endpoint'],
        method: json['method'],
        payload: Map<String, dynamic>.from(json['payload'] ?? {}),
        createdAt: DateTime.parse(json['createdAt']),
        status: json['status'] ?? 'pending',
      );
}

class OfflineQueue {
  static const _queueStorageKey = 'cal_offline_mutation_queue';
  final ApiClient apiClient;
  final _uuid = const Uuid();

  OfflineQueue({required this.apiClient});

  Future<QueuedMutation> enqueue({
    required String actionType,
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    String? existingIdempotencyKey,
  }) async {
    final mutation = QueuedMutation(
      id: _uuid.v4(),
      idempotencyKey: existingIdempotencyKey ?? _uuid.v4(),
      actionType: actionType,
      endpoint: endpoint,
      method: method,
      payload: payload,
      createdAt: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    final currentList = await getPendingMutations();
    currentList.add(mutation);

    final serialized = jsonEncode(currentList.map((m) => m.toJson()).toList());
    await prefs.setString(_queueStorageKey, serialized);

    return mutation;
  }

  Future<List<QueuedMutation>> getPendingMutations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueStorageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => QueuedMutation.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> processPendingQueue() async {
    final pending = await getPendingMutations();
    if (pending.isEmpty) return 0;

    int syncedCount = 0;
    final remaining = <QueuedMutation>[];

    for (final mutation in pending) {
      try {
        mutation.status = 'syncing';
        // Execute HTTP with idempotency key
        if (mutation.method == 'POST') {
          await apiClient.post(
            mutation.endpoint,
            data: {
              ...mutation.payload,
              'idempotency_key': mutation.idempotencyKey,
            },
          );
        } else if (mutation.method == 'PUT') {
          await apiClient.put(mutation.endpoint, data: mutation.payload);
        } else if (mutation.method == 'DELETE') {
          await apiClient.delete(mutation.endpoint);
        }
        syncedCount++;
      } catch (err) {
        // Keep in queue for next sync retry
        mutation.status = 'pending';
        remaining.add(mutation);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _queueStorageKey,
      jsonEncode(remaining.map((m) => m.toJson()).toList()),
    );

    return syncedCount;
  }

  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueStorageKey);
  }
}
