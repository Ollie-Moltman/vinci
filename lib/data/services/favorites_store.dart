import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists user favorites locally using SharedPreferences JSON.
class FavoritesStore {
  static const _key = 'favorites_v1';

  /// Load saved favorite photo IDs.
  Future<Set<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return {};
    final list = jsonDecode(data) as List;
    return list.cast<String>().toSet();
  }

  /// Save favorite photo IDs.
  Future<void> saveFavorites(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(ids.toList()));
  }

  /// Add a photo ID to favorites.
  Future<Set<String>> addFavorite(String id) async {
    final favorites = await loadFavorites();
    favorites.add(id);
    await saveFavorites(favorites);
    return favorites;
  }

  /// Remove a photo ID from favorites.
  Future<Set<String>> removeFavorite(String id) async {
    final favorites = await loadFavorites();
    favorites.remove(id);
    await saveFavorites(favorites);
    return favorites;
  }

  /// Toggle a favorite.
  Future<Set<String>> toggleFavorite(String id) async {
    final favorites = await loadFavorites();
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    await saveFavorites(favorites);
    return favorites;
  }
}
