/// News Model for News Corner
class NewsModel {
  final String newsId;
  final String title;
  final String content;
  final String? author;
  final String? imageUrl;
  final String category;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final int views;
  final int likes;
  final List<String>? tags;
  final String? sourceUrl;
  final bool isFeatured;

  NewsModel({
    required this.newsId,
    required this.title,
    required this.content,
    this.author,
    this.imageUrl,
    required this.category,
    this.publishedAt,
    this.createdAt,
    this.views = 0,
    this.likes = 0,
    this.tags,
    this.sourceUrl,
    this.isFeatured = false,
  });

  factory NewsModel.fromMap(Map<String, dynamic> map, String newsId) {
    return NewsModel(
      newsId: newsId,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      author: map['author'],
      imageUrl: map['image_url'],
      category: map['category'] ?? '',
      publishedAt: map['published_at']?.toDate(),
      createdAt: map['created_at']?.toDate(),
      views: map['views'] ?? 0,
      likes: map['likes'] ?? 0,
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      sourceUrl: map['source_url'],
      isFeatured: map['is_featured'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'author': author,
      'image_url': imageUrl,
      'category': category,
      'published_at': publishedAt,
      'created_at': createdAt,
      'views': views,
      'likes': likes,
      'tags': tags,
      'source_url': sourceUrl,
      'is_featured': isFeatured,
    };
  }
}

