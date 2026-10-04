import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/navigation/customer_bottom_nav.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final _authService = AuthService();
  final _searchController = TextEditingController();

  String _selectedCategory = 'ทั้งหมด';
  String? _profileUid;
  Future<UserModel?>? _profileFuture;

  static const _categories = ['ทั้งหมด', 'หมวดหมู่1', 'หมวดหมู่2'];
  static const _books = [
    _BookPreview(title: 'ชื่อสินค้า', subtitle: 'Text รอง', category: 'หมวดหมู่1'),
    _BookPreview(title: 'ชื่อสินค้า', subtitle: 'Text รอง', category: 'หมวดหมู่2'),
    _BookPreview(title: 'ชื่อสินค้า', subtitle: 'Text รอง', category: 'หมวดหมู่1'),
    _BookPreview(title: 'ชื่อสินค้า', subtitle: 'Text รอง', category: 'หมวดหมู่2'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _AccessPage(
            message: 'กำลังตรวจสอบสถานะการเข้าสู่ระบบ',
            showProgress: true,
          );
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          return _AccessPage(
            message: 'กรุณาเข้าสู่ระบบเพื่อดูรายการสินค้า',
            actionLabel: 'เข้าสู่ระบบ',
            onAction: _goToLogin,
          );
        }

        if (_profileUid != firebaseUser.uid) {
          _profileUid = firebaseUser.uid;
          _profileFuture = _authService.getUserProfile(firebaseUser.uid);
        }

        return FutureBuilder<UserModel?>(
          future: _profileFuture,
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _AccessPage(
                message: 'กำลังตรวจสอบสิทธิ์บัญชี',
                showProgress: true,
              );
            }

            if (profileSnapshot.hasError) {
              return _AccessPage(
                message: 'ตรวจสอบสิทธิ์ไม่ได้ กรุณาลองใหม่อีกครั้ง',
                actionLabel: 'ลองอีกครั้ง',
                onAction: () => _reloadProfile(firebaseUser.uid),
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null || profile.role != UserRole.customer) {
              return _AccessPage(
                message: profile == null
                    ? 'ไม่พบบัญชีลูกค้าที่ผูกกับผู้ใช้นี้'
                    : 'หน้านี้สำหรับบัญชี Customer เท่านั้น',
                actionLabel: 'ออกจากระบบ',
                onAction: _signOut,
              );
            }

            return _buildCatalog();
          },
        );
      },
    );
  }

  Widget _buildCatalog() {
    final query = _searchController.text.trim().toLowerCase();
    final visibleBooks = _books.where((book) {
      final matchesCategory = _selectedCategory == 'ทั้งหมด' ||
          book.category == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          '${book.title} ${book.subtitle}'.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 420 ? 20.0 : 32.0;
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    48,
                    horizontalPadding,
                    24,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'ค้นหา...',
                        hintStyle: const TextStyle(
                          color: Color(0xFFB8B8B8),
                          fontSize: 16,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFF49413F),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFF292929),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 42,
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = category == _selectedCategory;
                        return ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) => setState(() {
                            _selectedCategory = category;
                          }),
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF222222),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF222222)
                                : const Color(0xFF777777),
                          ),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        );
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    22,
                    horizontalPadding,
                    28,
                  ),
                  sliver: visibleBooks.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 36),
                            child: Center(child: Text('ไม่พบสินค้า')),
                          ),
                        )
                      : SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _BookCard(book: visibleBooks[index]),
                            childCount: visibleBooks.length,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 28,
                                childAspectRatio: 0.72,
                              ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: CustomerBottomNav(
        selectedIndex: 0,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }

  void _onDestinationSelected(int index) {
    final route = switch (index) {
      1 => AppRoutes.customerCart,
      2 => AppRoutes.chats,
      3 => AppRoutes.profile,
      _ => null,
    };
    if (route != null) Navigator.pushReplacementNamed(context, route);
  }

  void _reloadProfile(String uid) {
    setState(() {
      _profileFuture = _authService.getUserProfile(uid);
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) _goToLogin();
  }

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (_) => false,
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});

  final _BookPreview book;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF999999)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                border: Border.all(color: const Color(0xFFA5A5A5), width: 1.5),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, color: Colors.black),
          ),
          Text(
            book.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF777777)),
          ),
          const SizedBox(height: 6),
          const Text(
            'ราคา / เล่ม',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class _AccessPage extends StatelessWidget {
  const _AccessPage({
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showProgress) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                ],
                Text(message, textAlign: TextAlign.center),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookPreview {
  const _BookPreview({
    required this.title,
    required this.subtitle,
    required this.category,
  });

  final String title;
  final String subtitle;
  final String category;
}