import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/nexo_navigation.dart';
import '../../core/widgets/nexo_motion.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/photo_feedback.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../../core/widgets/pick_image.dart';
import '../common/cards.dart';

/// Personal profile: cover, overlapping avatar, identity, activity and tabs.
class MyProfilePage extends ConsumerStatefulWidget {
  const MyProfilePage({super.key, required this.initial, required this.onEdit});
  final AccountScreen initial;
  final ValueChanged<AccountScreen> onEdit;
  @override
  ConsumerState<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends ConsumerState<MyProfilePage> {
  int _tab = 0;
  bool _photoBusy = false;
  bool _loadingCover = false;
  String? _pendingPhoto;
  Future<void> _changePhoto({bool cover = false}) async {
    if (_photoBusy) return;
    final image = await pickOneImage(context);
    if (image == null || !mounted) return;
    setState(() {
      _photoBusy = true;
      _loadingCover = cover;
      _pendingPhoto = 'file://${image.path}';
    });
    try {
      final api = ref.read(apiProvider);
      final id = await api.upload(image, purpose: cover ? 'cover' : 'avatar');
      if (cover) {
        await api.setMyCover(id);
        ref.invalidate(myCoverProvider);
        await ref.read(myCoverProvider.future);
      } else {
        await api.updateMe(photoUploadId: id);
        ref.invalidate(accountProvider);
        await ref.read(accountProvider.future);
      }
      showNexoToast('Foto actualizada');
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
    } finally {
      if (mounted)
        setState(() {
          _photoBusy = false;
          _pendingPhoto = null;
        });
    }
  }

  Future<void> _preview(String? url, {required bool cover}) => showPhotoViewer(
        context,
        url,
        title: cover ? 'Cambiar portada' : 'Cambiar foto de perfil',
        circular: !cover,
        onChange: () => _changePhoto(cover: cover),
      );

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider).asData?.value ?? widget.initial;
    final location = ref.watch(searchLocationProvider);
    final requests = ref.watch(myRequestsProvider);
    final cover = ref.watch(myCoverProvider).asData?.value;
    final saved = ref.watch(savedProvider);
    return NexoPage(
      background: NexoColors.surface,
      bottom: const NexoNavigation(current: 4),
      child: Column(children: [
        const SubBar('Mi perfil'),
        Expanded(
            child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
              child: SizedBox(
                  height: 208,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: 166,
                        child: ClipRect(
                            child: Stack(children: [
                          const Positioned.fill(
                              child: DecoratedBox(
                                  decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Color(0xFFDCEDE7), Color(0xFFEAF1E3), Color(0xFFF8E9CF)])))),
                          if (cover != null)
                            Positioned.fill(
                                child: InkWell(
                                    onTap: () => _preview(cover, cover: true),
                                    child: Hero(tag: 'my-cover', child: NexoImage(cover)))),
                          if (_photoBusy && _loadingCover && _pendingPhoto != null)
                            Positioned.fill(child: NexoImage(_pendingPhoto!)),
                          if (_photoBusy && _loadingCover) const Positioned.fill(child: PhotoProcessingOverlay()),
                          if (cover == null)
                            Positioned(
                                right: -30,
                                top: -70,
                                child: Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle, color: NexoColors.surface.withValues(alpha: .6)))),
                          Positioned(
                              right: 16,
                              bottom: 14,
                              child: Material(
                                color: NexoColors.surface,
                                elevation: 3,
                                shadowColor: const Color(0x301F302B),
                                borderRadius: BorderRadius.circular(99),
                                child: InkWell(
                                    borderRadius: BorderRadius.circular(99),
                                    onTap: _photoBusy ? null : () => _changePhoto(cover: true),
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                                          const NexoIcon('camera', size: 14, color: NexoColors.brand),
                                          const SizedBox(width: 6),
                                          Text(cover == null ? 'Agregar portada' : 'Cambiar portada',
                                              style: NexoText.body(12.5, weight: FontWeight.w800)),
                                        ]))),
                              )),
                        ]))),
                    Positioned(
                        left: 16,
                        top: 124,
                        child: Stack(clipBehavior: Clip.none, children: [
                          Container(
                              decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [
                                BoxShadow(color: Color(0x241F302B), blurRadius: 20, offset: Offset(0, 6))
                              ]),
                              child: InkWell(
                                  onTap: () => _preview(account.photoUrl, cover: false),
                                  child: Hero(
                                      tag: 'my-avatar',
                                      child: NexoAvatar(
                                          name: account.name,
                                          url: _photoBusy && !_loadingCover ? _pendingPhoto : account.photoUrl,
                                          size: 88,
                                          border: true)))),
                          if (_photoBusy && !_loadingCover)
                            const Positioned.fill(child: PhotoProcessingOverlay(circular: true)),
                          Positioned(
                              right: -2,
                              bottom: -2,
                              child: Semantics(
                                  button: true,
                                  label: 'Cambiar foto de perfil',
                                  child: Material(
                                      color: NexoColors.brand,
                                      shape: const CircleBorder(side: BorderSide(color: NexoColors.surface, width: 3)),
                                      child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: _photoBusy ? null : () => _changePhoto(),
                                          child: const SizedBox(
                                              width: 34,
                                              height: 34,
                                              child:
                                                  Center(child: NexoIcon('camera', size: 16, color: Colors.white))))))),
                        ])),
                  ]))),
          SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              sliver: SliverToBoxAdapter(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(account.name, style: NexoText.display(23, weight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('Solicitante · ${location.zoneLabel}', style: NexoText.body(14, color: NexoColors.muted)),
                const SizedBox(height: 8),
                TextButton.icon(
                    onPressed: () => widget.onEdit(account),
                    icon: const NexoIcon('edit', size: 16, color: NexoColors.brand),
                    label: Text('Editar datos de mi perfil', style: NexoText.body(13, color: NexoColors.brand))),
                const SizedBox(height: 8),
                NBadge(account.emailVerified ? 'Correo verificado' : 'Correo pendiente',
                    icon: 'shield', tone: BadgeTone.ok),
                const SizedBox(height: 18),
                StatsRow([
                  (requests.asData?.value.length.toString() ?? '—', 'Solicitudes'),
                  ('—', 'Experiencias'),
                  (saved.asData?.value.$2.total.toString() ?? '—', 'Guardados')
                ]),
                const SizedBox(height: 16),
                LayoutBuilder(
                    builder: (_, constraints) => Wrap(spacing: 8, runSpacing: 8, children: [
                          SizedBox(
                              width: constraints.maxWidth < 300 ? constraints.maxWidth : (constraints.maxWidth - 8) / 2,
                              child: NexoButton(
                                  label: 'Nueva solicitud', icon: 'plus', onPressed: () => context.go('/publish'))),
                          SizedBox(
                              width: constraints.maxWidth < 300 ? constraints.maxWidth : (constraints.maxWidth - 8) / 2,
                              child: NexoButton(
                                  label: 'Mi experiencia',
                                  icon: 'thumb',
                                  variant: NexoButtonVariant.ghost,
                                  onPressed: () => showNexoToast('Publicar experiencias: próximamente.'))),
                        ])),
              ]))),
          SliverToBoxAdapter(
              child: Row(children: [
            for (var i = 0; i < 2; i++)
              Expanded(
                  child: NexoPressFeedback(
                child: InkWell(
                    onTap: () => setState(() => _tab = i),
                    child: AnimatedContainer(
                      duration: NexoMotion.duration(context, NexoMotion.press),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: _tab == i ? NexoColors.brand : NexoColors.line, width: _tab == i ? 2 : 1))),
                      child: Semantics(
                          selected: _tab == i,
                          button: true,
                          child: Text(i == 0 ? 'Solicitudes' : 'Experiencias',
                              textAlign: TextAlign.center,
                              style: NexoText.body(14,
                                  weight: FontWeight.w700, color: _tab == i ? NexoColors.brand : NexoColors.muted))),
                    )),
              ))
          ])),
          SliverToBoxAdapter(
              child: NexoEnter(
                  trigger: _tab,
                  child: _tab == 0
                      ? asyncView(
                          requests,
                          (items) => items.isEmpty
                              ? const EmptyState(
                                  icon: 'plus',
                                  title: 'Todavía no tienes solicitudes',
                                  text: 'Cuando publiques lo que necesitas, aparecerá aquí.')
                              : Column(children: [for (final request in items) RequestCard(r: request)]),
                          onRetry: () => ref.invalidate(myRequestsProvider))
                      : const EmptyState(
                          icon: 'thumb',
                          title: 'Próximamente',
                          text: 'Aquí aparecerán tus experiencias con los prestadores.'))),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ])),
      ]),
    );
  }
}
