import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/enrolled_sound.dart';

class StorageService {
  static const String _enrolledSoundsKey = 'enrolled_sounds_v1';

  Future<List<EnrolledSound>> loadEnrolledSounds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_enrolledSoundsKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <EnrolledSound>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <EnrolledSound>[];
    }

    return decoded
        .whereType<Map>()
        .map((e) => EnrolledSound.fromJson(e.cast<String, Object?>()))
        .where((e) => e.name.isNotEmpty && e.embedding.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> saveEnrolledSounds(List<EnrolledSound> sounds) async {
    final prefs = await SharedPreferences.getInstance();
    final list = sounds.map((s) => s.toJson()).toList(growable: false);
    await prefs.setString(_enrolledSoundsKey, jsonEncode(list));
  }

  Future<void> addOrReplace(EnrolledSound sound) async {
    final existing = (await loadEnrolledSounds()).toList(growable: true);
    final idx = existing.indexWhere(
      (e) => e.name.toLowerCase() == sound.name.toLowerCase(),
    );
    if (idx >= 0) {
      existing[idx] = sound;
    } else {
      existing.add(sound);
    }
    await saveEnrolledSounds(existing);
  }

  Future<void> deleteByName(String name) async {
    final existing = (await loadEnrolledSounds()).toList(growable: true);
    existing.removeWhere((e) => e.name.toLowerCase() == name.toLowerCase());
    await saveEnrolledSounds(existing);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_enrolledSoundsKey);
  }
}
