import 'chat_backdrop.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/tokens.dart';
import 'chat_experience.dart';

const _audio = MethodChannel('mx.nexolocal/private-audio');
Future<void> playPrivateAudio(Uint8List bytes, {String id = 'preview'}) =>
    _audio.invokeMethod('play', {'bytes': bytes, 'id': id});
String voiceTime(int milliseconds) {
  final seconds = milliseconds ~/ 1000;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// Decrypted attachment bytes live only in account-scoped memory.
class PrivateChatMedia extends ConsumerStatefulWidget {
  const PrivateChatMedia({
    super.key,
    required this.conversation,
    required this.file,
    this.initialBytes,
    this.mine = false,
    this.style = 'linen',
  });
  final String conversation;
  final Map<String, dynamic> file;
  final Uint8List? initialBytes;
  final bool mine;
  final String style;
  @override
  ConsumerState<PrivateChatMedia> createState() => _PrivateChatMediaState();
}

class _PrivateChatMediaState extends ConsumerState<PrivateChatMedia> {
  Uint8List? _bytes;
  bool _busy = false;
  bool _playing = false;
  bool _paused = false;
  String? _error;
  Timer? _positionTimer;
  int _position = 0;
  int _duration = 0;
  String get _id => '${widget.conversation}:${widget.file['id'] ?? 'local'}';
  bool get _image => '${widget.file['type']}'.startsWith('image/');
  Color get _ink => widget.mine ? Colors.white : ChatPalette.forStyle(widget.style).ink;
  @override
  void initState() {
    super.initState();
    _bytes = widget.initialBytes == null
        ? ref.read(chatExperienceProvider).media(_id)
        : Uint8List.fromList(widget.initialBytes!);
    _duration = widget.file['durationMs'] as int? ?? 0;
    if (_bytes != null && !_image) _readDuration();
    if (_bytes == null) unawaited(_load());
  }

  void _readDuration() {
    if (_bytes != null && _bytes!.length >= 44) _duration = ((_bytes!.length - 44) * 1000 / 32000).round();
  }

  Future<void> _load() async {
    if (_busy || _bytes != null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await ref.read(chatExperienceProvider).loadMedia(widget.conversation, widget.file);
      if (!mounted) {
        bytes.fillRange(0, bytes.length, 0);
        return;
      }
      setState(() {
        _bytes = bytes;
        if (!_image) _readDuration();
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo cargar. Toca para reintentar.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleAudio() async {
    try {
      if (_playing) {
        await _audio.invokeMethod('pause', _id);
        if (mounted) {
          setState(() {
            _playing = false;
            _paused = true;
          });
        }
        return;
      }
      if (_bytes == null) await _load();
      if (!mounted || _bytes == null) return;
      if (_paused) {
        await _audio.invokeMethod('resume', _id);
      } else {
        await playPrivateAudio(_bytes!, id: _id);
      }
      if (!mounted) return;
      setState(() {
        _playing = true;
        _paused = false;
        _error = null;
      });
      _positionTimer?.cancel();
      _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) async {
        try {
          final value = await _audio.invokeMapMethod<String, dynamic>('position');
          if (!mounted) return;
          if (value?['id'] != _id) {
            _positionTimer?.cancel();
            setState(() {
              _playing = false;
              _paused = false;
              _position = 0;
            });
          } else {
            setState(() {
              _position = value?['position'] as int? ?? 0;
              _duration = value?['duration'] as int? ?? _duration;
            });
          }
        } catch (_) {
          _positionTimer?.cancel();
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _paused = false;
          _error = 'No se pudo reproducir. Reintentar';
        });
      }
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    if (_playing || _paused) unawaited(_audio.invokeMethod('stop', _id).catchError((Object _) {}));
    if (_bytes != null) {
      PaintingBinding.instance.imageCache.evict(MemoryImage(_bytes!), includeLive: true);
      _bytes!.fillRange(0, _bytes!.length, 0);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_image) {
      return GestureDetector(
        onTap: _bytes == null
            ? _load
            : () => showDialog<void>(
                context: context,
                builder: (_) => Dialog.fullscreen(
                  backgroundColor: Colors.black,
                  child: SafeArea(
                    child: Stack(
                      children: [
                        Center(
                          child: InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Image.memory(_bytes!, fit: BoxFit.contain),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: IconButton.filledTonal(
                            tooltip: 'Cerrar foto',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            width: 260,
            child: _bytes != null
                ? ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 120, maxHeight: 320),
                    child: Image.memory(
                      _bytes!,
                      cacheWidth: 780,
                      width: 260,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, error, stack) =>
                          const SizedBox(height: 150, child: Center(child: Text('Imagen no compatible'))),
                    ),
                  )
                : Container(
                    height: 190,
                    color: ChatPalette.forStyle(widget.style).soft,
                    alignment: Alignment.center,
                    child: _busy
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.image_outlined, size: 32),
                              Text(_error ?? 'Cargar foto', textAlign: TextAlign.center),
                            ],
                          ),
                  ),
          ),
        ),
      );
    }
    return SizedBox(
      width: 240,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: _playing ? 'Pausar nota de voz' : 'Reproducir nota de voz',
                  style: IconButton.styleFrom(
                    backgroundColor: widget.mine
                        ? Colors.white.withValues(alpha: .18)
                        : ChatPalette.forStyle(widget.style).soft,
                    foregroundColor: _ink,
                  ),
                  onPressed: _busy ? null : _toggleAudio,
                  icon: _busy
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _ink))
                      : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        label: 'Progreso de nota de voz',
                        child: GestureDetector(
                          onTapDown: _bytes == null || _duration == 0
                              ? null
                              : (details) async {
                                  // Native player remains the source of timing; never fake playback progress.
                                  final box = context.findRenderObject() as RenderBox?;
                                  if (box != null && (_playing || _paused)) {
                                    await _audio.invokeMethod('seek', {
                                      'id': _id,
                                      'position': ((_duration * details.localPosition.dx / (box.size.width - 64)))
                                          .round()
                                          .clamp(0, _duration),
                                    });
                                  }
                                },
                          child: SizedBox(
                            height: 27,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _Waveform(_bytes, _duration == 0 ? 0 : _position / _duration, _ink),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _duration == 0 && _bytes == null
                            ? 'Nota de voz'
                            : '${voiceTime(_position > 0 ? _position : _duration)}  \u00b7  Nota de voz',
                        style: TextStyle(fontSize: 11, color: _ink.withValues(alpha: .75)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_error != null) Text(_error!, style: TextStyle(fontSize: 11, color: _ink)),
          ],
        ),
      ),
    );
  }
}

class _Waveform extends CustomPainter {
  _Waveform(this.bytes, this.progress, this.color);
  final Uint8List? bytes;
  final double progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    const count = 30;
    final paint = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final data = bytes == null || bytes!.length < 46 ? null : ByteData.sublistView(bytes!);
    final samples = data == null ? 0 : (bytes!.length - 44) ~/ 2;
    for (var i = 0; i < count; i++) {
      var amplitude = .1;
      if (data != null && samples > 0) {
        final sample = math.min(samples - 1, (samples * i / count).floor());
        amplitude = (data.getInt16(44 + sample * 2, Endian.little).abs() / 16000).clamp(.12, 1.0);
      }
      paint.color = color.withValues(alpha: i / count <= progress ? 1 : .35);
      final x = 2 + i * (size.width - 4) / (count - 1);
      final half = size.height * amplitude / 2;
      canvas.drawLine(Offset(x, size.height / 2 - half), Offset(x, size.height / 2 + half), paint);
    }
  }

  @override
  bool shouldRepaint(_Waveform old) => old.bytes != bytes || old.progress != progress || old.color != color;
}

/// The user reviews the actual image and optional caption before encrypting.
Future<String?> previewChatPhoto(BuildContext context, Uint8List bytes) => showModalBottomSheet<String>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  backgroundColor: const Color(0xFF111D1B),
  builder: (_) => _PhotoPreview(bytes),
);

class _PhotoPreview extends StatefulWidget {
  const _PhotoPreview(this.bytes);
  final Uint8List bytes;
  @override
  State<_PhotoPreview> createState() => _PhotoPreviewState();
}

class _PhotoPreviewState extends State<_PhotoPreview> {
  final _caption = TextEditingController();
  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .92,
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Cancelar foto',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    'Enviar foto',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.lock_outline_rounded, color: Colors.white60, size: 18),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(child: Image.memory(widget.bytes, fit: BoxFit.contain)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'Revisa la foto. Solo ustedes pueden ver su contenido.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _caption,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'A\u00f1ade un mensaje\u2026',
                      hintStyle: const TextStyle(color: Colors.white60),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: .1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  tooltip: 'Enviar foto',
                  style: IconButton.styleFrom(backgroundColor: NexoColors.brand, minimumSize: const Size(50, 50)),
                  onPressed: () => Navigator.pop(context, _caption.text.trim()),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
