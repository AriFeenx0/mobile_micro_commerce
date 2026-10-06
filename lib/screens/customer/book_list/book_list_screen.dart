// แสดงและค้นหารายการหนังสือสำหรับลูกค้า
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_routes.dart';
import '../../../models/book_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/book_provider.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/navigation/customer_bottom_nav.dart';
import '../book_detail/book_detail_screen.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final _authService = AuthService();
  late final TextEditingController _searchController;

  String? _profileUid;
  Future<UserModel?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<BookProvider>().appliedFilters.query,
    );
  }

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 420 ? 20.0 : 32.0;
            return Consumer<BookProvider>(
              builder: (context, booksProvider, _) {
                if (booksProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (booksProvider.error != null) {
                  return _CatalogState(
                    message: 'โหลดรายการหนังสือไม่ได้ กรุณาลองใหม่',
                    onRetry: booksProvider.refresh,
                  );
                }

                final categoryOptions = booksProvider.categories;
                final selectedCategory =
                    categoryOptions.contains(
                      booksProvider.appliedFilters.category,
                    )
                    ? booksProvider.appliedFilters.category
                    : 'ทั้งหมด';
                final visibleBooks = booksProvider.visibleBooks;

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
                          onChanged: booksProvider.setQuery,
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
                          itemCount: categoryOptions.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = categoryOptions[index];
                            final isSelected = category == selectedCategory;
                            return ChoiceChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (_) =>
                                  booksProvider.setCategory(category),
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
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
                                child: Center(child: Text('ไม่พบหนังสือ')),
                              ),
                            )
                          : SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _BookCard(
                                  book: visibleBooks[index],
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => BookDetailScreen(
                                        book: visibleBooks[index],
                                      ),
                                    ),
                                  ),
                                ),
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
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.onTap});

  final BookModel book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF999999)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: book.images.isEmpty
                      ? const ColoredBox(color: Color(0xFFD9D9D9))
                      : Image.network(
                          book.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: Color(0xFFD9D9D9)),
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
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF777777)),
              ),
              const SizedBox(height: 6),
              Text(
                book.category.isEmpty
                    ? book.language
                    : book.category.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogState extends StatelessWidget {
  const _CatalogState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('ลองใหม่')),
          ],
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
