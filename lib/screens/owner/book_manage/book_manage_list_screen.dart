// แสดงและจัดการหนังสือของเจ้าของร้าน
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_routes.dart';
import '../../../models/book_model.dart';
import '../../../models/book_volume_model.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/book_service.dart';
import '../../../widgets/navigation/owner_bottom_nav.dart';
import 'book_manage_form_screen.dart';

class BookManageListScreen extends StatefulWidget {
  const BookManageListScreen({super.key});

  @override
  State<BookManageListScreen> createState() => _BookManageListScreenState();
}

class _BookManageListScreenState extends State<BookManageListScreen> {
  final _authService = AuthService();
  final _bookService = BookService();
  final _searchController = TextEditingController();

  String? _profileUid;
  Future<UserModel?>? _profileFuture;
  String? _booksOwnerId;
  Stream<List<BookModel>>? _booksStream;

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
          return const _ListStatePage(
            message: 'กำลังตรวจสอบบัญชี',
            loading: true,
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const _ListStatePage(
            message: 'กรุณาเข้าสู่ระบบด้วยบัญชีเจ้าของร้าน',
          );
        }

        if (_profileUid != user.uid) {
          _profileUid = user.uid;
          _profileFuture = _authService.getUserProfile(user.uid);
          _booksOwnerId = user.uid;
          _booksStream = _bookService.watchBooksByOwner(user.uid);
        }

        return FutureBuilder<UserModel?>(
          future: _profileFuture,
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _ListStatePage(
                message: 'กำลังตรวจสอบสิทธิ์เจ้าของร้าน',
                loading: true,
              );
            }
            if (profileSnapshot.hasError) {
              return const _ListStatePage(
                message: 'อ่านข้อมูลบัญชีไม่ได้ กรุณาลองใหม่',
              );
            }
            if (profileSnapshot.data?.role != UserRole.owner) {
              return const _ListStatePage(
                message: 'หน้านี้สำหรับบัญชีเจ้าของร้านเท่านั้น',
              );
            }

            return _buildBookList(_booksOwnerId!);
          },
        );
      },
    );
  }

  Widget _buildBookList(String ownerId) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('รายการหนังสือ'),
        actions: [
          IconButton(
            tooltip: 'เพิ่มหนังสือ',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.ownerBookForm),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ค้นหาหนังสือ',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'ล้างการค้นหา',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<BookModel>>(
              stream: _booksStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ListStatePage(
                    message:
                        'โหลดรายการหนังสือไม่ได้ กรุณาตรวจสอบสิทธิ์ Firestore',
                    actionLabel: 'ลองใหม่',
                    onAction: () => setState(() {
                      _booksStream = _bookService.watchBooksByOwner(ownerId);
                    }),
                  );
                }

                final search = _searchController.text.trim().toLowerCase();
                final books = (snapshot.data ?? []).where((book) {
                  if (search.isEmpty) return true;
                  return [
                    book.title,
                    book.author,
                    book.publisher,
                    ...book.category,
                  ].any((value) => value.toLowerCase().contains(search));
                }).toList();

                if (books.isEmpty) {
                  return _ListStatePage(
                    message: snapshot.data?.isEmpty ?? true
                        ? 'ยังไม่มีหนังสือในร้าน'
                        : 'ไม่พบหนังสือที่ค้นหา',
                    actionLabel: snapshot.data?.isEmpty ?? true
                        ? 'เพิ่มหนังสือ'
                        : null,
                    onAction: snapshot.data?.isEmpty ?? true
                        ? () => Navigator.pushNamed(
                            context,
                            AppRoutes.ownerBookForm,
                          )
                        : null,
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 700 ? 3 : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                      itemCount: books.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.64,
                      ),
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return _BookCard(
                          book: book,
                          onEdit: () => _editBook(book),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: OwnerBottomNav(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          final route = switch (index) {
            0 => AppRoutes.ownerDashboard,
            2 => AppRoutes.ownerOrders,
            3 => AppRoutes.chats,
            4 => AppRoutes.profile,
            _ => null,
          };
          if (route != null) Navigator.pushReplacementNamed(context, route);
        },
      ),
    );
  }

  Future<void> _editBook(BookModel book) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => BookManageFormScreen(book: book)),
    );
  }
}

class _BookCard extends StatefulWidget {
  const _BookCard({required this.book, required this.onEdit});

  final BookModel book;
  final VoidCallback onEdit;

  @override
  State<_BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<_BookCard> {
  final _bookService = BookService();
  late Stream<List<BookVolumeModel>> _volumesStream;

  @override
  void initState() {
    super.initState();
    _volumesStream = _bookService.watchBookVolumes(widget.book.id);
  }

  @override
  void didUpdateWidget(covariant _BookCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id) {
      _volumesStream = _bookService.watchBookVolumes(widget.book.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCCCCCC)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onEdit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: book.images.isEmpty
                    ? const ColoredBox(color: Color(0xFFE1E1E1))
                    : Image.network(
                        book.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const ColoredBox(color: Color(0xFFE1E1E1)),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${book.volumeCount} เล่ม · ${book.coverType} · ${book.language}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    StreamBuilder<List<BookVolumeModel>>(
                      stream: _volumesStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text(
                            'โหลดสต็อกไม่สำเร็จ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFB3261E),
                              fontSize: 12,
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Text(
                            'กำลังโหลดสต็อก…',
                            style: TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 12,
                            ),
                          );
                        }

                        final stock = snapshot.data!.fold<int>(
                          0,
                          (total, volume) => total + volume.stock,
                        );
                        return Text(
                          stock > 0
                              ? 'คงเหลือ $stock เล่ม'
                              : 'หมดสต็อก',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: stock > 0
                                ? const Color(0xFF39834A)
                                : const Color(0xFFB3261E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListStatePage extends StatelessWidget {
  const _ListStatePage({
    required this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

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
                if (loading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
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
