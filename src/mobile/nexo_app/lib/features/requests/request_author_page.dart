import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_navigation.dart';
import '../../core/widgets/ui.dart';
import '../../data/models.dart';
import '../common/carousel.dart';

/// Solo datos que el autor ya hizo públicos en esta solicitud.
class RequestAuthorPage extends StatelessWidget {
  const RequestAuthorPage({super.key, required this.request});
  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final name = request.clientName.isEmpty ? 'Persona de Nexo Local' : request.clientName;
    return NexoPage(
      background: NexoColors.surface,
      bottom: const NexoNavigation(current: 0),
      child: Column(children: [
        const SubBar('Perfil'),
        Expanded(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(colors: [Color(0xFFDCEDE7), Color(0xFFF8E9CF)]),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              NexoAvatar(name: name, url: request.clientPhoto, size: 80, border: true),
              const SizedBox(height: 12),
              Text(name, style: NexoText.display(23, weight: FontWeight.w800)),
              Text('Solicitante · ${request.zoneLabel}', style: NexoText.body(14, color: NexoColors.muted)),
              const SizedBox(height: 22),
              Text('Solicitud pública', style: NexoText.display(17, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: NexoColors.line),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(request.title, style: NexoText.display(16, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(request.description, style: NexoText.body(14)),
                  if (request.photos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: PhotoCarousel(
                        images: [for (final url in request.photos) Img(url)],
                        category: request.category,
                        aspect: 1,
                      ),
                    ),
                  ],
                ]),
              ),
            ]),
          ),
        ])),
      ]),
    );
  }
}
