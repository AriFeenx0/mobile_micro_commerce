// โมเดลหนังสือและแปลงข้อมูลสำหรับจัดเก็บใน Firestore
import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String title;
  final String author;
  final String publisher;
  final String description;
  final String coverType; // "ปกอ่อน" | "ปกแข็ง"
  final String language; // "ไทย" | "อังกฤษ" | "อื่นๆ"
  final List<String> category;
  final List<String> images;
  final bool isSet;
  final int volumeCount;
  final String ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.publisher,
    this.description = '',
    required this.coverType,
    required this.language,
    this.category = const [],
    this.images = const [],
    this.isSet = false,
    this.volumeCount = 1,
    required this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  factory BookModel.fromJson(String id, Map<String, dynamic> json) {
    return BookModel(
      id: id,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      publisher: json['publisher'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverType: json['coverType'] as String? ?? 'ปกอ่อน',
      language: json['language'] as String? ?? 'ไทย',
      category: List<String>.from(json['category'] as List? ?? []),
      images: List<String>.from(json['images'] as List? ?? []),
      isSet: json['isSet'] as bool? ?? false,
      volumeCount: (json['volumeCount'] as num?)?.toInt() ?? 1,
      ownerId: json['ownerId'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'publisher': publisher,
      'description': description,
      'coverType': coverType,
      'language': language,
      'category': category,
      'images': images,
      'isSet': isSet,
      'volumeCount': volumeCount,
      'ownerId': ownerId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}