import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../app/env.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/map_view.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_field.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';

class LocationPickerArgs {
  const LocationPickerArgs(
      {this.title = '¿Dónde buscas el servicio?',
      this.subtitle,
      this.initial,
      this.radiusKm = 10,
      this.showRadius = true,
      this.button = 'Usar esta ubicación'});
  final String title;
  final String? subtitle;
  final GeoPoint? initial;
  final int radiusKm;
  final bool showRadius;
  final String button;
}

class LocationPick {
  const LocationPick(this.point, this.radiusKm, this.source, {this.label, this.zoneLabel});
  final GeoPoint point;
  final int radiusKm;
  final String source;
  final String? label;
  final String? zoneLabel;
}

class LocationPickerPage extends ConsumerStatefulWidget {
  const LocationPickerPage({super.key, required this.args});
  final LocationPickerArgs args;
  @override
  ConsumerState<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends ConsumerState<LocationPickerPage> {
  final _map = MapController();
  final _query = TextEditingController();
  Timer? _reverseTimer;
  late LatLng _center = ll(widget.args.initial ?? const GeoPoint(Env.defaultLat, Env.defaultLng));
  late int _radius = widget.args.radiusKm;
  late bool _selected = widget.args.initial != null;
  String _source = 'map';
  GeoPlace? _place;
  List<GeoPlace> _results = [];
  String? _searchError;
  String? _reverseError;
  bool _searching = false;
  bool _locating = false;
  int _searchEpoch = 0;
  int _reverseEpoch = 0;
  String get _coordinates => '${_center.latitude.toStringAsFixed(4)}, ${_center.longitude.toStringAsFixed(4)}';
  @override
  void initState() {
    super.initState();
    if (_selected) WidgetsBinding.instance.addPostFrameCallback((_) => _reverse());
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    final epoch = ++_searchEpoch;
    if (query.length < 3) {
      setState(() {
        _searching = false;
        _results = [];
        _searchError = 'Escribe al menos tres caracteres.';
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _searchError = null;
      _results = [];
    });
    try {
      final places = await ref.read(apiProvider).searchPlaces(query, at: _selected ? gp(_center) : null);
      if (!mounted || epoch != _searchEpoch) return;
      setState(() {
        _results = places;
        if (places.isEmpty) {
          _searchError = 'No encontramos esa dirección. Prueba con la ciudad o elige un punto en el mapa.';
        }
      });
    } catch (_) {
      if (mounted && epoch == _searchEpoch) {
        setState(() => _searchError = 'No pudimos buscar direcciones. Inténtalo de nuevo o elige tu zona en el mapa.');
      }
    } finally {
      if (mounted && epoch == _searchEpoch) setState(() => _searching = false);
    }
  }

  Future<void> _reverse() async {
    final epoch = ++_reverseEpoch;
    final point = gp(_center);
    try {
      final place = await ref.read(apiProvider).reversePlace(point);
      if (!mounted || epoch != _reverseEpoch) return;
      setState(() {
        _place = place;
        _reverseError = place == null ? 'Sin nombre de zona disponible; se guardará el punto seleccionado.' : null;
      });
    } catch (_) {
      if (mounted && epoch == _reverseEpoch) {
        setState(() => _reverseError = 'No pudimos obtener el nombre de la zona; puedes confirmar el punto del mapa.');
      }
    }
  }

  void _pick(GeoPlace place) {
    _reverseTimer?.cancel();
    _reverseEpoch++;
    _map.move(ll(place.point), widget.args.showRadius ? zoomForRadius(_radius) : 16);
    setState(() {
      _center = ll(place.point);
      _place = place;
      _selected = true;
      _source = 'search';
      _results = [];
      _searchError = null;
      _reverseError = null;
    });
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        showNexoToast('Activa la ubicación del teléfono o elige tu zona en el mapa.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        showNexoToast('Sin permiso de ubicación. Puedes buscar una dirección o mover el mapa.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 15)));
      if (!mounted) return;
      final point = GeoPoint(position.latitude, position.longitude);
      if (!_inMexico(point)) {
        showNexoToast('Por ahora Nexo Local está disponible en México.');
        return;
      }
      _reverseTimer?.cancel();
      _reverseEpoch++;
      _map.move(ll(point), widget.args.showRadius ? zoomForRadius(_radius) : 16);
      setState(() {
        _center = ll(point);
        _selected = true;
        _source = 'gps';
        _place = null;
      });
      await _reverse();
    } catch (_) {
      showNexoToast('No pudimos obtener tu ubicación. Busca una dirección o mueve el mapa.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  bool _inMexico(GeoPoint p) =>
      p.lat.isFinite && p.lng.isFinite && p.lat >= 14 && p.lat <= 33 && p.lng >= -119 && p.lng <= -86;
  @override
  void dispose() {
    _reverseTimer?.cancel();
    _query.dispose();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NexoPage(
      background: NexoColors.surface,
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Column(children: [
              Center(
                  child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(color: NexoColors.line, borderRadius: BorderRadius.circular(9)))),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Text(widget.args.title, style: NexoText.display(20))),
                NexoIconButton(
                    icon: 'close',
                    label: 'Cerrar ubicación',
                    size: 36,
                    circle: true,
                    onTap: () => Navigator.of(context).pop())
              ]),
            ])),
        Expanded(
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (widget.args.subtitle != null) ...[
                    Text(widget.args.subtitle!, style: NexoText.body(14, color: NexoColors.muted)),
                    const SizedBox(height: 12)
                  ],
                  Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _query,
                            maxLength: 160,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _search(),
                            onChanged: (_) {
                              _searchEpoch++;
                              setState(() {
                                _searching = false;
                                _results = [];
                                _searchError = null;
                              });
                            },
                            style: NexoText.body(14),
                            decoration: nexoInputDecoration(hint: 'Calle, colonia o ciudad')
                                .copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)))),
                    const SizedBox(width: 8),
                    NexoButton(
                        label: 'Buscar',
                        small: true,
                        block: false,
                        loading: _searching,
                        onPressed: _searching ? null : _search)
                  ]),
                  if (_searchError != null)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(_searchError!, style: NexoText.body(13, color: NexoColors.muted))),
                  for (final result in _results)
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const NexoIcon('pin', color: NexoColors.brand),
                        title: Text(result.label, style: NexoText.body(14, weight: FontWeight.w700)),
                        onTap: () => _pick(result)),
                  const SizedBox(height: 12),
                  SizedBox(
                      height: 230,
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(children: [
                            FlutterMap(
                                mapController: _map,
                                options: MapOptions(
                                    initialCenter: _center,
                                    initialZoom: widget.args.showRadius ? zoomForRadius(_radius) : 16,
                                    interactionOptions:
                                        const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                                    onPositionChanged: (camera, gesture) {
                                      if (!gesture) return;
                                      _reverseTimer?.cancel();
                                      _reverseEpoch++;
                                      setState(() {
                                        _center = camera.center;
                                        _selected = true;
                                        _source = 'map';
                                        _place = null;
                                        _reverseError = null;
                                      });
                                      if (_inMexico(gp(_center))) {
                                        _reverseTimer = Timer(const Duration(milliseconds: 1200), _reverse);
                                      }
                                    }),
                                children: [
                                  nexoTiles(),
                                  if (widget.args.showRadius && _selected)
                                    CircleLayer(circles: [
                                      CircleMarker(
                                          point: _center,
                                          radius: _radius * 1000.0,
                                          useRadiusInMeter: true,
                                          color: NexoColors.brand.withValues(alpha: .12),
                                          borderColor: NexoColors.brand,
                                          borderStrokeWidth: 2)
                                    ])
                                ]),
                            const IgnorePointer(
                                child: Center(
                                    child: Padding(padding: EdgeInsets.only(bottom: 32), child: MapPin(size: 38)))),
                          ]))),
                  const SizedBox(height: 10),
                  NexoButton(
                      label: 'Usar mi ubicación',
                      icon: 'locate',
                      loading: _locating,
                      variant: NexoButtonVariant.ghost,
                      onPressed: _locating ? null : _locate),
                  const SizedBox(height: 12),
                  Text(
                      _selected
                          ? (_place?.label ?? _coordinates)
                          : 'Busca una dirección, usa tu GPS o mueve el mapa para elegir tu zona.',
                      style: NexoText.body(14, weight: FontWeight.w700)),
                  if (_reverseError != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_reverseError!, style: NexoText.body(12.5, color: NexoColors.muted))),
                  if (widget.args.showRadius) ...[
                    const SizedBox(height: 14),
                    Text('Buscar a menos de', style: NexoText.body(14, weight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SegControl<int>(
                        small: true,
                        options: const [(2, '2 km'), (5, '5 km'), (10, '10 km'), (20, '20 km')],
                        value: _radius,
                        onChanged: (radius) {
                          setState(() => _radius = radius);
                          _map.move(_center, zoomForRadius(radius));
                        })
                  ],
                  const SizedBox(height: 14),
                  Text(
                      'Tu punto exacto no se publica. La búsqueda de direcciones se procesa con Photon y datos de OpenStreetMap.',
                      style: NexoText.body(12, color: NexoColors.muted, height: 1.4)),
                  const SizedBox(height: 6),
                  Text('Mapa © Esri · OpenStreetMap | Direcciones © OpenStreetMap contributors · Photon',
                      style: NexoText.body(10.5, color: NexoColors.muted)),
                ]))),
        SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                child: NexoButton(
                    label: widget.args.button,
                    onPressed: !_selected
                        ? null
                        : () {
                            if (!_inMexico(gp(_center))) {
                              showNexoToast('Selecciona una ubicación dentro de México.');
                              return;
                            }
                            Navigator.of(context).pop(LocationPick(gp(_center), _radius, _source,
                                label: _place?.label, zoneLabel: _place?.zoneLabel));
                          }))),
      ]));
}
