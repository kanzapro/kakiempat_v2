import 'package:shared_preferences/shared_preferences.dart';
/// Owner bookmark sitter IDs (local until API endpoint exists).
class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  static const _key = 'v2_favorite_sitter_ids';

  Future<Set<String>> getFavoriteSitterIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key)?.toSet() ?? {};
  }

  Future<bool> isFavorite(String sitterId) async {
    final ids = await getFavoriteSitterIds();
    return ids.contains(sitterId);
  }

  Future<void> toggleFavorite(String sitterId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key)?.toSet() ?? {};
    if (ids.contains(sitterId)) {
      ids.remove(sitterId);
    } else {
      ids.add(sitterId);
    }
    await prefs.setStringList(_key, ids.toList());
  }
}
