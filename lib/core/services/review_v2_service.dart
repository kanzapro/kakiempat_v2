import 'package:kaki_empat/core/services/v2_api_client.dart';

class ReviewV2 {
  const ReviewV2({
    required this.id,
    required this.bookingId,
    required this.rating,
    this.ownerUserId,
    this.sitterUserId,
    this.ownerName,
    this.comment = '',
    this.createdAt = '',
  });

  final String id;
  final String bookingId;
  final int rating;
  final String? ownerUserId;
  final String? sitterUserId;
  final String? ownerName;
  final String comment;
  final String createdAt;

  factory ReviewV2.fromJson(Map<String, dynamic> json) {
    return ReviewV2(
      id: '${json['id'] ?? ''}',
      bookingId: '${json['booking_id'] ?? ''}',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      ownerUserId: json['owner_user_id']?.toString(),
      sitterUserId: json['sitter_user_id']?.toString(),
      ownerName: json['owner_name'] as String?,
      comment: '${json['comment'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
    );
  }
}

class SitterReviewsResult {
  const SitterReviewsResult({
    required this.sitterId,
    required this.reviews,
    required this.total,
    this.averageRating,
  });

  final String sitterId;
  final List<ReviewV2> reviews;
  final int total;
  final double? averageRating;

  factory SitterReviewsResult.fromJson(Map<String, dynamic> json) {
    final raw = json['reviews'];
    return SitterReviewsResult(
      sitterId: '${json['sitter_id'] ?? ''}',
      reviews: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(ReviewV2.fromJson)
              .toList()
          : const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
    );
  }
}

class ReviewV2Service {
  ReviewV2Service({V2ApiClient? client}) : _api = client ?? V2ApiClient.instance;

  static final ReviewV2Service instance = ReviewV2Service();

  final V2ApiClient _api;
  static const _script = 'review_v2.php';

  Future<ReviewV2> submitReview({
    required String bookingId,
    required int rating,
    String comment = '',
  }) async {
    final response = await _api.postAuth(
      _script,
      action: 'submit_review',
      body: {
        'booking_id': bookingId,
        'rating': rating,
        if (comment.isNotEmpty) 'comment': comment,
      },
    );
    return _api.parse(
      response,
      (body) => ReviewV2.fromJson(body['review'] as Map<String, dynamic>),
    );
  }

  Future<SitterReviewsResult> getSitterReviews(
    String sitterId, {
    int limit = 50,
  }) async {
    final response = await _api.getAuth(
      _script,
      action: 'get_sitter_reviews',
      query: {'sitter_id': sitterId, 'limit': '$limit'},
    );
    return _api.parse(response, SitterReviewsResult.fromJson);
  }

  Future<ReviewV2?> getBookingReview(String bookingId) async {
    final response = await _api.getAuth(
      _script,
      action: 'list_booking_review',
      query: {'booking_id': bookingId},
    );
    return _api.parse(
      response,
      (body) {
        final raw = body['review'];
        if (raw is! Map<String, dynamic>) return null;
        return ReviewV2.fromJson(raw);
      },
    );
  }
}
