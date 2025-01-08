import 'package:flutter/material.dart';
import '../api_service.dart';
import 'add_edit_review_screen.dart';

class MovieReviewsScreen extends StatefulWidget {
  final String username;
  final String role; // "admin" atau "user"

  const MovieReviewsScreen({Key? key, required this.username, required this.role}) : super(key: key);

  @override
  _MovieReviewsScreenState createState() => _MovieReviewsScreenState();
}

class _MovieReviewsScreenState extends State<MovieReviewsScreen> {
  final _apiService = ApiService();
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final reviews = await _apiService.getReviews();
    setState(() {
      _reviews = reviews;
    });
  }

  void _deleteReview(String id) async {
    final success = await _apiService.deleteReview(id);
    if (success) {
      _loadReviews();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus review')),
      );
    }
  }

  Widget _buildStarRating(int rating) {
    // Pastikan rating di antara 1-5
    if (rating < 1) rating = 1;
    if (rating > 5) rating = 5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.yellow[700],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil list judul unik
    final titles = _reviews.map((r) => r['title']).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Movie Reviews'),
        actions: [
          // Admin dapat menambahkan review baru untuk film apa saja
          if (widget.role == 'admin')
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditReviewScreen(
                      username: widget.username,
                      role: widget.role,
                    ),
                  ),
                );
                if (result == true) _loadReviews();
              },
            ),
        ],
      ),
      body: titles.isEmpty
          ? Center(child: Text('Belum ada review.'))
          : ListView.builder(
              itemCount: titles.length,
              itemBuilder: (context, index) {
                final title = titles[index];
                final movieReviews = _reviews.where((rev) => rev['title'] == title).toList();

                // Hitung rata-rata rating
                final avgRating = movieReviews.map((r) => r['rating']).fold(0, (a, b) => b + a) / movieReviews.length;
                int roundedAvg = avgRating.round();
                if (roundedAvg < 1) {
                  roundedAvg = 1;
                } else if (roundedAvg > 5) {
                  roundedAvg = 5;
                }

                return Card(
                  child: ListTile(
                    title: Text(title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rata-rata rating:'),
                        _buildStarRating(roundedAvg),
                        Text('${movieReviews.length} Review(s)'),
                      ],
                    ),
                    trailing: widget.role == 'admin'
                        ? IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () async {
                              if (movieReviews.isNotEmpty) {
                                // Admin dapat mengedit review pertama sebagai contoh (bisa dikembangkan)
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEditReviewScreen(
                                      username: widget.username,
                                      role: widget.role,
                                      review: movieReviews.first,
                                    ),
                                  ),
                                );
                                if (result == true) _loadReviews();
                              }
                            },
                          )
                        : (widget.role == 'user'
                            ? IconButton(
                                icon: Icon(Icons.add_comment),
                                onPressed: () async {
                                  // User menambahkan review jika belum pernah review film ini
                                  final alreadyReviewed = await _apiService.userHasReviewed(widget.username, title);
                                  if (alreadyReviewed) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Anda sudah mereview film ini.')),
                                    );
                                  } else {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddEditReviewScreen(
                                          username: widget.username,
                                          role: widget.role,
                                          predefinedTitle: title,
                                          isUserAdd: true,
                                        ),
                                      ),
                                    );
                                    if (result == true) _loadReviews();
                                  }
                                },
                              )
                            : null),
                    onTap: () {
                      // Halaman detail film
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MovieDetailScreen(
                            title: title,
                            reviews: movieReviews,
                            isAdmin: widget.role == 'admin',
                            onDelete: (id) {
                              _deleteReview(id);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class MovieDetailScreen extends StatelessWidget {
  final String title;
  final List<dynamic> reviews;
  final bool isAdmin;
  final Function(String) onDelete;

  MovieDetailScreen({required this.title, required this.reviews, required this.isAdmin, required this.onDelete});

  Widget _buildStarRating(int rating) {
    if (rating < 1) rating = 1;
    if (rating > 5) rating = 5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.yellow[700],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: reviews.isEmpty
          ? Center(child: Text('Tidak ada review untuk film ini.'))
          : ListView.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return ListTile(
                  title: Text('${review['username']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStarRating(review['rating']),
                      Text(review['comment']),
                    ],
                  ),
                  trailing: isAdmin
                      ? IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            onDelete(review['_id']);
                            Navigator.pop(context);
                          },
                        )
                      : null,
                );
              },
            ),
    );
  }
}
