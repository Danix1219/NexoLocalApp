import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/env.dart';

import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/widgets/nexo_button.dart';
import '../../../core/widgets/nexo_sheet.dart';
import '../../../core/widgets/toast.dart';

/// Texto de ejemplo de la maqueta (`privacySheet` / `termsSheet`), adaptado a
/// correo. La versión final la revisa asesoría legal y vive en la landing.
/// Páginas legales de la landing (requisito 16/17): aviso de privacidad,
/// términos y cómo eliminar la cuenta. La landing debe publicarlas en estas
/// rutas; se abren en el navegador.
class LegalPages {
  LegalPages._();
  static const privacy = 'privacidad';
  static const terms = 'terminos';
  static const deleteAccount = 'eliminar-cuenta';
}

/// Abre una página de la landing. Devuelve false si no está configurada.
Future<bool> openLanding(String page) async {
  final url = Env.landingPage(page);
  if (url == null) return false;
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok) showNexoToast('No se pudo abrir la página.');
  return ok;
}

Future<void> showPrivacySheet(BuildContext context) => _legal(
      context,
      'Aviso de privacidad',
      page: LegalPages.privacy,
      [
        ('Qué datos usamos',
            'Tu correo, tu nombre, tu ubicación (zona), lo que publicas y las fotos que subes. Si ofreces servicios, también los datos de tu perfil.'),
        ('Para qué los usamos',
            'Para conectarte con prestadores o con personas que buscan un servicio, mostrar resultados cercanos, mantener la seguridad de la comunidad y moderar contenido.'),
        ('Tu ubicación',
            'Usamos el punto que marcas para calcular distancias. Los demás usuarios ven solo la zona aproximada, nunca el punto exacto.'),
        ('Tu correo y tu número',
            'No se muestran en tu perfil. Tu número solo lo ve la otra persona si tú lo compartes para una llamada.'),
        ('Avisos y datos en tu teléfono',
            'Si activas los avisos guardamos un identificador de tu teléfono para enviarlos; se quita al desactivarlos o al cerrar sesión. Lo último que viste se guarda en tu teléfono para mostrarlo sin señal y se borra al cerrar sesión.'),
        ('Asistente y fotos',
            'La sugerencia de categoría por foto se calcula en tu teléfono. El asistente de redacción recibe solo el texto que escribiste, sin teléfonos, correos ni direcciones, y no publica nada por ti.'),
        ('Lo que no hacemos',
            'No cobramos comisiones, no vendemos tus datos y no compartimos tu información con terceros con fines de publicidad.'),
        ('Tus derechos',
            'Puedes acceder a tus datos, corregirlos, oponerte a su uso o eliminarlos. Para eliminar tu cuenta entra a Cuenta, «Privacidad y cuenta».'),
        ('Conservación',
            'Al eliminar tu cuenta se borran tu perfil, publicaciones, solicitudes y datos de contacto.'),
      ],
    );

Future<void> showTermsSheet(BuildContext context) => _legal(
      context,
      'Términos de uso',
      page: LegalPages.terms,
      [
        ('Qué es Nexo Local',
            'Una red que conecta a personas que buscan un servicio con quienes lo ofrecen. No intervenimos en el trato, el precio ni el pago.'),
        ('Tu responsabilidad',
            'La información de tu perfil o de tus publicaciones debe ser verdadera. El trato se cierra entre ambas partes.'),
        ('Contenido',
            'No se permite contenido ofensivo, engañoso o que muestre datos de terceros. Las publicaciones pueden ser reportadas y revisadas por moderación.'),
        ('Cuentas',
            'Puedes cerrar sesión o eliminar tu cuenta en cualquier momento. Podemos suspender cuentas que incumplan estas reglas.'),
      ],
    );

Future<void> _legal(BuildContext context, String title, List<(String, String)> parts, {String? page}) {
  final full = page == null ? null : Env.landingPage(page);
  return showNexoSheet<void>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title,
            subtitle: full == null
                ? 'Resumen. La versión completa se publica en nuestra página.'
                : 'Resumen. La versión completa y vigente está en nuestra página.'),
        for (final (h, p) in parts) ...[
          const SizedBox(height: 10),
          Text(h, style: NexoText.display(14, letterSpacing: 0)),
          const SizedBox(height: 4),
          Text(p, style: NexoText.body(14, color: NexoColors.muted, height: 1.45)),
        ],
        const SizedBox(height: 16),
        if (full != null) ...[
          NexoButton(
            label: 'Ver versión completa',
            variant: NexoButtonVariant.line,
            onPressed: () => openLanding(page!),
          ),
          const SizedBox(height: 8),
        ],
        NexoButton(label: 'Entendido', onPressed: () => Navigator.of(ctx).pop()),
      ],
    ),
  );
}
