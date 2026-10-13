import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_micro_commerce/models/book_volume_model.dart';

void main() {
  group('BookVolumeModel reservations', () {
    test('counts active reservations and ignores expired payment holds', () {
      final now = DateTime.now();
      final volume = BookVolumeModel(
        id: 'volume_1',
        bookId: 'book_1',
        volumeNumber: 1,
        price: 100,
        stock: 6,
        condition: 'ใหม่',
        reservations: {
          'active': {
            'quantity': 2,
            'status': 'pendingPayment',
            'expiresAt': Timestamp.fromDate(
              now.add(const Duration(minutes: 5)),
            ),
          },
          'expired': {
            'quantity': 2,
            'status': 'pendingPayment',
            'expiresAt': Timestamp.fromDate(
              now.subtract(const Duration(seconds: 1)),
            ),
          },
          'review': {
            'quantity': 1,
            'status': 'pendingSlipReview',
            'expiresAt': null,
          },
        },
      );

      expect(volume.reservedQuantity, 3);
      expect(volume.availableStock, 3);
      expect(volume.isAvailable, isTrue);
    });

    test('reports unavailable when active reservations consume stock', () {
      final volume = BookVolumeModel(
        id: 'volume_1',
        bookId: 'book_1',
        volumeNumber: 1,
        price: 100,
        stock: 2,
        condition: 'ใหม่',
        reservations: {
          'active': {
            'quantity': 2,
            'status': 'pendingSlipReview',
            'expiresAt': null,
          },
        },
      );

      expect(volume.availableStock, 0);
      expect(volume.isAvailable, isFalse);
    });
  });
}
