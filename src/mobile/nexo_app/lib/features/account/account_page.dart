import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/env.dart';
import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/auth/session_controller.dart';
import '../../core/auth/token_storage.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/map_view.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_field.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/nexo_sheet.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/catalog_status.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/legal_sheets.dart';
import '../provider/edit_sheets.dart';
import '../push/push_controller.dart';
import '../shell/top_bar.dart';
import 'phone_sheet.dart';

/// 7.13 Cuenta (`V.account`).
class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  bool _switching = false;
  bool _leaving = false;

  Future<void> _setMode(String mode, AccountScreen a) async {
    final s = ref.read(sessionProvider);
    if (s.mode == mode || _switching) return;
    final hasProvider = ref.read(myProviderProvider).asData?.value != null || a.hasProvider;
    if (mode == 'provider' && !hasProvider) {
      context.push(Routes.proOnboarding);
      return;
    }
    setState(() => _switching = true);
    try {
      final tokens = await ref.read(apiProvider).switchMode(mode);
      await ref.read(sessionProvider.notifier).setMode(mode, tokens: tokens, hasProvider: hasProvider);
      ref.read(compareProvider.notifier).clear();
      refreshActivity(ref);
      if (mounted) context.go(Routes.home);
      showNexoToast(mode == 'provider' ? 'Ahora estás en Modo Proveedor' : 'Ahora estás en Modo Cliente');
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  /// `logoutSheet` → `POST /v1/identity/logout` + limpieza local.
  Future<void> _logout() async {
    final ok = await confirmSheet(
      context,
      title: '¿Cerrar sesión?',
      subtitle: 'Tus datos se conservan. Podrás volver a entrar con tu correo y contraseña.',
      confirmLabel: 'Cerrar sesión',
    );
    if (ok != true || _leaving) return;
    setState(() => _leaving = true);
    // Primero se da de baja el teléfono para push (necesita la sesión).
    await ref.read(pushProvider.notifier).disable();
    final tokens = await ref.read(tokenStorageProvider).read();
    final remote = tokens == null ? true : await ref.read(authRepositoryProvider).logout(tokens.refreshToken);
    ref.read(compareProvider.notifier).clear();
    await ref.read(sessionProvider.notifier).signOutLocal();
    showNexoToast(
        remote ? 'Sesión cerrada' : 'Sesión cerrada en este teléfono. El cierre en el servidor queda pendiente.');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);
    if (s.isGuest) return _guest();
    final v = ref.watch(accountProvider);
    return RefreshIndicator(
      color: NexoColors.brand,
      onRefresh: () async {
        ref.invalidate(accountProvider);
        ref.invalidate(myProviderProvider);
      },
      child: PinnedHeaderList(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          const ScreenTitleBar('Cuenta'),
          asyncView(v, (a) => a == null ? const SizedBox.shrink() : _body(s, a),
              onRetry: () => ref.invalidate(accountProvider)),
          if (v.hasError)
            Padding(
              padding: const EdgeInsets.all(16),
              child: NexoButton(
                label: 'Volver a iniciar sesi?n',
                variant: NexoButtonVariant.line,
                onPressed: () async {
                  ref.read(compareProvider.notifier).clear();
                  await ref.read(sessionProvider.notifier).signOutLocal();
                  ref.invalidate(accountProvider);
                  if (mounted) context.go(Routes.login);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _guest() {
    return PinnedHeaderList(children: [
      const ScreenTitleBar('Cuenta'),
      NexoCard(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: NexoColors.brandSoft, shape: BoxShape.circle),
            child: const Center(child: NexoIcon('user', size: 30, color: NexoColors.brand)),
          ),
          const SizedBox(height: 12),
          Text('Tu espacio en Nexo', style: NexoText.display(20)),
          const SizedBox(height: 4),
          Text('Crea una cuenta cuando quieras conservar tu actividad.',
              textAlign: TextAlign.center, style: NexoText.body(14, color: NexoColors.muted)),
          const SizedBox(height: 14),
          const Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            NBadge('Guardados', icon: 'bookmark', tone: BadgeTone.brand),
            NBadge('Publicaciones', icon: 'plus', tone: BadgeTone.brand),
            NBadge('Recomendaciones', icon: 'thumb', tone: BadgeTone.brand),
          ]),
          const SizedBox(height: 16),
          NexoButton(
            label: 'Crear una cuenta',
            onPressed: () {
              ref.read(sessionProvider.notifier).leaveGuest();
              context.go(Routes.registerEmail);
            },
          ),
          const SizedBox(height: 8),
          NexoButton(
            label: 'Iniciar sesión',
            variant: NexoButtonVariant.line,
            onPressed: () {
              ref.read(sessionProvider.notifier).leaveGuest();
              context.go(Routes.login);
            },
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Center(
        child: TextButton(
          onPressed: () => showPrivacySheet(context),
          child:
              Text('Aviso de privacidad', style: NexoText.body(13.5, weight: FontWeight.w700, color: NexoColors.brand)),
        ),
      ),
    ]);
  }

  Widget _box(String title, List<Widget> children) => NexoCard(
        title: title,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );

  Widget _body(SessionState s, AccountScreen a) {
    if (s.recoveryOnly) {
      return NexoCard(
          child: Column(children: [
        const Text('Tu cuenta tiene una baja pendiente'),
        const SizedBox(height: 12),
        const Text('Puedes cancelar la baja dentro de los 30 días de gracia.'),
        NexoButton(
            label: 'Conservar mi cuenta',
            onPressed: () async {
              try {
                await ref.read(apiProvider).cancelDeletion();
                final stored = await ref.read(tokenStorageProvider).read();
                final fresh = stored == null ? null : await refreshTokens(stored.refreshToken);
                if (fresh == null) {
                  await ref.read(sessionProvider.notifier).signOutLocal();
                } else {
                  await ref.read(sessionProvider.notifier).updateTokens(fresh);
                  refreshActivity(ref);
                  if (mounted) context.go(Routes.home);
                }
              } catch (e) {
                showNexoToast(apiErrorMessage(e));
              }
            }),
        NexoButton(label: 'Cerrar sesión', onPressed: _logout),
      ]));
    }
    final push = ref.watch(pushProvider);
    final pro = s.isProviderMode;
    final mp = ref.watch(myProviderProvider).asData?.value;
    final loc = ref.watch(searchLocationProvider);
    final interests = ref.watch(interestsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (a.pendingDeletion)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: NexoColors.warnSoft, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Tu cuenta se eliminará pronto',
                    style: NexoText.body(15, weight: FontWeight.w800, color: NexoColors.warn)),
                const SizedBox(height: 4),
                Text('Si cambiaste de opinión, puedes cancelarlo.', style: NexoText.body(13.5, color: NexoColors.warn)),
                const SizedBox(height: 10),
                NexoButton(
                  label: 'Cancelar eliminación',
                  small: true,
                  variant: NexoButtonVariant.line,
                  onPressed: () async {
                    try {
                      await ref.read(apiProvider).cancelDeletion();
                      final stored = await ref.read(tokenStorageProvider).read();
                      final fresh = stored == null ? null : await refreshTokens(stored.refreshToken);
                      if (fresh == null) {
                        await ref.read(sessionProvider.notifier).signOutLocal();
                      } else {
                        await ref.read(sessionProvider.notifier).updateTokens(fresh);
                        refreshActivity(ref);
                        if (mounted) context.go(Routes.home);
                      }
                      showNexoToast('Tu cuenta sigue activa');
                    } catch (e) {
                      showNexoToast(apiErrorMessage(e));
                    }
                  },
                ),
              ]),
            ),
          ),
        // ---- tarjeta propia (`selfcard`)
        NexoCard(
          onTap: () => pro && mp != null ? context.push(Routes.provider(mp.profile.id)) : _viewMe(a),
          child: Row(children: [
            NexoAvatar(name: a.name, url: (pro ? mp?.profile.photoUrl : null) ?? a.photoUrl, size: 50),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pro && mp != null ? mp.profile.name : a.name, style: NexoText.body(16, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Row(children: [
                  NexoIcon(a.emailVerified ? 'shield' : 'info',
                      size: 14, color: a.emailVerified ? NexoColors.ok : NexoColors.muted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                        '${a.emailVerified ? 'Correo verificado' : (a.email.isEmpty ? 'Cuenta' : a.email)} · ${pro && mp != null ? mp.profile.zoneLabel : loc.zoneLabel}',
                        overflow: TextOverflow.ellipsis,
                        style: NexoText.body(12.5, color: NexoColors.muted)),
                  ),
                ]),
              ]),
            ),
            Text('Ver perfil', style: NexoText.body(13, weight: FontWeight.w800, color: NexoColors.brand)),
            const NexoIcon('chevron', size: 16, color: NexoColors.brand),
          ]),
        ),
        // ---- modo (`roleBlock`)
        _box('Modo de uso', [
          SegControl<String>(
            options: const [('client', 'Cliente'), ('provider', 'Proveedor')],
            value: s.mode,
            onChanged: (m) => _setMode(m, a),
          ),
          if (_switching)
            const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(color: NexoColors.brand)),
          if (!a.hasProvider && mp == null) ...[
            const SizedBox(height: 8),
            Text('¿Ofreces servicios? Elige Proveedor y crea tu perfil con esta misma cuenta.',
                style: NexoText.body(12.5, color: NexoColors.muted)),
          ],
        ]),
        if (!pro) ...[
          _box('Tus intereses', [
            Wrap(spacing: 8, runSpacing: 8, children: [
              const CatalogStatus(),
              for (final c in (ref.watch(catalogProvider).asData?.value ?? []))
                ToggleChip(
                  label: c.name,
                  icon: c.icon,
                  selected: interests.contains(c.id),
                  onTap: () => ref.read(interestsProvider.notifier).toggle(c.id),
                ),
            ]),
          ]),
          _box('Tu ubicación', [
            if (!loc.hasSelection)
              NexoButton(label: 'Elegir mi ubicación', icon: 'pin', onPressed: () => openSearchLocation(context, ref))
            else
              MiniMap(
                point: loc.point,
                radiusKm: loc.radiusKm,
                label: '${loc.zoneLabel} · ${loc.radiusKm} km',
                actionLabel: 'Cambiar',
                onAction: () => openSearchLocation(context, ref),
              ),
          ]),
          _box('Tu actividad', [
            StatsRow([
              ('${a.requests}', 'Solicitudes'),
              ('${a.orders}', 'Servicios pedidos'),
              ('${a.saved.total}', 'Guardados'),
            ]),
          ]),
        ] else if (mp == null)
          _box('Crea tu perfil de prestador', [
            NexoButton(label: 'Crear mi perfil', onPressed: () => context.push(Routes.proOnboarding)),
          ])
        else ...[
          _box(mp.profile.attention == 'shop' ? 'Tu local' : 'Zona de atención', [
            MiniMap(
              point: mp.location ?? mp.profile.zonePoint ?? loc.point,
              radiusKm: mp.profile.attention == 'shop' ? 0 : mp.profile.radiusKm,
              label: mp.profile.zoneLabel,
              actionLabel: mp.profile.attention == 'shop' ? 'Cambiar' : 'hasta ${mp.profile.radiusKm} km',
              onAction: () => showZoneSheet(context, ref, mp.profile),
            ),
          ]),
          _box('Tu perfil', [
            Row(children: [
              Expanded(
                  child: Text('Completo al ${mp.completeness}%', style: NexoText.body(14, weight: FontWeight.w700))),
              if (a.nextTodo != null)
                Flexible(
                    child: Text('Sigue: ${a.nextTodo}',
                        textAlign: TextAlign.right, style: NexoText.body(12.5, color: NexoColors.muted))),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: LinearProgressIndicator(
                  value: mp.completeness / 100,
                  minHeight: 7,
                  color: NexoColors.brand,
                  backgroundColor: NexoColors.surface2),
            ),
            const SizedBox(height: 12),
            NexoButton(
              label: 'Ver mi perfil',
              variant: NexoButtonVariant.ghost,
              onPressed: () => context.push(Routes.provider(mp.profile.id)),
            ),
          ]),
          _box('Disponibilidad', [
            Text(mp.profile.updatedText, style: NexoText.body(13, color: NexoColors.muted)),
            const SizedBox(height: 4),
            Notice(mp.profile.status.text,
                icon: 'clock', tone: mp.profile.status.open ? BadgeTone.ok : BadgeTone.plain),
            const SizedBox(height: 10),
            NexoButton(
                label: 'Actualizar horario', icon: 'clock', onPressed: () => showHoursSheet(context, ref, mp.profile)),
          ]),
          _box('Cómo te contactan', [
            OptRow(icon: 'chat', label: 'Chat en Nexo · Activo', selected: true, onTap: () {}),
            const SizedBox(height: 8),
            OptRow(
              icon: 'phone',
              label: 'Mostrar mi número para llamadas · ${mp.profile.channelCall ? 'Activo' : 'Apagado'}',
              selected: mp.profile.channelCall,
              onTap: () => showTermsEditSheet(context, ref, mp.profile),
            ),
          ]),
          _box('Tu visibilidad', [
            StatsRow([
              ('${mp.views}', 'Visitas al perfil'),
              (mp.contactClicks?.toString() ?? '—', 'Clics de contacto'),
              ('${mp.profile.jobs}', 'Trabajos'),
            ]),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: NexoButton(label: 'Publicar un trabajo', icon: 'plus', onPressed: () => context.go(Routes.publish)),
          ),
        ],
        // ---- guardados, celular, privacidad
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: OptRow(
            icon: 'bookmark',
            label: a.saved.total > 0 ? 'Guardados · ${a.saved.total}' : 'Guardados',
            trailingChevron: true,
            onTap: () => context.push(Routes.saved),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: OptRow(
            icon: 'phone',
            label: a.phone == null ? 'Agregar celular (opcional)' : 'Celular de contacto ${a.phone}',
            trailingChevron: true,
            onTap: () => showPhoneSheet(context, ref),
          ),
        ),
        _box('Privacidad y cuenta', [
          OptRow(
              icon: 'shield',
              label: 'Aviso de privacidad',
              trailingChevron: true,
              onTap: () => showPrivacySheet(context)),
          const SizedBox(height: 8),
          OptRow(icon: 'info', label: 'Términos de uso', trailingChevron: true, onTap: () => showTermsSheet(context)),
          const SizedBox(height: 8),
          if (push.available) ...[
            OptRow(
              icon: 'bell',
              label: push.enabled ? 'Avisos en el teléfono · Activos' : 'Avisos en el teléfono · Apagados',
              selected: push.enabled,
              onTap: () async {
                final n = ref.read(pushProvider.notifier);
                if (push.enabled) {
                  await n.disable();
                  showNexoToast('Avisos desactivados');
                } else {
                  final ok = await n.enable();
                  showNexoToast(
                      ok ? 'Avisos activados' : 'Activa las notificaciones de Nexo en los ajustes del teléfono.');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
          OptRow(icon: 'out', label: _leaving ? 'Cerrando sesión…' : 'Cerrar sesión', onTap: _logout),
          const SizedBox(height: 8),
          OptRow(icon: 'close', label: 'Eliminar mi cuenta', danger: true, onTap: () => _delete(a)),
        ]),
      ],
    );
  }

  Future<void> _viewMe(AccountScreen account) => context.push<void>(Routes.myProfile, extra: account);

  Future<void> _delete(AccountScreen a) async {
    if (a.pendingDeletion) {
      showNexoToast('Tu cuenta ya está en proceso de eliminación.');
      return;
    }
    await showNexoSheet<void>(context, builder: (_) => const _DeleteSheet());
  }
}

Future<void> showAccountEditSheet(BuildContext context, AccountScreen account) =>
    showNexoSheet<void>(context, builder: (_) => _EditMeSheet(name: account.name, photo: account.photoUrl));

class _EditMeSheet extends ConsumerStatefulWidget {
  const _EditMeSheet({required this.name, this.photo});
  final String name;
  final String? photo;
  @override
  ConsumerState<_EditMeSheet> createState() => _EditMeSheetState();
}

class _EditMeSheetState extends ConsumerState<_EditMeSheet> {
  late final _name = TextEditingController(text: widget.name);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('Tu cuenta', subtitle: 'Tu nombre y tu foto se muestran cuando publicas o escribes.'),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showNexoToast(
            'Fotos de perfil: próximamente. Estamos preparando la carga y revisión de imágenes.',
          ),
          child: Row(children: [
            NexoAvatar(name: widget.name, url: widget.photo, size: 72),
            const SizedBox(width: 14),
            Text(widget.photo == null ? 'Agregar foto' : 'Cambiar foto',
                style: NexoText.body(15, weight: FontWeight.w700, color: NexoColors.brand)),
          ]),
        ),
        const SizedBox(height: 12),
        NexoField(label: 'Tu nombre', controller: _name, maxLength: 80, capitalization: TextCapitalization.words),
        const SizedBox(height: 12),
        NexoButton(
          label: 'Guardar',
          loading: _busy,
          onPressed: () async {
            setState(() => _busy = true);
            final nav = Navigator.of(context);
            try {
              await ref.read(apiProvider).updateMe(name: _name.text.trim());
              await ref.read(sessionProvider.notifier).setName(_name.text.trim());
              ref.invalidate(accountProvider);
              nav.pop();
              showNexoToast('Cuenta actualizada');
            } catch (e) {
              showNexoToast(apiErrorMessage(e));
              if (mounted) setState(() => _busy = false);
            }
          },
        ),
      ],
    );
  }
}

/// `delSheet` → `POST /v1/identity/me/deletion`.
class _DeleteSheet extends ConsumerStatefulWidget {
  const _DeleteSheet();
  @override
  ConsumerState<_DeleteSheet> createState() => _DeleteSheetState();
}

class _DeleteSheetState extends ConsumerState<_DeleteSheet> {
  final _pass = TextEditingController();
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pass.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('Eliminar mi cuenta',
            subtitle:
                'Tu perfil, publicaciones y guardados dejarán de verse. Tienes 30 días para arrepentirte; después se borra de forma permanente.'),
        if (Env.landingPage(LegalPages.deleteAccount) != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => openLanding(LegalPages.deleteAccount),
              child: Text('Qué datos se borran y cuáles se conservan',
                  style: NexoText.body(13.5, weight: FontWeight.w700, color: NexoColors.brand)),
            ),
          ),
        NexoPasswordField(label: 'Tu contraseña', controller: _pass, textInputAction: TextInputAction.next),
        const SizedBox(height: 12),
        TextField(
          controller: _reason,
          maxLength: 300,
          maxLines: 2,
          style: NexoText.body(15),
          decoration: nexoInputDecoration(hint: '¿Por qué te vas? (opcional)'),
        ),
        if (_error != null) NexoError(_error!),
        const SizedBox(height: 8),
        NexoButton(
          label: 'Eliminar mi cuenta',
          variant: NexoButtonVariant.danger,
          loading: _busy,
          onPressed: () async {
            if (_pass.text.isEmpty) {
              setState(() => _error = 'Escribe tu contraseña para confirmar.');
              return;
            }
            setState(() {
              _busy = true;
              _error = null;
            });
            final nav = Navigator.of(context);
            try {
              final msg = await ref.read(apiProvider).requestDeletion(
                  password: _pass.text, reason: _reason.text.trim().isEmpty ? null : _reason.text.trim());
              nav.pop();
              await ref.read(sessionProvider.notifier).signOutLocal();
              showNexoToast(msg);
            } catch (e) {
              if (mounted) {
                setState(() {
                  _busy = false;
                  _error = apiErrorMessage(e);
                });
              }
            }
          },
        ),
        const SizedBox(height: 8),
        NexoButton(label: 'Mejor no', variant: NexoButtonVariant.ghost, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
