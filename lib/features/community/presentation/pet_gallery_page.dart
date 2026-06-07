import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kaki_empat/core/services/community_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/features/shared/widgets/v2_empty_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class PetGalleryPage extends StatefulWidget {
  const PetGalleryPage({super.key});

  @override
  State<PetGalleryPage> createState() => _PetGalleryPageState();
}

class _PetGalleryPageState extends State<PetGalleryPage> {
  List<PetGalleryItem> _items = [];
  bool _loading = true;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await CommunityV2Service.instance.listGallery();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on V2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.loadFailed;
        _loading = false;
      });
    }
  }

  Future<void> _upload() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    final mime = result.files.first.extension == 'png' ? 'image/png' : 'image/jpeg';
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

    setState(() => _uploading = true);
    try {
      await CommunityV2Service.instance.uploadGallery(imageData: dataUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.petGalleryUploadSuccess)),
      );
      await _load();
    } on V2ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _like(PetGalleryItem item) async {
    try {
      final count = await CommunityV2Service.instance.likeGallery(item.id);
      if (!mounted) return;
      setState(() {
        _items = _items.map((i) {
          if (i.id != item.id) return i;
          return PetGalleryItem(
            id: i.id,
            ownerUserId: i.ownerUserId,
            ownerName: i.ownerName,
            petId: i.petId,
            caption: i.caption,
            imageData: i.imageData,
            likesCount: count,
            likedByMe: true,
            createdAt: i.createdAt,
          );
        }).toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.petGalleryTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _upload,
        icon: _uploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_photo_alternate_outlined),
        label: Text(l10n.petGalleryUpload),
      ),
      body: V2Responsive.constrain(
        _loading
            ? const V2ListSkeleton()
            : _error != null && _items.isEmpty
                ? V2ErrorState(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _items.isEmpty
                        ? ListView(
                            children: [
                              V2EmptyState(
                                message: l10n.petGalleryEmpty,
                                icon: Icons.photo_library_outlined,
                              ),
                            ],
                          )
                        : GridView.builder(
                            padding: V2Responsive.pagePadding(context),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return _GalleryCard(
                                item: item,
                                onLike: () => _like(item),
                              );
                            },
                          ),
                  ),
        context,
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({required this.item, required this.onLike});

  final PetGalleryItem item;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ImageProvider? image;
    if (item.imageData.startsWith('data:')) {
      try {
        final b64 = item.imageData.split(',').last;
        image = MemoryImage(base64Decode(b64));
      } catch (_) {}
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: image != null
                ? Image(image: image, fit: BoxFit.cover)
                : Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.pets, size: 48),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.ownerName, style: Theme.of(context).textTheme.labelLarge),
                if (item.caption.isNotEmpty)
                  Text(item.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        item.likedByMe ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                      ),
                      onPressed: item.likedByMe ? null : onLike,
                    ),
                    Text(l10n.storiLikes(item.likesCount)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
