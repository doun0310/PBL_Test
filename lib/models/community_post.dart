import 'package:uuid/uuid.dart';

class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String content;
  final DateTime timestamp;
  final List<String> imageUrls;
  final int likes;
  final int comments;
  final String category;

  CommunityPost({
    String? id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.content,
    DateTime? timestamp,
    this.imageUrls = const [],
    this.likes = 0,
    this.comments = 0,
    this.category = '일반',
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'imageUrls': imageUrls,
      'likes': likes,
      'comments': comments,
      'category': category,
    };
  }

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      title: json['title'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      category: json['category'] ?? '일반',
    );
  }

  CommunityPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? title,
    String? content,
    DateTime? timestamp,
    List<String>? imageUrls,
    int? likes,
    int? comments,
    String? category,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      imageUrls: imageUrls ?? this.imageUrls,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      category: category ?? this.category,
    );
  }
}

class PostComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String content;
  final DateTime timestamp;

  PostComment({
    String? id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.content,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'],
      postId: json['postId'],
      userId: json['userId'],
      userName: json['userName'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
