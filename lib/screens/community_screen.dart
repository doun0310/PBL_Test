import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/community_post.dart';
import '../services/community_service.dart';
import '../services/auth_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<CommunityPost> _posts = [];
  String _selectedCategory = '전체';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    
    final posts = await CommunityService.getPostsByCategory(_selectedCategory);
    
    setState(() {
      _posts = posts;
      _isLoading = false;
    });
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreatePostDialog(
        onPost: (post) async {
          await CommunityService.addPost(post);
          await _loadPosts();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('게시물이 작성되었습니다'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 검색 기능
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreatePostDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildPostList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: CommunityService.categories.length,
        itemBuilder: (context, index) {
          final category = CommunityService.categories[index];
          final isSelected = category == _selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
                _loadPosts();
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostList() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum,
              size: 64,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              '아직 게시물이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showCreatePostDialog,
              icon: const Icon(Icons.add),
              label: const Text('첫 게시물 작성하기'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showPostDetails(post),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(post.userName[0]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(post.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(post.category, style: const TextStyle(fontSize: 12)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 20,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likes}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.comment_outlined,
                    size: 20,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.comments}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostDetails(CommunityPost post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PostDetailScreen(post: post),
      ),
    );
    // Refresh posts when returning from detail screen
    _loadPosts();
  }
}

class _CreatePostDialog extends StatefulWidget {
  final Function(CommunityPost) onPost;

  const _CreatePostDialog({required this.onPost});

  @override
  State<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<_CreatePostDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = '일반';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('게시물 작성'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(),
              ),
              items: CommunityService.categories
                  .where((c) => c != '전체')
                  .map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('제목과 내용을 입력해주세요')),
              );
              return;
            }

            final userName = await AuthService.getCurrentUserName() ?? '사용자';
            final userId = await AuthService.getCurrentUserId() ?? 'anonymous';

            final post = CommunityPost(
              userId: userId,
              userName: userName,
              title: _titleController.text,
              content: _contentController.text,
              category: _selectedCategory,
            );

            widget.onPost(post);
            Navigator.pop(context);
          },
          child: const Text('게시'),
        ),
      ],
    );
  }
}

class _PostDetailScreen extends StatefulWidget {
  final CommunityPost post;

  const _PostDetailScreen({required this.post});

  @override
  State<_PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<_PostDetailScreen> {
  late CommunityPost _post;
  List<PostComment> _comments = [];
  final _commentController = TextEditingController();
  bool _isLiked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final comments = await CommunityService.getComments(_post.id);
    setState(() {
      _comments = comments;
    });
  }

  Future<void> _handleLike() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _isLiked = !_isLiked;
    });

    await CommunityService.likePost(_post.id);
    
    // Reload post to get updated like count
    final posts = await CommunityService.getAllPosts();
    final updatedPost = posts.firstWhere((p) => p.id == _post.id, orElse: () => _post);
    
    setState(() {
      _post = updatedPost;
      _isLoading = false;
    });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 내용을 입력해주세요')),
      );
      return;
    }

    final userName = await AuthService.getCurrentUserName() ?? '사용자';
    final userId = await AuthService.getCurrentUserId() ?? 'anonymous';

    final comment = PostComment(
      postId: _post.id,
      userId: userId,
      userName: userName,
      content: _commentController.text.trim(),
    );

    await CommunityService.addComment(comment);
    _commentController.clear();
    
    // Reload comments and post
    await _loadComments();
    final posts = await CommunityService.getAllPosts();
    final updatedPost = posts.firstWhere((p) => p.id == _post.id, orElse: () => _post);
    
    setState(() {
      _post = updatedPost;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('댓글이 작성되었습니다')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시물'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        child: Text(_post.userName[0]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _post.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(_post.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(label: Text(_post.category)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _post.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _post.content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _handleLike,
                        icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
                        label: Text('좋아요 ${_post.likes}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLiked ? Colors.red.shade50 : null,
                          foregroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.comment_outlined),
                        label: Text('댓글 ${_post.comments}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    '댓글 ${_comments.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._comments.map((comment) => _buildCommentItem(comment)),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(PostComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(comment.userName[0], style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(comment.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: '댓글을 입력하세요...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitComment(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _submitComment,
              icon: const Icon(Icons.send),
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
