import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._();
  factory FavoritesService() => _instance;
  FavoritesService._();

  Set<int> _ids = {};

  bool isFavorite(int id) => _ids.contains(id);
  int get count => _ids.length;
  Set<int> get ids => Set.unmodifiable(_ids);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('fav_material_ids') ?? [];
    _ids = raw
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toSet();
    notifyListeners();
  }

  Future<void> toggle(int id) async {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'fav_material_ids',
      _ids.map((e) => e.toString()).toList(),
    );
    notifyListeners();
  }
}
