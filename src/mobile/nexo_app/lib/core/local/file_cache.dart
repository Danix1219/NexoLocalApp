import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Archivos en la carpeta de caché privada de la app (Android puede vaciarla y
/// no se respalda). Si no está disponible, todo se comporta como sin caché.
class FileCache {
  FileCache(this.folder, {this.maxBytes = 120 * 1024 * 1024, Future<Directory?> Function()? root})
    : _root = root ?? _appCache;

  final String folder;
  final int maxBytes;
  final Future<Directory?> Function() _root;
  Future<Directory?>? _dir;
  int _writes = 0;

  static const _base = 'nexo_files';

  static Future<Directory?> _appCache() async {
    try {
      return await getApplicationCacheDirectory();
    } catch (_) {
      return null;
    }
  }

  Future<Directory?> _directory() => _dir ??= () async {
    final root = await _root();
    if (root == null) return null;
    return Directory('${root.path}/$_base/$folder').create(recursive: true);
  }();

  /// Nombre estable y corto para una clave cualquiera (FNV-1a de 64 bits).
  static String nameOf(String key) {
    var hash = 0xcbf29ce484222325;
    for (final unit in key.codeUnits) {
      hash = (hash ^ unit) * 0x100000001b3;
    }
    return '${hash.toUnsigned(64).toRadixString(16)}_${key.length}';
  }

  Future<File?> _file(String key) async {
    final dir = await _directory();
    return dir == null ? null : File('${dir.path}/${nameOf(key)}');
  }

  Future<Uint8List?> read(String key) async {
    try {
      final file = await _file(key);
      if (file == null || !await file.exists()) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, List<int> bytes) async {
    try {
      final file = await _file(key);
      if (file == null) return;
      // Se escribe aparte y se renombra: nunca queda un archivo a medias.
      final temp = File('${file.path}.tmp');
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(file.path);
      if (++_writes % 25 == 1) await _prune(file.parent);
    } catch (_) {
      _dir = null; // La carpeta pudo borrarse (cierre de sesión o el sistema).
    }
  }

  Future<void> remove(String key) async {
    try {
      final file = await _file(key);
      if (file != null && await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> _prune(Directory dir) async {
    final files = <(File, FileStat)>[];
    await for (final entry in dir.list()) {
      if (entry is File) files.add((entry, await entry.stat()));
    }
    var total = files.fold<int>(0, (sum, f) => sum + f.$2.size);
    files.sort((a, b) => a.$2.modified.compareTo(b.$2.modified));
    for (final (file, stat) in files) {
      if (total <= maxBytes) break;
      await file.delete();
      total -= stat.size;
    }
  }

  /// Cierre de sesión: no queda ningún archivo guardado.
  static Future<void> clearAll() async {
    try {
      final root = await _appCache();
      if (root == null) return;
      final dir = Directory('${root.path}/$_base');
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }
}
