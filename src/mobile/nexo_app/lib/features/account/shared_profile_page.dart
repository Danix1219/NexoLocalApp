import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/photo_feedback.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';

final sharedProfileProvider = FutureProvider.autoDispose.family<Json, String>(
  (ref, id) => ref.watch(apiProvider).sharedProfile(id),
);

class SharedProfilePage extends ConsumerWidget {
  const SharedProfilePage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => NexoPage(
    child: Column(
      children: [
        const SubBar('Perfil'),
        Expanded(
          child: skeletonView(
            NexoSkeletonKind.providers,
            ref.watch(sharedProfileProvider(id)),
            (profile) {
              final name = profile['name']?.toString() ?? '';
              final photo = profile['photoUrl']?.toString();
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => showPhotoViewer(
                        context,
                        photo,
                        title: 'Foto de perfil',
                        circular: true,
                        name: name,
                        profileLink: 'nexolocal://profile/$id',
                      ),
                      child: NexoAvatar(name: name, url: photo, size: 120),
                    ),
                    const SizedBox(height: 16),
                    Text(name, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text('Solicitante de Nexo Local'),
                  ],
                ),
              );
            },
            onRetry: () => ref.invalidate(sharedProfileProvider(id)),
          ),
        ),
      ],
    ),
  );
}
