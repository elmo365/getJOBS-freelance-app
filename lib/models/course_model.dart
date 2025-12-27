/// Course Model for Trainers & Mentors module
class CourseModel {
  final String courseId;
  final String trainerId;
  final String trainerName;
  final String? trainerImage;
  final String title;
  final String description;
  final String? category;
  final String? thumbnailUrl;
  final double price;
  final double? rating;
  final int totalStudents;
  final int totalLessons;
  final List<Lesson> lessons;
  final DateTime? createdAt;
  final bool isPublished;
  final List<String>? tags;
  final String? level; // Beginner, Intermediate, Advanced

  CourseModel({
    required this.courseId,
    required this.trainerId,
    required this.trainerName,
    this.trainerImage,
    required this.title,
    required this.description,
    this.category,
    this.thumbnailUrl,
    this.price = 0.0,
    this.rating,
    this.totalStudents = 0,
    this.totalLessons = 0,
    this.lessons = const [],
    this.createdAt,
    this.isPublished = false,
    this.tags,
    this.level,
  });

  factory CourseModel.fromMap(Map<String, dynamic> map, String courseId) {
    return CourseModel(
      courseId: courseId,
      trainerId: map['trainer_id'] ?? '',
      trainerName: map['trainer_name'] ?? '',
      trainerImage: map['trainer_image'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'],
      thumbnailUrl: map['thumbnail_url'],
      price: (map['price'] ?? 0).toDouble(),
      rating: map['rating']?.toDouble(),
      totalStudents: map['total_students'] ?? 0,
      totalLessons: map['total_lessons'] ?? 0,
      lessons: (map['lessons'] as List<dynamic>?)
              ?.map((e) => Lesson.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: map['created_at']?.toDate(),
      isPublished: map['is_published'] ?? false,
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      level: map['level'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trainer_id': trainerId,
      'trainer_name': trainerName,
      'trainer_image': trainerImage,
      'title': title,
      'description': description,
      'category': category,
      'thumbnail_url': thumbnailUrl,
      'price': price,
      'rating': rating,
      'total_students': totalStudents,
      'total_lessons': totalLessons,
      'lessons': lessons.map((e) => e.toMap()).toList(),
      'created_at': createdAt,
      'is_published': isPublished,
      'tags': tags,
      'level': level,
    };
  }
}

class Lesson {
  final String lessonId;
  final String title;
  final String? description;
  final String? videoUrl;
  final String? content;
  final int duration; // in minutes
  final int order;
  final bool isFree;

  Lesson({
    required this.lessonId,
    required this.title,
    this.description,
    this.videoUrl,
    this.content,
    this.duration = 0,
    this.order = 0,
    this.isFree = false,
  });

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      lessonId: map['lesson_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      videoUrl: map['video_url'],
      content: map['content'],
      duration: map['duration'] ?? 0,
      order: map['order'] ?? 0,
      isFree: map['is_free'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lesson_id': lessonId,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'content': content,
      'duration': duration,
      'order': order,
      'is_free': isFree,
    };
  }
}

