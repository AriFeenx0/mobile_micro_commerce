/// เก็บรายการหนังสือและสถานะตัวกรองไว้ระหว่างเปลี่ยนหน้า
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/book_model.dart';
import '../services/book_service.dart';

class BookFilters {
  /// สร้างชุดตัวกรองเริ่มต้นหรือกำหนดเงื่อนไขที่ต้องการ
  const BookFilters({
    this.query = '',
    this.category = 'ทั้งหมด',
    this.author = '',
    this.publisher = '',
    this.language = '',
    this.condition = '',
    this.minPrice,
    this.maxPrice,
  });

  final String query;
  final String category;
  final String author;
  final String publisher;
  final String language;
  final String condition;
  final double? minPrice;
  final double? maxPrice;

  /// คัดลอกชุดตัวกรองโดยเปลี่ยนค่าที่ระบุหรือเคลียร์ช่วงราคาได้
  BookFilters copyWith({
    String? query,
    String? category,
    String? author,
    String? publisher,
    String? language,
    String? condition,
    double? minPrice,
    double? maxPrice,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return BookFilters(
      query: query ?? this.query,
      category: category ?? this.category,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      language: language ?? this.language,
      condition: condition ?? this.condition,
      minPrice: clearMinPrice ? null : minPrice ?? this.minPrice,
      maxPrice: clearMaxPrice ? null : maxPrice ?? this.maxPrice,
    );
  }
}

class BookProvider extends ChangeNotifier {
  /// เริ่มติดตามการเข้าสู่ระบบและโหลดหนังสือของผู้ใช้ปัจจุบัน
  BookProvider({BookService? bookService, FirebaseAuth? auth})
    : _bookService = bookService ?? BookService(),
      _auth = auth ?? FirebaseAuth.instance {
    _authSubscription = _auth.authStateChanges().listen(_handleAuthChange);
  }

  final BookService _bookService;
  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<List<BookModel>>? _booksSubscription;
  String? _subscribedUserId;
  List<BookModel> _books = const [];
  bool _isLoading = true;
  Object? _error;
  BookFilters _draftFilters = const BookFilters();
  BookFilters _appliedFilters = const BookFilters();

  /// รายการหนังสือแบบอ่านอย่างเดียว
  List<BookModel> get books => List.unmodifiable(_books);

  /// ระบุว่ากำลังโหลดรายการหนังสือ
  bool get isLoading => _isLoading;

  /// ข้อผิดพลาดล่าสุดจากการโหลดหนังสือ
  Object? get error => _error;

  /// ตัวกรองที่กำลังแก้ไขก่อนนำไปใช้
  BookFilters get draftFilters => _draftFilters;

  /// ตัวกรองที่ใช้คัดรายการหนังสืออยู่
  BookFilters get appliedFilters => _appliedFilters;

  /// หมวดหมู่ที่มีในรายการ พร้อมตัวเลือกทั้งหมด
  List<String> get categories {
    final values = <String>{
      for (final book in _books) ...book.category,
    }.toList()..sort();
    return ['ทั้งหมด', ...values];
  }

  /// สำนักพิมพ์ที่มีอยู่ในรายการหนังสือ
  List<String> get publishers => _sortedValues(_books.map((book) => book.publisher));

  /// ภาษาที่มีอยู่ในรายการหนังสือ
  List<String> get languages => _sortedValues(_books.map((book) => book.language));

  /// จำนวนเงื่อนไขหมวดหมู่ ผู้เขียน สำนักพิมพ์ และภาษาที่กำลังใช้
  int get activeFilterCount {
    var count = 0;
    if (_appliedFilters.category != 'ทั้งหมด') count++;
    if (_appliedFilters.author.trim().isNotEmpty) count++;
    if (_appliedFilters.publisher.isNotEmpty) count++;
    if (_appliedFilters.language.isNotEmpty) count++;
    return count;
  }

  /// หนังสือที่ตรงกับตัวกรองที่นำไปใช้แล้ว
  List<BookModel> get visibleBooks {
    final query = _appliedFilters.query.trim().toLowerCase();
    final category = _appliedFilters.category;
    return _books.where((book) {
      final matchesCategory =
          category == 'ทั้งหมด' || book.category.contains(category);
      final author = _appliedFilters.author.trim().toLowerCase();
      final matchesAuthor =
          author.isEmpty || book.author.toLowerCase().contains(author);
      final publisher = _appliedFilters.publisher;
      final matchesPublisher =
          publisher.isEmpty || book.publisher == publisher;
      final language = _appliedFilters.language;
      final matchesLanguage = language.isEmpty || book.language == language;
      final matchesQuery =
          query.isEmpty ||
          [
            book.title,
            book.author,
            book.publisher,
            book.description,
            ...book.category,
          ].any((value) => value.toLowerCase().contains(query));
      return matchesCategory &&
          matchesAuthor &&
          matchesPublisher &&
          matchesLanguage &&
          matchesQuery;
    }).toList();
  }

  /// อัปเดตคำค้นทั้งในตัวกรองร่างและตัวกรองที่ใช้อยู่ทันที
  void setQuery(String query) {
    _draftFilters = _draftFilters.copyWith(query: query);
    _appliedFilters = _appliedFilters.copyWith(query: query);
    notifyListeners();
  }

  /// อัปเดตหมวดหมู่ทั้งในตัวกรองร่างและตัวกรองที่ใช้อยู่ทันที
  void setCategory(String category) {
    _draftFilters = _draftFilters.copyWith(category: category);
    _appliedFilters = _appliedFilters.copyWith(category: category);
    notifyListeners();
  }

  /// บันทึกเงื่อนไขร่างไว้จนกว่าจะนำไปใช้
  void updateDraftFilters(BookFilters filters) {
    _draftFilters = filters;
    notifyListeners();
  }

  /// นำตัวกรองร่างทั้งหมดไปใช้กับรายการหนังสือ
  void applyFilters() {
    _appliedFilters = _draftFilters;
    notifyListeners();
  }

  /// โหลดรายการหนังสือใหม่จากแหล่งข้อมูลที่ติดตามอยู่
  void refresh() {
    if (_subscribedUserId == null) return;
    _isLoading = _books.isEmpty;
    _error = null;
    notifyListeners();
    _subscribeToBooks();
  }

  /// เปลี่ยนการติดตามรายการหนังสือเมื่อบัญชีผู้ใช้เปลี่ยน
  void _handleAuthChange(User? user) {
    if (user?.uid == _subscribedUserId) return;
    _subscribedUserId = user?.uid;
    _booksSubscription?.cancel();
    _booksSubscription = null;

    if (user == null) {
      _books = const [];
      _isLoading = false;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    _subscribeToBooks();
  }

  /// สมัครรับรายการหนังสือและปรับสถานะเมื่อมีข้อมูลหรือข้อผิดพลาด
  void _subscribeToBooks() {
    _booksSubscription?.cancel();
    _booksSubscription = _bookService.watchBooks().listen(
      (books) {
        _books = books;
        _isLoading = false;
        _error = null;
        _draftFilters = _normalizeFilters(_draftFilters);
        _appliedFilters = _normalizeFilters(_appliedFilters);
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _error = error;
        notifyListeners();
      },
    );
  }

  /// ตรวจว่าหมวดหมู่ยังมีอยู่ในรายการหนังสือหรือไม่
  bool _categoriesContain(String category) =>
      category == 'ทั้งหมด' ||
      _books.any((book) => book.category.contains(category));

  /// เคลียร์ตัวกรองที่ค่าไม่อยู่ในรายการหนังสือปัจจุบัน
  BookFilters _normalizeFilters(BookFilters filters) {
    return filters.copyWith(
      category: _categoriesContain(filters.category) ? filters.category : 'ทั้งหมด',
      publisher:
          filters.publisher.isEmpty ||
              _books.any((book) => book.publisher == filters.publisher)
          ? filters.publisher
          : '',
      language:
          filters.language.isEmpty ||
              _books.any((book) => book.language == filters.language)
          ? filters.language
          : '',
    );
  }

  /// คืนค่าที่ไม่ว่างโดยไม่ซ้ำและเรียงตามตัวอักษร
  List<String> _sortedValues(Iterable<String> values) {
    final sorted = values.where((value) => value.trim().isNotEmpty).toSet().toList()
      ..sort();
    return sorted;
  }

  /// ยกเลิกการติดตามการเข้าสู่ระบบและรายการหนังสือ
  @override
  void dispose() {
    _authSubscription.cancel();
    _booksSubscription?.cancel();
    super.dispose();
  }
}
