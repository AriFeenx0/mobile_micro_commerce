import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/book_model.dart';
import '../../../models/book_volume_model.dart';
import '../../../services/book_service.dart';
import '../../../widgets/auth_form_components.dart';

class BookManageFormScreen extends StatefulWidget {
  const BookManageFormScreen({super.key, this.book});

  final BookModel? book;

  @override
  State<BookManageFormScreen> createState() => _BookManageFormScreenState();
}

class _BookManageFormScreenState extends State<BookManageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookService = BookService();
  final _imagePicker = ImagePicker();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _publisherController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _images = <XFile>[];
  final _existingImageUrls = <String>[];
  final _volumeRows = <_VolumeFields>[];

  String _coverType = 'ปกอ่อน';
  String _language = 'ไทย';
  String _condition = 'มือสอง สภาพดี';
  bool _isSet = true;
  bool _isSaving = false;
  bool _isLoadingVolumes = false;
  String? _volumeLoadError;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    if (book == null) {
      _volumeRows.addAll([
        _VolumeFields(number: 1, price: '250', stock: '1'),
        _VolumeFields(number: 2, price: '250', stock: '0'),
      ]);
      return;
    }

    _titleController.text = book.title;
    _authorController.text = book.author;
    _publisherController.text = book.publisher;
    _descriptionController.text = book.description;
    _categoryController.text = book.category.join(', ');
    _coverType = book.coverType;
    _language = book.language;
    _isSet = book.isSet;
    _existingImageUrls.addAll(book.images);
    _isLoadingVolumes = true;
    _loadVolumes(book.id);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _publisherController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    for (final row in _volumeRows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.book == null ? 'เพิ่มหนังสือใหม่' : 'แก้ไขหนังสือ',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          if (widget.book != null)
            IconButton(
              tooltip: 'ลบหนังสือ',
              onPressed: _isSaving ? null : _confirmDeleteBook,
              icon: const Icon(Icons.delete_outline),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: _isLoadingVolumes
                    ? const Center(child: CircularProgressIndicator())
                    : _volumeLoadError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _volumeLoadError!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final horizontalPadding = constraints.maxWidth < 420
                              ? AuthFormStyle.compactHorizontalPadding
                              : AuthFormStyle.wideHorizontalPadding;
                          return SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              8,
                              horizontalPadding,
                              24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildImages(),
                                const SizedBox(height: 14),
                                _buildTextField(
                                  label: 'ชื่อเรื่อง',
                                  hint: 'เช่น นิทานเมืองริมทาง',
                                  controller: _titleController,
                                  validator: _required('กรุณากรอกชื่อเรื่อง'),
                                ),
                                _buildTextField(
                                  label: 'ผู้เขียน',
                                  hint: 'ชื่อผู้เขียน',
                                  controller: _authorController,
                                  validator: _required('กรุณากรอกชื่อผู้เขียน'),
                                ),
                                _buildTextField(
                                  label: 'สำนักพิมพ์',
                                  hint: 'ชื่อสำนักพิมพ์',
                                  controller: _publisherController,
                                  validator: _required('กรุณากรอกสำนักพิมพ์'),
                                ),
                                _buildTextField(
                                  label: 'รายละเอียด',
                                  hint: 'รายละเอียดหนังสือ (ไม่บังคับ)',
                                  controller: _descriptionController,
                                  maxLines: 3,
                                ),
                                _buildTextField(
                                  label: 'หมวดหมู่',
                                  hint: 'คั่นแต่ละหมวดด้วยเครื่องหมายจุลภาค',
                                  controller: _categoryController,
                                ),
                                _buildChoices(
                                  label: 'รูปแบบปก',
                                  options: const ['ปกอ่อน', 'ปกแข็ง'],
                                  selected: _coverType,
                                  onSelected: (value) => setState(() {
                                    _coverType = value;
                                  }),
                                ),
                                _buildChoices(
                                  label: 'ภาษา',
                                  options: const ['ไทย', 'อังกฤษ', 'อื่นๆ'],
                                  selected: _language,
                                  onSelected: (value) => setState(() {
                                    _language = value;
                                  }),
                                ),
                                _buildChoices(
                                  label: 'สภาพ',
                                  options: const [
                                    'ใหม่',
                                    'มือสอง สภาพดี',
                                    'มือสอง พอใช้',
                                  ],
                                  selected: _condition,
                                  onSelected: (value) => setState(() {
                                    _condition = value;
                                  }),
                                ),
                                _buildChoices(
                                  label: 'จำนวนเล่ม',
                                  options: const ['เล่มเดี่ยว', 'ชุดหลายเล่ม'],
                                  selected: _isSet
                                      ? 'ชุดหลายเล่ม'
                                      : 'เล่มเดี่ยว',
                                  onSelected: _setBookType,
                                ),
                                const SizedBox(height: 12),
                                _buildVolumeTable(),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: _isSaving ? null : _addVolume,
                                    icon: const Icon(Icons.add, size: 20),
                                    label: const Text(
                                      'เพิ่มเล่ม',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF292929),
                                      padding: const EdgeInsets.only(left: 4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AuthFormStyle.compactHorizontalPadding,
                  8,
                  AuthFormStyle.compactHorizontalPadding,
                  AuthFormStyle.bottomPadding,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton(
                    onPressed:
                        _isSaving ||
                            _isLoadingVolumes ||
                            _volumeLoadError != null
                        ? null
                        : _saveBook,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF333333),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AuthFormStyle.buttonRadius,
                        ),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.book == null
                                ? 'บันทึกหนังสือ'
                                : 'บันทึกการแก้ไข',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImages() {
    final currentImageCount = _existingImageUrls.length + _images.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthFormStyle.label('รูปปกหนังสือ (สูงสุด 5 รูป)'),
        const SizedBox(height: 6),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: currentImageCount + (currentImageCount < 5 ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index < _existingImageUrls.length) {
                final imageUrl = _existingImageUrls[index];
                return _imageTile(
                  Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: Color(0xFFE1E1E1)),
                  ),
                  () => setState(() => _existingImageUrls.removeAt(index)),
                );
              }

              final selectedImageIndex = index - _existingImageUrls.length;
              if (selectedImageIndex < _images.length) {
                final image = _images[selectedImageIndex];
                return _imageTile(
                  FutureBuilder(
                    future: image.readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container(
                          width: 80,
                          color: const Color(0xFFF0F0F0),
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        );
                      }
                      return Image.memory(
                        snapshot.data!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  () => setState(() => _images.removeAt(selectedImageIndex)),
                );
              }

              if (index == currentImageCount) {
                return InkWell(
                  onTap: _isSaving ? null : _pickImages,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFCCCCCC),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Color(0xFF999999),
                      size: 28,
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _imageTile(Widget image, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 80, height: 80, child: image),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: IconButton(
            onPressed: _isSaving ? null : onRemove,
            icon: const Icon(Icons.close, size: 16),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF333333),
              minimumSize: const Size(24, 24),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthFormStyle.label(label),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            style: const TextStyle(
              fontSize: AuthFormStyle.inputFontSize,
              color: Color(0xFF333333),
            ),
            decoration: AuthFormStyle.inputDecoration(hint),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildChoices({
    required String label,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthFormStyle.label(label),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              for (final option in options)
                ChoiceChip(
                  label: Text(option),
                  selected: selected == option,
                  onSelected: (_) => onSelected(option),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: selected == option
                        ? Colors.white
                        : const Color(0xFF777777),
                    fontSize: 14,
                  ),
                  selectedColor: const Color(0xFF333333),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected == option
                        ? const Color(0xFF333333)
                        : const Color(0xFFCCCCCC),
                    width: 1.5,
                  ),
                  shape: const StadiumBorder(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeTable() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F4),
            border: Border.all(color: const Color(0xFFE5E5E5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 48,
                child: Text('เล่มที่', style: _tableHeaderStyle),
              ),
              Expanded(
                child: Center(child: Text('ราคา', style: _tableHeaderStyle)),
              ),
              Expanded(
                child: Center(child: Text('สต๊อก', style: _tableHeaderStyle)),
              ),
            ],
          ),
        ),
        for (var index = 0; index < _volumeRows.length; index++)
          _buildVolumeRow(_volumeRows[index], index),
      ],
    );
  }

  Widget _buildVolumeRow(_VolumeFields row, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text('${row.number}', style: const TextStyle(fontSize: 15)),
          ),
          Expanded(
            child: _numberField(
              controller: row.priceController,
              hint: 'ราคา',
              decimal: true,
              validator: (value) => _validNonNegativeNumber(value, 'ราคา'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _numberField(
              controller: row.stockController,
              hint: 'สต๊อก',
              validator: (value) => _validNonNegativeNumber(value, 'สต๊อก'),
            ),
          ),
          if (_isSet && _volumeRows.length > 2)
            IconButton(
              tooltip: 'ลบเล่ม',
              onPressed: _isSaving ? null : () => _removeVolume(index),
              icon: const Icon(Icons.remove_circle_outline),
              color: const Color(0xFF777777),
            ),
        ],
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    bool decimal = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'^\d*\.?\d{0,2}') : RegExp(r'^\d*'),
        ),
      ],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 15),
      decoration: AuthFormStyle.inputDecoration(hint).copyWith(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      ),
      validator: validator,
    );
  }

  void _setBookType(String value) {
    setState(() {
      _isSet = value == 'ชุดหลายเล่ม';
      if (!_isSet) {
        for (final row in _volumeRows.skip(1)) {
          row.dispose();
        }
        _volumeRows.removeRange(1, _volumeRows.length);
        _volumeRows.first.number = 1;
      } else if (_volumeRows.length == 1) {
        _volumeRows.add(_VolumeFields(number: 2));
      }
    });
  }

  void _addVolume() {
    if (!_isSet) {
      _showMessage('เลือกชุดหลายเล่มก่อนเพิ่มเล่ม');
      return;
    }
    setState(() {
      _volumeRows.add(_VolumeFields(number: _volumeRows.length + 1));
    });
  }

  void _removeVolume(int index) {
    if (index == 0 || _volumeRows.length <= 2) return;
    setState(() {
      _volumeRows.removeAt(index).dispose();
      for (var rowIndex = 0; rowIndex < _volumeRows.length; rowIndex++) {
        _volumeRows[rowIndex].number = rowIndex + 1;
      }
    });
  }

  Future<void> _pickImages() async {
    try {
      final pickedImages = await _imagePicker.pickMultiImage(
        maxWidth: 1600,
        imageQuality: 82,
        limit: 5 - _images.length,
        requestFullMetadata: false,
      );
      if (!mounted || pickedImages.isEmpty) return;
      setState(() => _images.addAll(pickedImages.take(5 - _images.length)));
    } on PlatformException {
      _showMessage('เปิดคลังรูปภาพไม่ได้ กรุณาตรวจสอบสิทธิ์การเข้าถึง');
    }
  }

  Future<void> _saveBook() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ownerId = FirebaseAuth.instance.currentUser?.uid;
    if (ownerId == null) {
      _showMessage('กรุณาเข้าสู่ระบบด้วยบัญชีเจ้าของร้าน');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final volumes = _volumeRows.map((row) {
        final stock = int.parse(row.stockController.text.trim());
        return BookVolumeModel(
          id: 'volume_${row.number}',
          bookId: '',
          volumeNumber: row.number,
          price: double.parse(row.priceController.text.trim()),
          stock: stock,
          condition: _condition,
          isSingleCopy: stock == 1,
        );
      }).toList();
      final categories = _categoryController.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
      final book = BookModel(
        id: widget.book?.id ?? '',
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        publisher: _publisherController.text.trim(),
        description: _descriptionController.text.trim(),
        coverType: _coverType,
        language: _language,
        category: categories,
        isSet: _isSet,
        volumeCount: volumes.length,
        ownerId: ownerId,
        createdAt: widget.book?.createdAt,
      );

      if (widget.book == null) {
        await _bookService.createBook(
          book: book,
          volumes: volumes,
          images: _images,
        );
      } else {
        await _bookService.updateBook(
          book: book,
          volumes: volumes,
          newImages: _images,
          retainedImageUrls: _existingImageUrls,
        );
      }
      if (!mounted) return;
      _showMessage(
        widget.book == null ? 'บันทึกหนังสือแล้ว' : 'แก้ไขหนังสือแล้ว',
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showMessage(_saveErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDeleteBook() async {
    final book = widget.book;
    if (book == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบหนังสือ?'),
        content: Text('ต้องการลบ “${book.title}” และข้อมูลเล่มทั้งหมดหรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF333333),
            ),
            child: const Text('ลบหนังสือ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await _bookService.deleteBook(book.id);
      if (!mounted) return;
      _showMessage('ลบหนังสือแล้ว');
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showMessage(_saveErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _loadVolumes(String bookId) async {
    try {
      final volumes = await _bookService.getBookVolumes(bookId);
      if (!mounted) return;
      setState(() {
        _volumeRows
          ..forEach((row) => row.dispose())
          ..clear()
          ..addAll(
            volumes.map(
              (volume) => _VolumeFields(
                number: volume.volumeNumber,
                price: volume.price.toStringAsFixed(
                  volume.price == volume.price.roundToDouble() ? 0 : 2,
                ),
                stock: volume.stock.toString(),
              ),
            ),
          );
        if (_volumeRows.isEmpty) {
          _volumeRows.add(_VolumeFields(number: 1));
        }
        _condition = volumes.isEmpty ? _condition : volumes.first.condition;
        _isSet = widget.book?.isSet ?? _volumeRows.length > 1;
        _isLoadingVolumes = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _volumeLoadError = 'โหลดข้อมูลเล่มไม่สำเร็จ: $error';
        _isLoadingVolumes = false;
      });
    }
  }

  String? Function(String?) _required(String message) => (value) {
    if (value?.trim().isEmpty ?? true) return message;
    return null;
  };

  String? _validNonNegativeNumber(String? value, String label) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || number < 0) return 'กรอก$labelให้ถูกต้อง';
    return null;
  }

  String _saveErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      debugPrint('Book save auth error (${error.code}): ${error.message}');
      return 'ตรวจสอบสิทธิ์บัญชีเจ้าของร้านแล้วลองใหม่';
    }
    if (error is FirebaseException) {
      debugPrint(
        'Book save Firebase error [${error.plugin}/${error.code}]: ${error.message}',
      );
      final code = error.code.replaceFirst('storage/', '');
      return switch (code) {
        'canceled' =>
          'การอัปโหลดถูกยกเลิกหรือการเชื่อมต่อสะดุด กรุณาลองอัปโหลดอีกครั้ง',
        'unauthorized' || 'unauthenticated' =>
          'ไม่มีสิทธิ์อัปโหลด ตรวจสอบ Firebase Storage Rules และสถานะ Login',
        'quota-exceeded' =>
          'เกินโควตา Storage หรือโปรเจกต์ต้องเปิดใช้แพ็กเกจ Blaze',
        'retry-limit-exceeded' =>
          'อัปโหลดใช้เวลานานเกินไป ตรวจสอบอินเทอร์เน็ตแล้วลองใหม่',
        'permission-denied' =>
          'ไม่มีสิทธิ์บันทึก ตรวจสอบ role owner และกฎ Firestore',
        _ =>
          'Firebase error (${error.plugin}/${error.code}): ${error.message ?? 'ไม่ทราบสาเหตุ'}',
      };
    }
    if (error is StateError) return error.message;
    return 'บันทึกไม่สำเร็จ กรุณาตรวจสอบข้อมูลและลองใหม่';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _VolumeFields {
  _VolumeFields({required this.number, String price = '', String stock = '0'})
    : priceController = TextEditingController(text: price),
      stockController = TextEditingController(text: stock);

  int number;
  final TextEditingController priceController;
  final TextEditingController stockController;

  void dispose() {
    priceController.dispose();
    stockController.dispose();
  }
}

const _tableHeaderStyle = TextStyle(color: Color(0xFF999999), fontSize: 12);
