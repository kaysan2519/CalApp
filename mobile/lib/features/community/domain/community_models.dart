class GroupItem {
  final String id;
  final String name;
  final String? description;
  final bool isPrivate;
  final int memberCount;
  final bool isMember;

  GroupItem({
    required this.id,
    required this.name,
    this.description,
    this.isPrivate = false,
    this.memberCount = 1,
    this.isMember = false,
  });

  factory GroupItem.fromJson(Map<String, dynamic> json) {
    return GroupItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isPrivate: json['is_private'] as bool? ?? false,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 1,
      isMember: json['is_member'] as bool? ?? false,
    );
  }
}

class PostItem {
  final String id;
  final String userId;
  final String? groupId;
  final String content;
  final String postType;
  final String createdAt;
  final String authorName;
  final String? groupName;
  final int reactionCount;
  final int commentCount;
  final bool hasReacted;

  PostItem({
    required this.id,
    required this.userId,
    this.groupId,
    required this.content,
    this.postType = 'text',
    required this.createdAt,
    required this.authorName,
    this.groupName,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.hasReacted = false,
  });

  factory PostItem.fromJson(Map<String, dynamic> json) {
    return PostItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String?,
      content: json['content'] as String,
      postType: json['post_type'] as String? ?? 'text',
      createdAt: json['created_at'] as String,
      authorName: json['author_name'] as String? ?? 'Sahabat Cal',
      groupName: json['group_name'] as String?,
      reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      hasReacted: json['has_reacted'] as bool? ?? false,
    );
  }
}

class CommentItem {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final String createdAt;
  final String authorName;

  CommentItem({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.authorName,
  });

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    return CommentItem(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: json['created_at'] as String,
      authorName: json['author_name'] as String? ?? 'Sahabat Cal',
    );
  }
}
