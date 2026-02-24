import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firestore_service.dart';
import 'trip_journal_screen.dart';

class MemoryVault extends StatefulWidget {
  const MemoryVault({super.key});

  @override
  State<MemoryVault> createState() => _MemoryVaultState();
}

class _MemoryVaultState extends State<MemoryVault> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isUploading = false;
  int _selectedTab = 0; // 0: Memories, 1: Journals

  Future<void> _pickAndUploadMemory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to save memories."), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null || !mounted) return;

    String caption = '';
    String location = '';

    final bool? shouldUpload = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassCardDecoration(borderRadius: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("New Memory", style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text("Add details to your travel moment", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 24),
                TextField(
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: "Caption (e.g. Sunset in Santorini)",
                    hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.4)),
                    filled: true,
                    fillColor: AppTheme.surfaceLight.withOpacity(0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.accentAmber)),
                  ),
                  onChanged: (v) => caption = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: "Location",
                    hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.4)),
                    filled: true,
                    fillColor: AppTheme.surfaceLight.withOpacity(0.5),
                    prefixIcon: Icon(LucideIcons.mapPin, color: AppTheme.accentAmber.withOpacity(0.6), size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.accentAmber)),
                  ),
                  onChanged: (v) => location = v,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(gradient: AppTheme.amberGradient, borderRadius: BorderRadius.circular(12)),
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Upload", style: TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldUpload != true) return;
    setState(() => _isUploading = true);

    try {
      final storageRef = FirebaseStorage.instance.ref()
          .child('users').child(user.uid).child('memories')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        uploadTask = storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        uploadTask = storageRef.putFile(File(image.path));
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestoreService.addMemory(user.uid, {
        'url': downloadUrl,
        'caption': caption.isNotEmpty ? caption : 'Untitled Memory',
        'location': location.isNotEmpty ? location : 'Unknown Location',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Memory saved!"), backgroundColor: AppTheme.accentAmber),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildTabs(),
            const SizedBox(height: 16),
            Expanded(
              child: user == null
                  ? const Center(child: Text("Please log in to view vault.", style: TextStyle(color: AppTheme.textPrimary)))
                  : StreamBuilder<QuerySnapshot>(
                      stream: _selectedTab == 0 ? _firestoreService.getMemories(user.uid) : _firestoreService.getJournals(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.accentAmber));
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return _buildEmptyState();
                        }
                        if (_selectedTab == 0) {
                          return _buildMemoriesGrid(docs);
                        } else {
                          return _buildJournalsList(docs);
                        }
                      },
                    ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Memory Vault", style: TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text("Your precious travel moments", style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 13)),
              ],
            ),
          ),
          
          // AI Journal Button
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TripJournalScreen()));
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.accentViolet.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accentViolet.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.penTool, color: AppTheme.accentViolet, size: 16),
                  SizedBox(width: 8),
                  Text("Journal", style: TextStyle(color: AppTheme.accentViolet, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),

          // Upload Button
          GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadMemory,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: _isUploading ? null : AppTheme.amberGradient,
                color: _isUploading ? AppTheme.surfaceLight : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isUploading ? null : [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.3), blurRadius: 12)],
              ),
              child: _isUploading
                  ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlack)))
                  : const Icon(LucideIcons.plus, color: AppTheme.primaryBlack, size: 20),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildTabItem(0, "Memories"),
          const SizedBox(width: 16),
          _buildTabItem(1, "AI Journals"),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildTabItem(int index, String title) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(
            color: isSelected ? AppTheme.accentAmber : AppTheme.textSecondary,
            fontSize: 16, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          )),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 3, width: isSelected ? 30 : 0,
            decoration: BoxDecoration(color: AppTheme.accentAmber, borderRadius: BorderRadius.circular(2)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accentAmber.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(_selectedTab == 0 ? LucideIcons.camera : LucideIcons.book, color: AppTheme.accentAmber.withOpacity(0.5), size: 36),
          ),
          const SizedBox(height: 20),
          Text(_selectedTab == 0 ? "No memories yet" : "No journals yet", style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(_selectedTab == 0 ? "Tap + to capture your first travel moment" : "Create one from your memories",
              style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 14)),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildMemoriesGrid(List<QueryDocumentSnapshot> docs) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        return _MemoryCard(
          url: data['url'] ?? '', caption: data['caption'] ?? 'Memory', location: data['location'] ?? '',
        ).animate().fadeIn(delay: Duration(milliseconds: 60 * index)).scale(begin: const Offset(0.95, 0.95));
      },
    );
  }

  Widget _buildJournalsList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (ctx, i) {
        final data = docs[i].data() as Map<String, dynamic>;
        final title = data['title'] ?? 'AI Journal';
        final coverImage = data['coverImage'] ?? '';
        final story = data['story'] ?? '';
        final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: AppTheme.glassCardDecoration(borderRadius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (coverImage.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(coverImage, fit: BoxFit.cover),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                        Text('${date.day}/${date.month}/${date.year}', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      story, maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 100 * i)).slideY(begin: 0.1, end: 0);
      },
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final String url, caption, location;

  const _MemoryCard({super.key, required this.url, required this.caption, required this.location});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(url, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.surfaceDark,
                  child: const Icon(LucideIcons.image, color: AppTheme.accentAmber, size: 28))),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                stops: const [0.35, 1.0],
                colors: [Colors.transparent, AppTheme.primaryBlack.withOpacity(0.85)],
              ),
            ),
          ),
          Positioned(
            bottom: 14, left: 12, right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(caption, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14, height: 1.2)),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(LucideIcons.mapPin, color: AppTheme.accentAmber, size: 10),
                    const SizedBox(width: 4),
                    Expanded(child: Text(location, style: const TextStyle(color: AppTheme.accentAmber, fontSize: 11), overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
