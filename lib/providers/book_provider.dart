// เก็บรายการหนังสือและสถานะตัวกรองไว้ระหว่างเปลี่ยนหน้า
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/book_model.dart';
import '../services/book_service.dart';

class BookFilters {
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

  List<BookModel> get books => List.unmodifiable(_books);
  bool get isLoading => _isLoading;
  Object? get error => _error;
  BookFilters get draftFilters => _draftFilters;
  BookFilters get appliedFilters => _appliedFilters;

  List<String> get categories {
    final values = <String>{
      for (final book in _books) ...book.category,
    }.toList()..sort();
    return ['ทั้งหมด', ...values];
  }

  List<BookModel> get visibleBooks {
    final query = _appliedFilters.query.trim().toLowerCase();
    final category = _appliedFilters.category;
    return _books.where((book) {
      final matchesCategory =
          category == 'ทั้งหมด' || book.category.contains(category);
      final matchesQuery =
          query.isEmpty ||
          [
            book.title,
            book.author,
            book.publisher,
            book.description,
            ...book.category,
          ].any((value) => value.toLowerCase().contains(query));
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void setQuery(String query) {
    _draftFilters = _draftFilters.copyWith(query: query);
    _appliedFilters = _appliedFilters.copyWith(query: query);
    notifyListeners();
  }

  void setCategory(String category) {
    _draftFilters = _draftFilters.copyWith(category: category);
    _appliedFilters = _appliedFilters.copyWith(category: category);
    notifyListeners();
  }

  void updateDraftFilters(BookFilters filters) {
    _draftFilters = filters;
    notifyListeners();
  }

  void applyFilters() {
    _appliedFilters = _draftFilters;
    notifyListeners();
  }

  void refresh() {
    if (_subscribedUserId == null) return;
    _isLoading = _books.isEmpty;
    _error = null;
    notifyListeners();
    _subscribeToBooks();
  }

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

  void _subscribeToBooks() {
    _booksSubscription?.cancel();
    _booksSubscription = _bookService.watchBooks().listen(
      (books) {
        _books = books;
        _isLoading = false;
        _error = null;
        if (!_categoriesContain(_draftFilters.category)) {
          _draftFilters = _draftFilters.copyWith(category: 'ทั้งหมด');
          _appliedFilters = _appliedFilters.copyWith(category: 'ทั้งหมด');
        }
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _error = error;
        notifyListeners();
      },
    );
  }

  bool _categoriesContain(String category) =>
      category == 'ทั้งหมด' ||
      _books.any((book) => book.category.contains(category));

  @override
  void dispose() {
    _authSubscription.cancel();
    _booksSubscription?.cancel();
    super.dispose();
  }
}
