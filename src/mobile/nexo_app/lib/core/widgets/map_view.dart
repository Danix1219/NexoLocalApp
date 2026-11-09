import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../data/models.dart';
import 'nexo_icon.dart';

/// Mosaicos de la maqueta (ArcGIS World Street Map, el que usa en file://).
const kTileUrl = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';

LatLng ll(GeoPoint p) => LatLng(p.lat, p.lng);
GeoPoint gp(LatLng p) => GeoPoint(p.latitude, p.longitude);

/// Zoom que deja ver el radio completo en un mapa de ~360 px.
double zoomForRadius(num km) => km <= 0 ? 15.5 : (14.5 - math.log(km) / math.ln2).clamp(9.0, 16.0).toDouble();

TileLayer nexoTiles() => TileLayer(urlTemplate: kTileUrl, userAgentPackageName: 'mx.nexolocal.nexo_app');

/// Alfiler de la maqueta: gota ámbar con borde blanco.
class MapPin extends StatelessWidget {
  const MapPin({super.key, this.size = 38, this.color = NexoColors.accent});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      NexoIcon('pin', size: size, color: Colors.white, fillColor: color, strokeWidth: 1.6);
}

/// `miniMap`: mapa pequeño de solo lectura con radio opcional y un botón.
class MiniMap extends StatelessWidget {
  const MiniMap({
    super.key,
    required this.point,
    this.radiusKm = 0,
    this.label,
    this.actionLabel,
    this.onAction,
    this.height = 150,
    this.approximate = false,
  });

  final GeoPoint point;
  final num radiusKm;
  final String? label;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double height;

  /// Zona aproximada (sin alfiler exacto): se dibuja un círculo de ~600 m.
  final bool approximate;

  @override
  Widget build(BuildContext context) {
    final center = ll(point);
    return Semantics(
      label: 'Mapa${label == null ? '' : ': $label'}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: approximate ? 14.2 : zoomForRadius(radiusKm),
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      nexoTiles(),
                      if (radiusKm > 0 || approximate)
                        CircleLayer(circles: [
                          CircleMarker(
                            point: center,
                            radius: approximate ? 600 : radiusKm * 1000.0,
                            useRadiusInMeter: true,
                            color: NexoColors.brand.withValues(alpha: .14),
                            borderColor: NexoColors.brand,
                            borderStrokeWidth: 2,
                          ),
                        ]),
                      if (!approximate)
                        MarkerLayer(markers: [
                          Marker(
                              point: center,
                              width: 38,
                              height: 38,
                              alignment: Alignment.topCenter,
                              child: const MapPin()),
                        ]),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: NexoColors.line, width: 1.5),
                  ),
                ),
              ),
              if (label != null || actionLabel != null)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Row(
                    children: [
                      if (label != null)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                            decoration: BoxDecoration(
                              color: NexoColors.surface,
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: const [
                                BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2))
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const NexoIcon('pin', size: 15, color: NexoColors.brand),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(label!,
                                      overflow: TextOverflow.ellipsis,
                                      style: NexoText.body(13, weight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (actionLabel != null && onAction != null)
                        Material(
                          color: NexoColors.brand,
                          borderRadius: BorderRadius.circular(99),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(99),
                            onTap: onAction,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                              child: Text(actionLabel!,
                                  style: NexoText.body(13, weight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mapa con puntos (prestadores o solicitudes) y la zona de búsqueda.
class PointsMap extends StatelessWidget {
  const PointsMap(
      {super.key,
      required this.center,
      required this.radiusKm,
      required this.points,
      this.onTapPoint,
      this.height = 260});
  final GeoPoint center;
  final num radiusKm;
  final List<MapPoint> points;
  final ValueChanged<MapPoint>? onTapPoint;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: ll(center),
            initialZoom: zoomForRadius(radiusKm),
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            nexoTiles(),
            CircleLayer(circles: [
              CircleMarker(
                point: ll(center),
                radius: radiusKm * 1000.0,
                useRadiusInMeter: true,
                color: NexoColors.brand.withValues(alpha: .08),
                borderColor: NexoColors.brand.withValues(alpha: .6),
                borderStrokeWidth: 1.5,
              ),
            ]),
            MarkerLayer(markers: [
              for (final p in points)
                Marker(
                  point: ll(p.point),
                  width: 34,
                  height: 34,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: onTapPoint == null ? null : () => onTapPoint!(p),
                    child: MapPin(
                      size: 34,
                      color: p.state == 'open' || p.state == 'today'
                          ? NexoColors.accent
                          : p.state == 'closed'
                              ? NexoColors.muted
                              : NexoColors.brand,
                    ),
                  ),
                ),
              Marker(
                point: ll(center),
                width: 18,
                height: 18,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B72D1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 6)],
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
