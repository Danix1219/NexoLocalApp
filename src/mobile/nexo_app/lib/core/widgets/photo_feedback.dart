import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import 'nexo_button.dart';
import 'ui.dart';

/// Shimmer sobre la foto elegida mientras el servidor la revisa.
class PhotoProcessingOverlay extends StatefulWidget {
  const PhotoProcessingOverlay({super.key, this.circular = false});
  final bool circular;
  @override
  State<PhotoProcessingOverlay> createState() => _PhotoProcessingOverlayState();
}

class _PhotoProcessingOverlayState extends State<PhotoProcessingOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = MediaQuery.disableAnimationsOf(context);
    final shimmer = AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-2 + 3 * (motion ? .5 : _controller.value), -1),
            end: Alignment(-1 + 3 * (motion ? .5 : _controller.value), 1),
            colors: const [Color(0xB8DCEDE7), Color(0xE8FFFFFF), Color(0xB8DCEDE7)],
          ),
        ),
      ),
    );
    return Semantics(
      label: 'Revisando foto',
      liveRegion: true,
      child: IgnorePointer(child: widget.circular ? ClipOval(child: shimmer) : shimmer),
    );
  }
}

Future<void> showPhotoViewer(
  BuildContext context,
  String? url, {
  required String title,
  VoidCallback? onChange,
  bool circular = false,
  String? name,
  String? profileLink,
  Future<String> Function()? requestProfileLink,
  String? editLabel,
}) async {
  if (!circular && (url == null || url.isEmpty)) {
    onChange?.call();
    return;
  }
  final viewerMessenger = GlobalKey<ScaffoldMessengerState>();
  void notice(String text) => viewerMessenger.currentState?.showSnackBar(SnackBar(content: Text(text)));
  String? resolvedLink = profileLink;
  bool preparing = false;
  Future<void> withLink(Future<void> Function(String) action) async {
    if (preparing) return;
    preparing = true;
    try {
      if (resolvedLink == null) notice('Preparando enlace de perfil...');
      resolvedLink ??= await requestProfileLink!();
      if (context.mounted) await action(resolvedLink!);
    } catch (error) {
      notice(apiErrorMessage(error));
    } finally {
      preparing = false;
    }
  }

  await showDialog<void>(
    context: context,
    builder: (dialog) => Dialog.fullscreen(
      backgroundColor: const Color(0xFF0C1014),
      child: ScaffoldMessenger(
        key: viewerMessenger,
        child: Scaffold(
          backgroundColor: const Color(0xFF0C1014),
          body: Stack(
            children: [
              if (url != null && url.isNotEmpty)
                Positioned.fill(
                  child: Opacity(
                    opacity: .28,
                    child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 35, sigmaY: 35), child: NexoImage(url)),
                  ),
                ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xA00C1014), Color(0x150C1014), Color(0xFF0C1014)],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Volver al perfil',
                            onPressed: () => Navigator.pop(dialog),
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          ),
                          Expanded(
                            child: Text(
                              name ?? (circular ? 'Foto de perfil' : 'Portada'),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, bounds) {
                          final size = (MediaQuery.sizeOf(context).width * .69).clamp(
                            100.0,
                            bounds.maxHeight.clamp(100.0, 420.0),
                          );
                          if (!circular) {
                            return Center(
                              child: InteractiveViewer(
                                minScale: 1,
                                maxScale: 4,
                                child: NexoImage(url!, fit: BoxFit.contain),
                              ),
                            );
                          }
                          return Center(
                            child: SizedBox(
                              width: size,
                              height: size,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white.withValues(alpha: .12)),
                                        boxShadow: const [
                                          BoxShadow(color: Color(0x70000000), blurRadius: 40, offset: Offset(0, 16)),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: url == null || url.isEmpty
                                            ? Center(
                                                child: Text(
                                                  (name ?? '').isEmpty ? '?' : name!.characters.first.toUpperCase(),
                                                  style: const TextStyle(color: Colors.white, fontSize: 70),
                                                ),
                                              )
                                            : NexoImage(url),
                                      ),
                                    ),
                                  ),
                                  if (onChange != null)
                                    Positioned(
                                      right: 3,
                                      bottom: 5,
                                      child: IconButton.filled(
                                        style: IconButton.styleFrom(
                                          backgroundColor: const Color(0xFF10171B),
                                          side: const BorderSide(color: Colors.white24),
                                          minimumSize: const Size(52, 52),
                                        ),
                                        tooltip: editLabel ?? 'Editar foto de perfil',
                                        onPressed: () {
                                          Navigator.pop(dialog);
                                          onChange();
                                        },
                                        icon: const Icon(Icons.edit_outlined, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (circular)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (profileLink != null || requestProfileLink != null)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _PhotoAction(
                                      Icons.ios_share_rounded,
                                      'Compartir perfil',
                                      () => withLink((link) async {
                                        await const MethodChannel('mx.nexolocal/share').invokeMethod('share', {
                                          'text': link,
                                          'title': name ?? 'Perfil de Nexo Local',
                                        });
                                      }),
                                    ),
                                  ),
                                  Expanded(
                                    child: _PhotoAction(
                                      Icons.link_rounded,
                                      'Copiar enlace',
                                      () => withLink((link) async {
                                        await Clipboard.setData(ClipboardData(text: link));
                                        if (dialog.mounted) {
                                          viewerMessenger.currentState?.showSnackBar(
                                            const SnackBar(content: Text('Enlace de perfil copiado')),
                                          );
                                        }
                                      }),
                                    ),
                                  ),
                                  Expanded(
                                    child: _PhotoAction(
                                      Icons.qr_code_rounded,
                                      'C\u00f3digo QR',
                                      () => withLink(
                                        (link) => showDialog<void>(
                                          context: dialog,
                                          builder: (_) => ProfileQrCard(
                                            name: name ?? 'Perfil de Nexo Local',
                                            photoUrl: url,
                                            link: link,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    if (!circular && onChange != null)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: NexoButton(
                          label: title,
                          icon: 'camera',
                          onPressed: () {
                            Navigator.pop(dialog);
                            onChange();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PhotoAction extends StatelessWidget {
  const _PhotoAction(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.all(6)),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, size: 27),
        ),
        const SizedBox(height: 9),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.25)),
      ],
    ),
  );
}

/// Identity stays outside the QR: no logo covers its modules or quiet zone.
class ProfileQrCard extends StatelessWidget {
  const ProfileQrCard({super.key, required this.name, required this.link, this.photoUrl});
  final String name;
  final String link;
  final String? photoUrl;

  static const _avatar = 84.0;

  Future<void> _share(BuildContext context) async {
    try {
      await const MethodChannel('mx.nexolocal/share').invokeMethod('share', {'text': link, 'title': 'Perfil de $name'});
    } on PlatformException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos abrir las opciones para compartir. Intenta copiar el enlace.')),
        );
      }
    }
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace de perfil copiado')));
    }
  }

  Widget _header(BuildContext context) => SizedBox(
    height: 96 + _avatar / 2,
    child: Stack(
      children: [
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 96,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [NexoColors.welcomeTop, NexoColors.welcomeMid],
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          top: 18,
          right: 64,
          child: Text(
            'MI CÓDIGO NEXO',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NexoText.body(12, weight: FontWeight.w800, color: Colors.white70, letterSpacing: 1.8),
          ),
        ),
        Positioned(
          right: 8,
          top: 6,
          child: IconButton(
            tooltip: 'Cerrar código QR',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: NexoColors.surface,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x2E031E1B), blurRadius: 18, offset: Offset(0, 6))],
              ),
              child: NexoAvatar(name: name, url: photoUrl, size: _avatar - 8),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _code() => Semantics(
    label: 'Código QR para abrir el perfil de $name',
    image: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NexoColors.brandSoft, NexoColors.accentSoft],
        ),
      ),
      child: RepaintBoundary(
        key: const ValueKey('profile-qr-artifact'),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(8),
          child: LayoutBuilder(
            builder: (_, bounds) => QrImageView(
              data: link,
              key: ValueKey(link),
              size: bounds.maxWidth,
              padding: EdgeInsets.all(
                bounds.maxWidth *
                    4 /
                    (QrValidator.validate(data: link, errorCorrectionLevel: QrErrorCorrectLevel.Q).qrCode!.moduleCount +
                        8),
              ),
              errorCorrectionLevel: QrErrorCorrectLevel.Q,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: NexoColors.brandDeep),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: NexoColors.ink,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
    backgroundColor: NexoColors.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 370),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
              child: Column(
                children: [
                  Text(name, textAlign: TextAlign.center, style: NexoText.display(22, height: 1.2)),
                  const SizedBox(height: 18),
                  _code(),
                  const SizedBox(height: 16),
                  Text(
                    'Escanea para abrir este perfil en Nexo Local.',
                    textAlign: TextAlign.center,
                    style: NexoText.body(14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Necesitas tener la app instalada.',
                    textAlign: TextAlign.center,
                    style: NexoText.body(12.5, color: NexoColors.muted),
                  ),
                  const SizedBox(height: 18),
                  NexoButton(label: 'Compartir perfil', icon: 'share', onPressed: () => _share(context)),
                  const SizedBox(height: 8),
                  NexoButton(label: 'Copiar enlace', variant: NexoButtonVariant.line, onPressed: () => _copy(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
