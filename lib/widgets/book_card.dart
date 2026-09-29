import 'package:flutter/material.dart';

class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.title,
    required this.author,
    required this.price,
    this.onTap,
  });

  final String title;
  final String author;
  final String price;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(author),
        trailing: Text(price),
        onTap: onTap,
      ),
    );
  }
}