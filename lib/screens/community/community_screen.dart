import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/post_model.dart';
import '../../utils/constants.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (_posts.isEmpty) setState(() => _isLoading = true);
    try {
      final posts = await _firestoreService.getPosts();
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint(e.toString());
      }
    }
  }

  Future<void> _handleLike(PostModel post) async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() {
      if (post.likes.contains(user.uid)) {
        post.likes.remove(user.uid);
      } else {
        post.likes.add(user.uid);
      }
    });

    try {
      await _firestoreService.toggleLike(post.id, user.uid);
    } catch (e) {
      _loadPosts();
    }
  }

  // --- YENİ PAYLAŞIM ---
  Future<void> _showAddPostDialog() async {
    final messageController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Paylasim'),
        content: TextField(
          controller: messageController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Motivasyon mesaji yaz...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Iptal')),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.trim().isNotEmpty) {
                Navigator.pop(context, messageController.text.trim());
              }
            },
            child: const Text('Paylas'),
          ),
        ],
      ),
    );

    if (result != null) {
      _sharePost(result);
    }
  }

  Future<void> _sharePost(String message) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paylasiliyor...')));
      final user = _authService.currentUser;
      if (user != null) {
        await _firestoreService.addPost(
          userId: user.uid,
          userName: user.displayName ?? 'Kullanici',
          message: message,
        );
        await _loadPosts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mesajiniz paylasildi!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  // --- YORUMLAR PENCERESİ ---
  void _showCommentsSheet(BuildContext context, PostModel post) {
    final commentController = TextEditingController();
    final user = _authService.currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                // Başlık
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Yorumlar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                ),
                const Divider(height: 1),

                // Yorum Listesi
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestoreService.getCommentsStream(post.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("Hic yorum yok. Ilk yorumu sen yaz!"));
                      }

                      final comments = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final commentData = comments[index].data() as Map<String, dynamic>;
                          final name = commentData['userName'] ?? 'Kullanici';
                          final msg = commentData['message'] ?? '';

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[200],
                              child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 12)),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(msg),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Yorum Yazma Alanı
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'Yorum yap...',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: AppColors.primary),
                        onPressed: () async {
                          if (commentController.text.trim().isNotEmpty && user != null) {
                            await _firestoreService.addComment(
                                post.id,
                                user.displayName ?? 'Kullanici',
                                commentController.text.trim()
                            );
                            commentController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Topluluk'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadPosts,
        child: _posts.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            return _buildPostCard(_posts[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPostDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.forum_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Henuz paylasim yok.\nIlk mesaji sen at!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(PostModel post) {
    final avatarColor = Colors.primaries[post.userName.length % Colors.primaries.length];
    final currentUser = _authService.currentUser;
    final isLiked = currentUser != null && post.likes.contains(currentUser.uid);
    final likeCount = post.likes.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Kısım: Profil ve İsim
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: avatarColor.withOpacity(0.2),
                  radius: 20,
                  child: Text(
                    post.userName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: avatarColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _formatDate(post.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mesaj İçeriği
            Text(
              post.message,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),

            const Divider(height: 24),

            // --- ALT ETKİLEŞİM BUTONLARI ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Beğeni Butonu
                Row(
                  children: [
                    InkWell(
                      onTap: () => _handleLike(post),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              likeCount > 0 ? '$likeCount' : 'Begen',
                              style: TextStyle(
                                color: isLiked ? Colors.red : Colors.grey[700],
                                fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Yorum Butonu
                InkWell(
                  onTap: () => _showCommentsSheet(context, post),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.mode_comment_outlined, color: Colors.grey, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Yorum Yap',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}