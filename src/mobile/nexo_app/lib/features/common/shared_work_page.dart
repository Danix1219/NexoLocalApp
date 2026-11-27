import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import 'cards.dart';

final sharedWorkProvider = FutureProvider.family<Work, (String, String)>((ref, ids) async {
  final works = await ref.read(apiProvider).providerWorks(ids.$1);
  final found = works.where((work) => work.id == ids.$2).firstOrNull;
  if (found == null) throw StateError('La publicaci\u00f3n no est\u00e1 disponible o fue eliminada.');
  return found;
});

class SharedWorkPage extends ConsumerWidget {
  const SharedWorkPage({super.key, required this.providerId, required this.workId});
  final String providerId;
  final String workId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(sharedWorkProvider((providerId, workId)));
    return Scaffold(
      appBar: AppBar(title: const Text('Publicaci\u00f3n')),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Esta publicaci\u00f3n ya no est\u00e1 disponible.', textAlign: TextAlign.center),
              ),
              TextButton(
                onPressed: () => ref.invalidate(sharedWorkProvider((providerId, workId))),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (work) => SingleChildScrollView(child: WorkCard(work: work)),
      ),
    );
  }
}
