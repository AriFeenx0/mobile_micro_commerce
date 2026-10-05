import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../models/book_model.dart';
import '../models/book_volume_model.dart';
import '../services/storage_service.dart';

class BookService {
  BookService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    StorageService? storageService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storageService = storageService ?? StorageService();

  static const String booksCollection = 'books';
  static const String usersCollection = 'users';
  static const String volumesCollection = 'volumes';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StorageService _storageService;

  CollectionReference<Map<String, dynamic>> get _books =>
      _firestore.collection(booksCollection);

  Stream<List<BookModel>> watchBooks() {
    return _books.snapshots().map((snapshot) {
      final books = snapshot.docs
          .map((document) => BookModel.fromJson(document.id, document.data()))
          .toList();
      books.sort(
        (first, second) => (second.createdAt ?? DateTime(0)).compareTo(
          first.createdAt ?? DateTime(0),
        ),
      );
      return books;
    });
  }

  Stream<List<BookModel>> watchBooksByOwner(String ownerId) {
    return _books.where('ownerId', isEqualTo: ownerId).snapshots().map((
      snapshot,
    ) {
      final books = snapshot.docs
          .map((document) => BookModel.fromJson(document.id, document.data()))
          .toList();
      books.sort(
        (first, second) => (second.createdAt ?? DateTime(0)).compareTo(
          first.createdAt ?? DateTime(0),
        ),
      );
      return books;
    });
  }

  Future<List<BookVolumeModel>> getBookVolumes(String bookId) async {
    final snapshot = await _books
        .doc(bookId)
        .collection(volumesCollection)
        .get();
    final volumes = snapshot.docs
        .map(
          (document) =>
              BookVolumeModel.fromJson(document.id, bookId, document.data()),
        )
        .toList();
    volumes.sort(
      (first, second) => first.volumeNumber.compareTo(second.volumeNumber),
    );
    return volumes;
  }

  Stream<List<BookVolumeModel>> watchBookVolumes(String bookId) {
    return _books.doc(bookId).collection(volumesCollection).snapshots().map((
      snapshot,
    ) {
      final volumes = snapshot.docs
          .map(
            (document) =>
                BookVolumeModel.fromJson(document.id, bookId, document.data()),
          )
          .toList();
      volumes.sort(
        (first, second) => first.volumeNumber.compareTo(second.volumeNumber),
      );
      return volumes;
    });
  }

  Future<BookModel> createBook({
    required BookModel book,
    required List<BookVolumeModel> volumes,
    required List<XFile> images,
  }) async {
    final owner = await _requireShopOwner();
    if (book.ownerId != owner.uid) {
      throw StateError('ไม่สามารถเพิ่มหนังสือในบัญชีของผู้ใช้อื่นได้');
    }
    if (volumes.isEmpty) throw ArgumentError('ต้องมีข้อมูลอย่างน้อยหนึ่งเล่ม');

    final bookReference = _books.doc();
    var created = false;
    var imageUrls = <String>[];

    try {
      imageUrls = await _storageService.uploadBookImages(
        ownerId: owner.uid,
        bookId: bookReference.id,
        images: images,
      );

      final savedBook = BookModel(
        id: bookReference.id,
        title: book.title,
        author: book.author,
        publisher: book.publisher,
        description: book.description,
        coverType: book.coverType,
        language: book.language,
        category: book.category,
        images: imageUrls,
        isSet: book.isSet,
        volumeCount: volumes.length,
        ownerId: owner.uid,
        createdAt: DateTime.now(),
      );

      await bookReference.set(savedBook.toJson());
      created = true;

      final batch = _firestore.batch();
      for (final volume in volumes) {
        final volumeReference = bookReference
            .collection(volumesCollection)
            .doc('volume_${volume.volumeNumber}');
        batch.set(volumeReference, volume.toJson());
      }
      await batch.commit();

      return savedBook;
    } catch (_) {
      if (created) {
        try {
          await bookReference.delete();
        } on FirebaseException {
          // Preserve the original write error if cleanup is denied.
        }
      }
      rethrow;
    }
  }

  Future<BookModel> updateBook({
    required BookModel book,
    required List<BookVolumeModel> volumes,
    required List<XFile> newImages,
    required List<String> retainedImageUrls,
  }) async {
    final owner = await _requireShopOwner();
    if (book.id.isEmpty) throw ArgumentError('ไม่พบรหัสหนังสือ');
    if (book.ownerId != owner.uid) {
      throw StateError('ไม่สามารถแก้ไขหนังสือของผู้ใช้อื่นได้');
    }
    if (volumes.isEmpty) throw ArgumentError('ต้องมีข้อมูลอย่างน้อยหนึ่งเล่ม');

    final bookReference = _books.doc(book.id);
    final bookSnapshot = await bookReference.get();
    final existingData = bookSnapshot.data();
    if (!bookSnapshot.exists || existingData == null) {
      throw StateError('ไม่พบหนังสือที่ต้องการแก้ไข');
    }
    if (existingData['ownerId'] != owner.uid) {
      throw StateError('ไม่สามารถแก้ไขหนังสือของผู้ใช้อื่นได้');
    }

    final originalImageUrls = List<String>.from(
      existingData['images'] as List? ?? const [],
    );
    if (!originalImageUrls.toSet().containsAll(retainedImageUrls)) {
      throw StateError('พบรูปภาพที่ไม่ได้เป็นของหนังสือนี้');
    }

    var newImageUrls = <String>[];
    try {
      newImageUrls = await _storageService.uploadBookImages(
        ownerId: owner.uid,
        bookId: book.id,
        images: newImages,
      );
      final savedBook = BookModel(
        id: book.id,
        title: book.title,
        author: book.author,
        publisher: book.publisher,
        description: book.description,
        coverType: book.coverType,
        language: book.language,
        category: book.category,
        images: [...retainedImageUrls, ...newImageUrls],
        isSet: book.isSet,
        volumeCount: volumes.length,
        ownerId: owner.uid,
        createdAt:
            book.createdAt ??
            (existingData['createdAt'] as Timestamp?)?.toDate(),
      );

      final existingVolumes = await bookReference
          .collection(volumesCollection)
          .get();
      final volumeIds = volumes
          .map((volume) => 'volume_${volume.volumeNumber}')
          .toSet();
      final batch = _firestore.batch();
      for (final document in existingVolumes.docs) {
        if (!volumeIds.contains(document.id)) batch.delete(document.reference);
      }
      for (final volume in volumes) {
        final volumeReference = bookReference
            .collection(volumesCollection)
            .doc('volume_${volume.volumeNumber}');
        batch.set(volumeReference, volume.toJson());
      }
      batch.set(bookReference, savedBook.toJson());
      await batch.commit();

      return savedBook;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> deleteBook(String bookId) async {
    final owner = await _requireShopOwner();
    final bookReference = _books.doc(bookId);
    final bookSnapshot = await bookReference.get();
    final bookData = bookSnapshot.data();
    if (!bookSnapshot.exists || bookData == null) {
      throw StateError('ไม่พบหนังสือที่ต้องการลบ');
    }
    if (bookData['ownerId'] != owner.uid) {
      throw StateError('ไม่สามารถลบหนังสือของผู้ใช้อื่นได้');
    }

    final volumeSnapshot = await bookReference
        .collection(volumesCollection)
        .get();
    final volumeReferences = volumeSnapshot.docs
        .map((document) => document.reference)
        .toList();
    for (var start = 0; start < volumeReferences.length; start += 400) {
      final end = (start + 400).clamp(0, volumeReferences.length);
      final batch = _firestore.batch();
      for (final reference in volumeReferences.sublist(start, end)) {
        batch.delete(reference);
      }
      await batch.commit();
    }

    await bookReference.delete();
  }

  Future<User> _requireShopOwner() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('กรุณาเข้าสู่ระบบก่อนจัดการหนังสือ');

    final profile = await _firestore
        .collection(usersCollection)
        .doc(user.uid)
        .get();
    if (profile.data()?['role'] != 'owner') {
      throw StateError('บัญชีนี้ไม่มีสิทธิ์จัดการหนังสือ');
    }
    return user;
  }
}
