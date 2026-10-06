// แสดงรายละเอียดหนังสือ เลือกเล่ม และเพิ่มสินค้าลงตะกร้า
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_routes.dart';
import '../../../models/book_model.dart';
import '../../../models/book_volume_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../services/book_service.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.book});

  final BookModel book;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _bookService = BookService();
  late Stream<List<BookVolumeModel>> _volumesStream;
  String? _selectedVolumeId;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _volumesStream = _bookService.watchBookVolumes(widget.book.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('รายละเอียดหนังสือ'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<List<BookVolumeModel>>(
        stream: _volumesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('โหลดข้อมูลเล่มและสต็อกไม่ได้'),
                  TextButton(
                    onPressed: () => setState(() {
                      _volumesStream = _bookService.watchBookVolumes(
                        widget.book.id,
                      );
                    }),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }

          final volumes = snapshot.data ?? const <BookVolumeModel>[];
          final selectedVolume = _findSelectedVolume(volumes);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 300,
                      child: widget.book.images.isEmpty
                          ? const _ImageFallback()
                          : PageView.builder(
                              itemCount: widget.book.images.length,
                              itemBuilder: (context, index) => Image.network(
                                widget.book.images[index],
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const _ImageFallback(),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                sliver: SliverList.list(
                  children: [
                    Text(
                      widget.book.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.book.author,
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedVolume == null
                          ? 'ยังไม่มีเล่มจำหน่าย'
                          : _formatPrice(selectedVolume.price),
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'เลือกเล่มที่ต้องการ',
                      style: TextStyle(color: Color(0xFF777777)),
                    ),
                    const SizedBox(height: 12),
                    if (volumes.isEmpty)
                      const Text('ยังไม่มีข้อมูลเล่ม')
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final volume in volumes)
                            _VolumeOption(
                              volume: volume,
                              selected:
                                  selectedVolume?.id == volume.id &&
                                  volume.isAvailable,
                              onTap: volume.isAvailable
                                  ? () => setState(() {
                                      _selectedVolumeId = volume.id;
                                      _quantity = 1;
                                    })
                                  : null,
                            ),
                        ],
                      ),
                    if (selectedVolume != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'สินค้าคงเหลือ ${selectedVolume.isAvailable ? selectedVolume.stock : 0} ชิ้น'
                        '  ·  ${selectedVolume.condition}',
                        style: const TextStyle(color: Color(0xFF777777)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'จำนวน',
                            style: TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 18,
                            ),
                          ),
                        ),
                        _QuantityButton(
                          icon: Icons.remove,
                          onPressed: selectedVolume != null && _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        SizedBox(
                          width: 56,
                          child: Text(
                            '$_quantity',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        _QuantityButton(
                          icon: Icons.add,
                          onPressed:
                              selectedVolume != null &&
                                  selectedVolume.isAvailable &&
                                  _quantity < selectedVolume.stock
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      expandedAlignment: Alignment.centerLeft,
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      title: const Text('รายละเอียดสินค้า'),
                      children: [
                        _BookField(
                          label: 'สำนักพิมพ์',
                          value: widget.book.publisher,
                        ),
                        _BookField(
                          label: 'รายละเอียด',
                          value: widget.book.description.isEmpty
                              ? '-'
                              : widget.book.description,
                        ),
                        _BookField(
                          label: 'ประเภทปก',
                          value: widget.book.coverType,
                        ),
                        _BookField(label: 'ภาษา', value: widget.book.language),
                        _BookField(
                          label: 'หมวดหมู่',
                          value: widget.book.category.isEmpty
                              ? '-'
                              : widget.book.category.join(', '),
                        ),
                        _BookField(
                          label: 'รูปแบบหนังสือ',
                          value: widget.book.isSet ? 'เป็นชุด' : 'เล่มเดี่ยว',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: StreamBuilder<List<BookVolumeModel>>(
        stream: _volumesStream,
        builder: (context, snapshot) {
          final volumes = snapshot.data ?? const <BookVolumeModel>[];
          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _hasAvailableSelection(volumes) && !snapshot.hasError
                    ? _addToCart
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('ใส่ตะกร้า', style: TextStyle(fontSize: 18)),
              ),
            ),
          );
        },
      ),
    );
  }

  BookVolumeModel? _findSelectedVolume(List<BookVolumeModel> volumes) {
    for (final volume in volumes) {
      if (volume.id == _selectedVolumeId && volume.isAvailable) return volume;
    }
    for (final volume in volumes) {
      if (volume.isAvailable) return volume;
    }
    return volumes.isEmpty ? null : volumes.first;
  }

  bool _hasAvailableSelection(List<BookVolumeModel> volumes) {
    final selected = volumes.where((volume) => volume.id == _selectedVolumeId);
    if (selected.isNotEmpty) return selected.first.isAvailable;
    return volumes.any((volume) => volume.isAvailable);
  }

  String _formatPrice(double price) {
    final amount = price % 1 == 0
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '฿$amount / ชิ้น';
  }

  Future<void> _addToCart() async {
    final volumes = await _bookService.getBookVolumes(widget.book.id);
    if (!mounted) return;
    BookVolumeModel? volume;
    for (final candidate in volumes) {
      if (candidate.id == _selectedVolumeId && candidate.isAvailable) {
        volume = candidate;
        break;
      }
    }
    volume ??= volumes.where((candidate) => candidate.isAvailable).firstOrNull;
    if (volume == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('หนังสือเล่มนี้ไม่มีในสต็อก')),
      );
      return;
    }
    final cart = context.read<CartProvider>();
    if (!volume.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('หนังสือเล่มนี้หมดสต็อกแล้ว')),
      );
      return;
    }

    final added = cart.addItem(
      book: widget.book,
      volume: volume,
      quantity: _quantity,
    );
    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('จำนวนสินค้าเกินสต็อกที่มี')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: const Text('เพิ่มสินค้าในตะกร้าแล้ว'),
        action: SnackBarAction(
          label: 'ดูตะกร้า',
          onPressed: () {
            messenger.hideCurrentSnackBar();
            Navigator.pushNamed(context, AppRoutes.customerCart);
          },
        ),
      ),
    );
  }
}

class _VolumeOption extends StatelessWidget {
  const _VolumeOption({
    required this.volume,
    required this.selected,
    required this.onTap,
  });

  final BookVolumeModel volume;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final available = volume.isAvailable;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: available ? Colors.white : const Color(0xFFD9D9D9),
          border: available
              ? Border.all(
                  color: selected ? Colors.black : const Color(0xFF222222),
                  width: selected ? 2 : 1,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${volume.volumeNumber}',
              style: TextStyle(
                color: available ? Colors.black : const Color(0xFF777777),
                fontSize: 17,
              ),
            ),
            if (!available)
              const Icon(Icons.remove, size: 14, color: Color(0xFF777777)),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: const Color(0xFF333333),
          side: const BorderSide(color: Color(0xFF999999), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _BookField extends StatelessWidget {
  const _BookField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
          ),
          const SizedBox(height: 4),
          SelectableText(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE7E7E7),
      child: Center(child: Icon(Icons.menu_book_outlined, size: 56)),
    );
  }
}
