import 'package:flutter/material.dart';
import '../api_service.dart';

class AddEditReviewScreen extends StatefulWidget {
  final String username;
  final String role;
  final Map<String, dynamic>? review;
  final String? predefinedTitle;  // Jika user menambahkan review pada film yang sudah ada
  final bool isUserAdd; // True jika user menambahkan review baru

  const AddEditReviewScreen({
    Key? key,
    required this.username,
    required this.role,
    this.review,
    this.predefinedTitle,
    this.isUserAdd = false,
  }) : super(key: key);

  @override
  _AddEditReviewScreenState createState() => _AddEditReviewScreenState();
}

class _AddEditReviewScreenState extends State<AddEditReviewScreen> {
  final _titleController = TextEditingController();
  final _ratingController = TextEditingController();
  final _commentController = TextEditingController();
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    if (widget.review != null) {
      _titleController.text = widget.review!['title'];
      _ratingController.text = widget.review!['rating'].toString();
      _commentController.text = widget.review!['comment'];
    } else if (widget.predefinedTitle != null) {
      _titleController.text = widget.predefinedTitle!;
    }
  }

  void _saveReview() async {
    final title = _titleController.text.trim();
    final rating = int.tryParse(_ratingController.text) ?? 0;
    final comment = _commentController.text.trim();

    if (title.isEmpty || rating < 1 || rating > 5 || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data tidak valid. Rating harus 1-5, judul dan komentar tidak boleh kosong.')),
      );
      return;
    }

    bool success;
    if (widget.review == null) {
      // Tambah review baru
      success = await _apiService.addReview(widget.username, title, rating, comment);
    } else {
      // Edit review
      success = await _apiService.updateReview(widget.review!['_id'], title, rating, comment);
    }

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan review')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jika user menambahkan review untuk film yang sudah ada atau mengedit review,
    // judul tidak boleh diubah oleh user.
    final readOnlyTitle = (widget.isUserAdd && widget.predefinedTitle != null) || widget.review != null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.review == null ? 'Tambah Review' : 'Edit Review')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Judul Film'),
              readOnly: readOnlyTitle,
            ),
            TextField(
              controller: _ratingController,
              decoration: InputDecoration(labelText: 'Rating (1-5)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(labelText: 'Komentar'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveReview,
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
