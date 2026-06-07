import 'package:kaki_empat/core/services/v2_api_client.dart';

class PetGalleryItem {
  const PetGalleryItem({
    required this.id,
    required this.ownerUserId,
    required this.ownerName,
    required this.imageData,
    required this.likesCount,
    required this.likedByMe,
    this.petId,
    this.caption = '',
    this.createdAt = '',
  });

  final String id;
  final String ownerUserId;
  final String ownerName;
  final String? petId;
  final String caption;
  final String imageData;
  final int likesCount;
  final bool likedByMe;
  final String createdAt;

  factory PetGalleryItem.fromJson(Map<String, dynamic> json) {
    return PetGalleryItem(
      id: '${json['id'] ?? ''}',
      ownerUserId: '${json['owner_user_id'] ?? ''}',
      ownerName: '${json['owner_name'] ?? ''}',
      petId: json['pet_id']?.toString(),
      caption: '${json['caption'] ?? ''}',
      imageData: '${json['image_data'] ?? ''}',
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      likedByMe: json['liked_by_me'] == true,
      createdAt: '${json['created_at'] ?? ''}',
    );
  }
}

class CommunityV2Service {
  CommunityV2Service({V2ApiClient? client})
      : _api = client ?? V2ApiClient.instance;

  static final CommunityV2Service instance = CommunityV2Service();

  final V2ApiClient _api;
  static const _script = 'community_v2.php';

  Future<List<PetGalleryItem>> listGallery({int limit = 50}) async {
    final response = await _api.getAuth(
      _script,
      action: 'list_gallery',
      query: {'limit': '$limit'},
    );
    return _api.parse(
      response,
      (body) {
        final raw = body['items'];
        if (raw is! List) return <PetGalleryItem>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(PetGalleryItem.fromJson)
            .toList();
      },
    );
  }

  Future<void> uploadGallery({
    required String imageData,
    String caption = '',
    String? petId,
  }) async {
    final response = await _api.postAuth(
      _script,
      action: 'upload_gallery',
      body: {
        'image_data': imageData,
        if (caption.isNotEmpty) 'caption': caption,
        if (petId != null && petId.isNotEmpty) 'pet_id': petId,
      },
    );
    await _api.parse<void>(response, (_) {});
  }

  Future<int> likeGallery(String galleryId) async {
    final response = await _api.postAuth(
      _script,
      action: 'like_gallery',
      body: {'gallery_id': galleryId},
    );
    return _api.parse(
      response,
      (body) => (body['likes_count'] as num?)?.toInt() ?? 0,
    );
  }
}
