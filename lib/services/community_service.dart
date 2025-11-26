import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_post.dart';

class CommunityService {
  static const String _postsKey = 'community_posts';
  static const String _commentsKey = 'post_comments';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 로컬에서 모든 게시물 가져오기
  static Future<List<CommunityPost>> getAllPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final postsJson = prefs.getString(_postsKey);
    
    if (postsJson == null) {
      return _getSamplePosts();
    }

    final List<dynamic> decoded = json.decode(postsJson);
    return decoded.map((item) => CommunityPost.fromJson(item)).toList();
  }

  // 샘플 게시물 (초기 데이터)
  static List<CommunityPost> _getSamplePosts() {
    return [
      CommunityPost(
        userId: 'user1',
        userName: '건강한식단',
        title: '다이어트 한달 후기 공유합니다!',
        content: '한달 동안 앱으로 식단 관리하면서 5kg 감량 성공했어요! 꾸준히 기록하는 것이 정말 중요하더라구요.',
        category: '후기',
        likes: 42,
        comments: 8,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      CommunityPost(
        userId: 'user2',
        userName: '헬스러버',
        title: '운동과 식단 병행 팁',
        content: '운동 전후 식사 타이밍이 중요해요. 운동 1시간 전 가벼운 탄수화물, 운동 후 30분 내 단백질 섭취를 추천합니다!',
        category: '정보',
        likes: 67,
        comments: 15,
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
      ),
      CommunityPost(
        userId: 'user3',
        userName: '요리왕',
        title: '저칼로리 샐러드 레시피 공유',
        content: '닭가슴살과 신선한 채소로 만든 샐러드 레시피입니다. 200kcal 이하로 맛있게 먹을 수 있어요!',
        category: '레시피',
        likes: 89,
        comments: 23,
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }

  // 게시물 추가
  static Future<void> addPost(CommunityPost post) async {
    final posts = await getAllPosts();
    posts.insert(0, post);
    await _savePosts(posts);

    // Firebase에도 저장 (선택사항)
    try {
      await _firestore.collection('community_posts').doc(post.id).set(post.toJson());
    } catch (e) {
      // Firebase 저장 실패는 무시 (로컬 저장은 완료됨)
    }
  }

  // 게시물 업데이트
  static Future<void> updatePost(CommunityPost post) async {
    final posts = await getAllPosts();
    final index = posts.indexWhere((p) => p.id == post.id);
    if (index != -1) {
      posts[index] = post;
      await _savePosts(posts);

      // Firebase에도 업데이트 (선택사항)
      try {
        await _firestore.collection('community_posts').doc(post.id).update(post.toJson());
      } catch (e) {
        // Firebase 업데이트 실패는 무시 (로컬 저장은 완료됨)
      }
    }
  }

  // 게시물 삭제
  static Future<void> deletePost(String postId) async {
    final posts = await getAllPosts();
    posts.removeWhere((p) => p.id == postId);
    await _savePosts(posts);

    // Firebase에서도 삭제 (선택사항)
    try {
      await _firestore.collection('community_posts').doc(postId).delete();
    } catch (e) {
      // Firebase 삭제 실패는 무시 (로컬 삭제는 완료됨)
    }
  }

  // 카테고리별 게시물 가져오기
  static Future<List<CommunityPost>> getPostsByCategory(String category) async {
    final allPosts = await getAllPosts();
    if (category == '전체') return allPosts;
    return allPosts.where((post) => post.category == category).toList();
  }

  // 게시물 검색
  static Future<List<CommunityPost>> searchPosts(String query) async {
    final allPosts = await getAllPosts();
    final queryLower = query.toLowerCase();
    
    return allPosts.where((post) {
      return post.title.toLowerCase().contains(queryLower) ||
          post.content.toLowerCase().contains(queryLower) ||
          post.userName.toLowerCase().contains(queryLower);
    }).toList();
  }

  // 좋아요 추가
  static Future<void> likePost(String postId) async {
    final posts = await getAllPosts();
    final index = posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      posts[index] = posts[index].copyWith(likes: posts[index].likes + 1);
      await _savePosts(posts);
    }
  }

  // 댓글 가져오기
  static Future<List<PostComment>> getComments(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final commentsJson = prefs.getString('$_commentsKey$postId');
    
    if (commentsJson == null) return [];

    final List<dynamic> decoded = json.decode(commentsJson);
    return decoded.map((item) => PostComment.fromJson(item)).toList();
  }

  // 댓글 추가
  static Future<void> addComment(PostComment comment) async {
    final comments = await getComments(comment.postId);
    comments.add(comment);
    
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(comments.map((c) => c.toJson()).toList());
    await prefs.setString('$_commentsKey${comment.postId}', encoded);

    // 게시물의 댓글 수 증가
    final posts = await getAllPosts();
    final index = posts.indexWhere((p) => p.id == comment.postId);
    if (index != -1) {
      posts[index] = posts[index].copyWith(comments: posts[index].comments + 1);
      await _savePosts(posts);
    }
  }

  // Firebase에서 게시물 가져오기
  static Stream<List<CommunityPost>> watchPosts() {
    return _firestore
        .collection('community_posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityPost.fromJson(doc.data()))
            .toList());
  }

  // 인기 게시물 (좋아요 순)
  static Future<List<CommunityPost>> getPopularPosts({int limit = 10}) async {
    final allPosts = await getAllPosts();
    allPosts.sort((a, b) => b.likes.compareTo(a.likes));
    return allPosts.take(limit).toList();
  }

  // 최신 게시물
  static Future<List<CommunityPost>> getRecentPosts({int limit = 10}) async {
    final allPosts = await getAllPosts();
    allPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allPosts.take(limit).toList();
  }

  // 내가 작성한 게시물
  static Future<List<CommunityPost>> getMyPosts(String userId) async {
    final allPosts = await getAllPosts();
    return allPosts.where((post) => post.userId == userId).toList();
  }

  // 게시물 저장 (내부 메서드)
  static Future<void> _savePosts(List<CommunityPost> posts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(posts.map((p) => p.toJson()).toList());
    await prefs.setString(_postsKey, encoded);
  }

  // 카테고리 목록
  static const List<String> categories = [
    '전체',
    '정보',
    '레시피',
    '후기',
    '질문',
    '운동',
    '다이어트',
  ];
}
