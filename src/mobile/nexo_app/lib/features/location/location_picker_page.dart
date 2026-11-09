import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../app/env.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/map_view.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../data/fake/fake_nexo_api.dart';
import '../../data/models.dart';

class LocationPickerArgs {
  const LocationPickerArgs({
    this.title = '¿Dónde buscas el servicio?',
    this.subtitle,
    this.initial,
    this.radiusKm = 10,
    this.showRadius = true,
    this.button = 'Usar esta ubicación',
  });
  final String title;
  final String? subtitle;
  final GeoPoint? initial;
  final int radiusKm;
  final bool showRadius;
  final String button;
}

class LocationPick {
  const LocationPick(this.point, this.radiusKm, this.source);
  final GeoPoint point;
  final int radiusKm;

  /// `map` | `gps`.
  final String source;
}

/// Selector de mapa (`pickerOpen`): mueve el mapa bajo el alfiler, elige el
/// radio y confirma. Tu punto exacto no se publica.
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, required this.args});
  final LocationPickerArgs args;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const _rads = [2, 5, 10, 20];
  final _map = MapController();
  late LatLng _center = ll(widget.args.initial ?? const GeoPoint(Env.defaultLat, Env.defaultLng));
  late int _rad = widget.args.radiusKm;
  String _source = 'map';
  bool _locating = false;

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        showNexoToast('Activa la ubicación del teléfono e inténtalo de nuevo.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        showNexoToast('Sin permiso de ubicación. Mueve el mapa a tu zona.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 15)),
      );
      final p = LatLng(pos.latitude, pos.longitude);
      _map.move(p, widget.args.showRadius ? zoomForRadius(_rad) : 16);
      setState(() {
        _center = p;
        _source = 'gps';
      });
    } catch (_) {
      showNexoToast('No pudimos obtener tu ubicación. Mueve el mapa a tu zona.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    final zone = FakeNexoApi.zoneOf(gp(_center));
    return NexoPage(
      background: NexoColors.surface,
      child: Column(
        children: [
          SubBar(a.title),
          if (a.subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(a.subtitle!, style: NexoText.body(14, color: NexoColors.muted, height: 1.4)),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FlutterMap(
                        mapController: _map,
                        options: MapOptions(
                          initialCenter: _center,
                          initialZoom: a.showRadius ? zoomForRadius(_rad) : 16,
                          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                          onPositionChanged: (camera, hasGesture) {
                            if (hasGesture) {
                              setState(() {
                                _center = camera.center;
                                _source = 'map';
                              });
                            }
                          },
                        ),
                        children: [
                          nexoTiles(),
                          if (a.showRadius)
                            CircleLayer(circles: [
                              CircleMarker(
                                point: _center,
                                radius: _rad * 1000.0,
                                useRadiusInMeter: true,
                                color: NexoColors.brand.withValues(alpha: .14),
                                borderColor: NexoColors.brand,
                                borderStrokeWidth: 2,
                              ),
                            ]),
                        ],
                      ),
                    ),
                    // El alfiler queda fijo al centro; se mueve el mapa.
                    const IgnorePointer(
                      child: Align(
                        alignment: Alignment.center,
                        child: Padding(padding: EdgeInsets.only(bottom: 44), child: MapPin(size: 44)),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Material(
                        color: NexoColors.surface,
                        shape: const StadiumBorder(),
                        elevation: 3,
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: _locating ? null : _locate,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              if (_locating)
                                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              else
                                const NexoIcon('locate', size: 17, color: NexoColors.brand),
                              const SizedBox(width: 6),
                              Text('Usar mi ubicación',
                                  style: NexoText.body(13, weight: FontWeight.w700, color: NexoColors.brandDeep)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          color: NexoColors.surface,
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const NexoIcon('pin', size: 15, color: NexoColors.brand),
                          const SizedBox(width: 6),
                          Text(a.showRadius ? '$zone · hasta $_rad km' : zone,
                              style: NexoText.body(13, weight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (a.showRadius) ...[
                    Text('¿Hasta dónde?', style: NexoText.body(14, weight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    SegControl<int>(
                      small: true,
                      options: [for (final r in _rads) (r, '$r km')],
                      value: _rads.contains(_rad) ? _rad : 10,
                      onChanged: (r) {
                        setState(() => _rad = r);
                        _map.move(_center, zoomForRadius(r));
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(children: [
                    const NexoIcon('shield', size: 15, color: NexoColors.ok),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Tu punto exacto no se publica.', style: NexoText.body(12.5, color: NexoColors.muted)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  NexoButton(
                    label: a.button,
                    onPressed: () => Navigator.of(context).pop(LocationPick(gp(_center), _rad, _source)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
