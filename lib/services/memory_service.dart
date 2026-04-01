import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MemoryService {
  static const _key = 'user_memory_v1';
  final _storage = const FlutterSecureStorage();

  Future<void> saveMemory(String memory) async {
    await _storage.write(key: _key, value: memory);
  }

  Future<String?> getMemory() async {
    return _storage.read(key: _key);
  }

  Future<void> clearMemory() async {
    await _storage.delete(key: _key);
  }
}

final memoryServiceProvider = Provider<MemoryService>((ref) => MemoryService());
