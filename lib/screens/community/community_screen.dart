import 'package:flutter/material.dart';
import '../../services/auth_service.dart';      // İki nokta (..) yerine (../..)
import '../../services/firestore_service.dart'; // Çünkü artık bir klasör daha derindeyiz
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

  // Paylaşımları çekme (Pull-to-refresh için de kullanılır)
  Future<void> _loadPosts() async {
    // Eğer sayfa ilk açılışı değilse loading göstermeden arkada yenile
    // Ama ilk açılışsa loading göster
    if (_posts.isEmpty) {
      setState(() => _isLoading = true);
    }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Yeni Paylaşım Dialogu
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Iptal'),
          ),
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

  // Paylaşımı kaydetme işlemi
  Future<void> _sharePost(String message) async {
    try {
      // Loading göster (Basit bir snackbar ile bilgi verelim)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylasiliyor...')),
      );

      final user = _authService.currentUser;
      if (user != null) {
        await _firestoreService.addPost(
          userId: user.uid,
          userName: user.displayName ?? 'Kullanici', // İsmi o an kaydediyoruz
          message: message,
        );

        // Listeyi yenile
        await _loadPosts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mesajiniz paylasildi!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Tarih formatlayıcı (Basit)
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
        onRefresh: _loadPosts, // Aşağı çekince çalışacak fonksiyon
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
      // ListView kullanıyoruz ki RefreshIndicator çalışabilsin (scrollable olmalı)
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
    // Rastgele profil rengi veya sabit bir renk
    final avatarColor = Colors.primaries[post.userName.length % Colors.primaries.length];

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

            // Alt kısım (Beğeni butonu vs. buraya gelecek - Şimdilik boş)
          ],
        ),
      ),
    );
  }
}