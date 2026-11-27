import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../local/file_cache.dart';

/// Deja lista una foto antes de mostrarla. Los fallos se ignoran: la pantalla
/// vuelve a intentarlo al pintarla.
Future<void> precacheNexoPhoto(BuildContext context, String? url, {bool thumb = false}) async {
  if (url == null || !url.startsWith('http')) return;
  final target = thumb && url.contains('/v1/discovery/media/') && !url.endsWith('/thumb') ? '$url/thumb' : url;
  await precacheImage(NexoPhotoProvider(target), context, onError: (_, __) {});
}

/// Foto remota que se guarda en el teléfono: la segunda vez se pinta desde el
/// archivo, también sin conexión. Las fotos publicadas tienen una dirección
/// distinta en cada subida, así que no hay nada que revalidar.
@immutable
class NexoPhotoProvider extends ImageProvider<NexoPhotoProvider> {
  const NexoPhotoProvider(this.url);
  final String url;

  static final cache = FileCache('photos');
  static const _maxBytes = 8 * 1024 * 1024;

  @override
  Future<NexoPhotoProvider> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(NexoPhotoProvider key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1, debugLabel: 'foto');

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    try {
      final stored = await cache.read(url);
      if (stored != null && stored.isNotEmpty) {
        try {
          return await decode(await ui.ImmutableBuffer.fromUint8List(stored));
        } catch (_) {
          await cache.remove(url);
        }
      }
      final bytes = await _download();
      final codec = await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
      await cache.write(url, bytes);
      return codec;
    } catch (_) {
      // Sin esto el fallo quedaría memorizado y no habría reintento.
      PaintingBinding.instance.imageCache.evict(this);
      rethrow;
    }
  }

  Future<Uint8List> _download() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200 || response.contentLength > _maxBytes) {
        throw HttpException('Foto no disponible (${response.statusCode})');
      }
      final bytes = await consolidateHttpClientResponseBytes(response);
      if (bytes.isEmpty || bytes.length > _maxBytes) throw const HttpException('Foto no disponible');
      return bytes;
    } finally {
      client.close();
    }
  }

  @override
  bool operator ==(Object other) => other is NexoPhotoProvider && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
