import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/toast.dart';
import 'private_chat_media.dart';

/// Micrófono detrás de una interfaz para poder probar los gestos sin hardware.
abstract class VoiceCapture {
  Future<bool> hasPermission();

  /// PCM de 16 bits, 16 kHz, mono.
  Future<Stream<Uint8List>> start();
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> dispose();
}

class _DeviceVoiceCapture implements VoiceCapture {
  final _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();
  @override
  Future<Stream<Uint8List>> start() =>
      _recorder.startStream(const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1));
  @override
  Future<void> pause() => _recorder.pause();
  @override
  Future<void> resume() => _recorder.resume();
  @override
  Future<void> stop() => _recorder.stop();
  @override
  Future<void> dispose() => _recorder.dispose();
}

final voiceCaptureProvider = Provider<VoiceCapture Function()>((ref) => _DeviceVoiceCapture.new);

/// Envuelve PCM 16 kHz mono en un WAV y borra los fragmentos originales.
Uint8List pcmToWav(List<Uint8List> parts) {
  final size = parts.fold(0, (total, part) => total + part.length);
  final wav = Uint8List(44 + size);
  final header = ByteData.sublistView(wav);
  void word(int offset, String value) => wav.setRange(offset, offset + value.length, value.codeUnits);
  word(0, 'RIFF');
  header.setUint32(4, 36 + size, Endian.little);
  word(8, 'WAVE');
  word(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, 1, Endian.little);
  header.setUint32(24, 16000, Endian.little);
  header.setUint32(28, 32000, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  word(36, 'data');
  header.setUint32(40, size, Endian.little);
  var offset = 44;
  for (final part in parts) {
    wav.setRange(offset, offset + part.length, part);
    offset += part.length;
    part.fillRange(0, part.length, 0);
  }
  return wav;
}

/// Menos de medio segundo de audio no es una nota de voz.
const _minimumBytes = 16000;

/// Distancias del gesto: izquierda cancela, arriba bloquea.
const kVoiceCancelDistance = 110.0;
const kVoiceLockDistance = 80.0;

enum _Phase { idle, holding, locked, preview }

/// Fila inferior del chat. Mientras no se graba muestra [child] (el campo de
/// texto) y, si [showMic], el micrófono que se mantiene presionado.
class VoiceComposer extends ConsumerStatefulWidget {
  const VoiceComposer({
    super.key,
    required this.child,
    required this.trailing,
    required this.showMic,
    required this.accent,
    required this.onSend,
  });

  final Widget child;

  /// Botón de enviar texto; se usa cuando no corresponde el micrófono.
  final Widget trailing;
  final bool showMic;
  final Color accent;

  /// Recibe el WAV; los bytes se borran al volver, así que hay que copiarlos.
  final void Function(Uint8List wav) onSend;

  @override
  ConsumerState<VoiceComposer> createState() => _VoiceComposerState();
}

class _VoiceComposerState extends ConsumerState<VoiceComposer> with WidgetsBindingObserver {
  _Phase _phase = _Phase.idle;
  VoiceCapture? _capture;
  StreamSubscription<Uint8List>? _stream;
  Timer? _clock;
  final _elapsed = Stopwatch();
  final _parts = <Uint8List>[];
  final _levels = <double>[];
  Uint8List? _preview;
  bool _paused = false;
  bool _starting = false;
  bool _fingerDown = false;
  Offset _origin = Offset.zero;
  Offset _drag = Offset.zero;
  int _size = 0;

  /// Cada grabación tiene un número; lo que llegue de una anterior se ignora.
  int _session = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al salir de la app no se envía ni se pierde: queda lista para escuchar.
    if (state != AppLifecycleState.resumed && (_phase == _Phase.holding || _phase == _Phase.locked)) {
      unawaited(_finishToPreview());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _release();
    _wipe();
    super.dispose();
  }

  /// Detiene y libera el micrófono sin tocar el audio capturado.
  void _release() {
    _session++;
    _clock?.cancel();
    _elapsed.stop();
    final capture = _capture;
    final stream = _stream;
    _capture = null;
    _stream = null;
    if (capture != null) {
      unawaited(() async {
        try {
          await capture.stop();
        } catch (_) {
          // El micrófono ya estaba detenido.
        }
        await stream?.cancel();
        await capture.dispose();
      }());
    }
  }

  void _wipe() {
    for (final part in _parts) {
      part.fillRange(0, part.length, 0);
    }
    _parts.clear();
    _preview?.fillRange(0, _preview!.length, 0);
    _preview = null;
    _levels.clear();
    _size = 0;
  }

  void _reset() {
    _release();
    _wipe();
    _elapsed.reset();
    if (mounted) {
      setState(() {
        _phase = _Phase.idle;
        _paused = false;
        _drag = Offset.zero;
      });
    }
  }

  Future<void> _start({required bool locked}) async {
    if (_starting || _phase != _Phase.idle) return;
    _starting = true;
    final session = ++_session;
    final capture = ref.read(voiceCaptureProvider)();
    try {
      if (!await capture.hasPermission()) {
        showNexoToast('Activa el permiso de micrófono para grabar notas de voz.');
        await capture.dispose();
        return;
      }
      // Soltó mientras el sistema pedía permiso o preparaba el micrófono.
      if (!mounted || session != _session || (!locked && !_fingerDown)) {
        await capture.dispose();
        if (mounted) showNexoToast('Mantén presionado el micrófono para grabar.');
        return;
      }
      final stream = await capture.start();
      if (!mounted || session != _session) {
        await capture.stop();
        await capture.dispose();
        return;
      }
      _capture = capture;
      _stream = stream.listen(
        (part) {
          if (session != _session || !mounted) return;
          _parts.add(Uint8List.fromList(part));
          _size += part.length;
          if (part.length >= 2) {
            final pcm = ByteData.sublistView(part);
            var peak = 0;
            for (var i = 0; i + 1 < part.length; i += 64) {
              peak = math.max(peak, pcm.getInt16(i, Endian.little).abs());
            }
            _levels.add((peak / 20000).clamp(.08, 1.0));
            if (_levels.length > 60) _levels.removeAt(0);
          }
          setState(() {});
        },
        onError: (_) {
          showNexoToast('No se pudo grabar el audio.');
          _reset();
        },
      );
      _elapsed
        ..reset()
        ..start();
      _clock = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) setState(() {});
      });
      unawaited(HapticFeedback.mediumImpact());
      setState(() => _phase = locked ? _Phase.locked : _Phase.holding);
    } catch (_) {
      showNexoToast('No pudimos usar el micrófono. Inténtalo de nuevo.');
      await capture.dispose();
    } finally {
      _starting = false;
    }
  }

  /// Cierra la grabación y devuelve el WAV, o `null` si es demasiado corta.
  Future<Uint8List?> _finish() async {
    final capture = _capture;
    if (capture == null) return null;
    _clock?.cancel();
    _elapsed.stop();
    try {
      // Detener antes de cancelar permite recibir el último fragmento.
      await capture.stop();
    } catch (_) {
      return null;
    }
    final enough = _size >= _minimumBytes;
    final wav = enough ? pcmToWav(_parts) : null;
    _release();
    _parts.clear();
    return wav;
  }

  Future<void> _sendNow() async {
    final wav = _phase == _Phase.preview ? _preview : await _finish();
    if (!mounted) return;
    if (wav == null) {
      showNexoToast('Nota muy corta. Mantén presionado un poco más.');
      _reset();
      return;
    }
    unawaited(HapticFeedback.lightImpact());
    try {
      widget.onSend(wav);
    } finally {
      wav.fillRange(0, wav.length, 0);
      _preview = null;
      _reset();
    }
  }

  Future<void> _finishToPreview() async {
    final wav = await _finish();
    if (!mounted) return;
    if (wav == null) {
      _reset();
      return;
    }
    setState(() {
      _preview = wav;
      _phase = _Phase.preview;
      _paused = false;
    });
  }

  void _cancel() {
    unawaited(HapticFeedback.heavyImpact());
    _reset();
  }

  Future<void> _togglePause() async {
    final capture = _capture;
    if (capture == null) return;
    if (_paused) {
      await capture.resume();
      _elapsed.start();
    } else {
      await capture.pause();
      _elapsed.stop();
    }
    if (mounted) setState(() => _paused = !_paused);
  }

  void _pointerDown(PointerDownEvent event) {
    _fingerDown = true;
    _origin = event.position;
    _drag = Offset.zero;
    unawaited(_start(locked: false));
  }

  void _pointerMove(PointerMoveEvent event) {
    if (_phase != _Phase.holding) return;
    final delta = event.position - _origin;
    if (delta.dx <= -kVoiceCancelDistance) {
      _fingerDown = false;
      _cancel();
    } else if (delta.dy <= -kVoiceLockDistance) {
      unawaited(HapticFeedback.selectionClick());
      setState(() => _phase = _Phase.locked);
    } else {
      setState(() => _drag = Offset(math.min(0, delta.dx), math.min(0, delta.dy)));
    }
  }

  void _pointerUp({required bool cancelled}) {
    _fingerDown = false;
    if (_phase != _Phase.holding) return;
    if (cancelled) {
      _reset();
    } else if (_elapsed.elapsedMilliseconds < 600 && _size < _minimumBytes) {
      showNexoToast('Mantén presionado el micrófono para grabar.');
      _reset();
    } else {
      unawaited(_sendNow());
    }
  }

  String get _time => voiceTime(_elapsed.elapsedMilliseconds);

  Widget _dot() => _BlinkingDot(paused: _paused);

  Widget _round({required IconData icon, required Color color, Color iconColor = Colors.white, double size = 48}) =>
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: size * .5),
      );

  /// El micrófono permanece en el mismo lugar del árbol durante todo el gesto.
  Widget _mic() {
    final holding = _phase == _Phase.holding;
    return Semantics(
      button: true,
      label: 'Grabar nota de voz',
      hint: 'Mantén presionado para grabar',
      // Con lector de pantalla, un toque inicia la grabación bloqueada.
      onTap: () => unawaited(_start(locked: true)),
      child: Listener(
        key: const ValueKey('voice-mic'),
        behavior: HitTestBehavior.opaque,
        onPointerDown: _pointerDown,
        onPointerMove: _pointerMove,
        onPointerUp: (_) => _pointerUp(cancelled: false),
        onPointerCancel: (_) => _pointerUp(cancelled: true),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (holding)
                Positioned(
                  bottom: 76,
                  child: IgnorePointer(
                    child: Container(
                      width: 40,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: NexoColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 3))],
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 19, color: widget.accent),
                          const SizedBox(height: 4),
                          const Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: NexoColors.muted),
                        ],
                      ),
                    ),
                  ),
                ),
              Transform.translate(
                offset: holding ? _drag : Offset.zero,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 140),
                  scale: holding ? 1.45 : 1,
                  child: _round(icon: Icons.mic_rounded, color: widget.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _holdingBar() {
    final fade = (1 + _drag.dx / kVoiceCancelDistance).clamp(0.2, 1.0);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: NexoColors.field, borderRadius: BorderRadius.circular(26)),
      child: Row(
        children: [
          _dot(),
          const SizedBox(width: 8),
          Text(_time, style: NexoText.body(15, weight: FontWeight.w700)),
          Expanded(
            child: Opacity(
              opacity: fade,
              child: Transform.translate(
                offset: Offset(_drag.dx * .45, 0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    children: [
                      const Icon(Icons.chevron_left_rounded, size: 20, color: NexoColors.muted),
                      Text('Desliza para cancelar', style: NexoText.body(13.5, color: NexoColors.muted)),
                      const SizedBox(width: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordingPanel() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          const SizedBox(width: 6),
          _dot(),
          const SizedBox(width: 8),
          Text(_time, style: NexoText.body(16, weight: FontWeight.w800)),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(height: 32, child: CustomPaint(painter: _LevelsPainter(List.of(_levels), widget.accent))),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          IconButton(
            tooltip: 'Eliminar grabación',
            onPressed: _cancel,
            icon: const Icon(Icons.delete_outline_rounded, color: NexoColors.danger),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: _paused ? 'Continuar grabando' : 'Pausar grabación',
                  onPressed: _togglePause,
                  icon: Icon(_paused ? Icons.mic_rounded : Icons.pause_rounded, color: NexoColors.danger),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Escuchar antes de enviar',
                  onPressed: _finishToPreview,
                  icon: const Icon(Icons.headphones_rounded, color: NexoColors.ink),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Enviar nota de voz',
            onPressed: _sendNow,
            padding: EdgeInsets.zero,
            icon: _round(icon: Icons.send_rounded, color: widget.accent),
          ),
        ],
      ),
    ],
  );

  Widget _previewPanel() => Row(
    children: [
      IconButton(
        tooltip: 'Eliminar grabación',
        onPressed: _cancel,
        icon: const Icon(Icons.delete_outline_rounded, color: NexoColors.danger),
      ),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: NexoColors.field, borderRadius: BorderRadius.circular(24)),
          child: PrivateChatMedia(
            key: ValueKey(_preview),
            conversation: 'preview',
            file: const {'id': 'voice-preview', 'type': 'audio/wav'},
            initialBytes: _preview,
          ),
        ),
      ),
      const SizedBox(width: 6),
      IconButton(
        tooltip: 'Enviar nota de voz',
        onPressed: _sendNow,
        padding: EdgeInsets.zero,
        icon: _round(icon: Icons.send_rounded, color: widget.accent),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (_phase == _Phase.locked) {
      content = _recordingPanel();
    } else if (_phase == _Phase.preview) {
      content = _previewPanel();
    } else {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            // El campo se conserva montado para no perder foco ni borrador.
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Visibility(
                  visible: _phase == _Phase.idle,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: widget.child,
                ),
                if (_phase == _Phase.holding) _holdingBar(),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (widget.showMic || _phase == _Phase.holding) _mic() else widget.trailing,
        ],
      );
    }
    return PopScope(
      canPop: _phase == _Phase.idle,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _phase != _Phase.idle) _cancel();
      },
      child: content,
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot({required this.paused});
  final bool paused;

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700), value: 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_BlinkingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.paused || MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true, min: .25, max: 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _controller,
    child: Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: widget.paused ? NexoColors.muted : const Color(0xFFE5484D),
        shape: BoxShape.circle,
      ),
    ),
  );
}

class _LevelsPainter extends CustomPainter {
  _LevelsPainter(this.levels, this.color);
  final List<double> levels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.6;
    const gap = 5.0;
    final bars = size.width ~/ gap;
    for (var i = 0; i < bars; i++) {
      final index = levels.length - bars + i;
      final level = index >= 0 ? levels[index] : .08;
      final half = level * size.height / 2;
      final x = i * gap + 2;
      canvas.drawLine(Offset(x, size.height / 2 - half), Offset(x, size.height / 2 + half), paint);
    }
  }

  @override
  bool shouldRepaint(_LevelsPainter old) => true;
}
