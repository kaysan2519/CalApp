import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/community_models.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CommunityRepository(apiClient: apiClient);
});

class CommunityRepository {
  final ApiClient apiClient;

  CommunityRepository({required this.apiClient});

  Future<List<GroupItem>> getGroups() async {
    final res = await apiClient.get('/community/groups');
    final list = res.data['data'] as List;
    return list.map((e) => GroupItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GroupItem> createGroup({
    required String name,
    String? description,
    bool isPrivate = false,
  }) async {
    final res = await apiClient.post(
      '/community/groups',
      data: {
        'name': name,
        if (description != null) 'description': description,
        'isPrivate': isPrivate,
      },
    );
    return GroupItem.fromJson(res.data['data']);
  }

  Future<void> joinGroup(String groupId) async {
    await apiClient.post('/community/groups/$groupId/join');
  }

  Future<void> leaveGroup(String groupId) async {
    await apiClient.post('/community/groups/$groupId/leave');
  }

  Future<List<PostItem>> getPosts({String? groupId, int limit = 20, int offset = 0}) async {
    final res = await apiClient.get(
      '/community/posts',
      queryParameters: {
        if (groupId != null) 'groupId': groupId,
        'limit': limit,
        'offset': offset,
      },
    );
    final list = res.data['data'] as List;
    return list.map((e) => PostItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PostItem> createPost({
    required String content,
    String? groupId,
    String postType = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    final res = await apiClient.post(
      '/community/posts',
      data: {
        'content': content,
        if (groupId != null) 'groupId': groupId,
        'postType': postType,
        'metadata': metadata ?? {},
      },
    );
    return PostItem.fromJson(res.data['data']);
  }

  Future<bool> toggleReaction(String postId, {String reactionType = 'kudos'}) async {
    final res = await apiClient.post(
      '/community/posts/$postId/reactions',
      data: {'reactionType': reactionType},
    );
    return res.data['data']['reacted'] as bool? ?? false;
  }

  Future<List<CommentItem>> getComments(String postId) async {
    final res = await apiClient.get('/community/posts/$postId/comments');
    final list = res.data['data'] as List;
    return list.map((e) => CommentItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CommentItem> addComment(String postId, String content) async {
    final res = await apiClient.post(
      '/community/posts/$postId/comments',
      data: {'content': content},
    );
    return CommentItem.fromJson(res.data['data']);
  }

  Future<Map<String, dynamic>> reportContent({
    required String reason,
    String? targetPostId,
    String? targetUserId,
  }) async {
    final res = await apiClient.post(
      '/community/report',
      data: {
        'reason': reason,
        if (targetPostId != null) 'targetPostId': targetPostId,
        if (targetUserId != null) 'targetUserId': targetUserId,
      },
    );
    return res.data['data'] as Map<String, dynamic>;
  }
}
