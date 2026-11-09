import 'dart:async';
import 'dart:math' as math;

import '../../core/auth/auth_tokens.dart';
import '../../core/network/api_exception.dart';
import '../models.dart';
import '../nexo_api.dart';
import 'fake_seed.dart';

/// Lo que la API falsa necesita saber de la sesión actual.
class FakeContext {
  FakeContext({required this.name, required this.mode, required this.notify, this.simulateCounterpart = true});

  /// Nombre de la cuenta (lo da la sesión).
  final String Function() name;

  /// `client` | `provider`.
  final String Function() mode;

  /// Avisa a la app que algo cambió "del lado del servidor" (respuestas
  /// simuladas), para que refresque bandeja, pedidos y avisos.
  final void Function(String what) notify;

  /// Simular a la otra parte (interesarse, aceptar, responder). Constitución
  /// §4: el cliente no simula a la contraparte; solo se permite en debug o con
  /// API_MODE=fake (demostración), nunca en un release en modo auto.
  final bool simulateCounterpart;
}

class _FOrder {
  _FOrder({
    required this.id,
    required this.providerId,
    required this.clientName,
    required this.mine, // true: yo soy el cliente
    required this.cat,
    required this.desc,
    required this.attention,
    required this.zone,
    this.address,
    this.addressNote,
    this.location,
    required this.status,
    this.requestId,
    required this.ago,
    this.priceCents,
    this.includes,
  });
  final String id;
  final String providerId;
  final String clientName;
  final bool mine;
  final String cat;
  String desc;
  String attention;
  String zone;
  String? address;
  String? addressNote;
  GeoPoint? location;
  String status; // pending | accepted | rejected | cancelled | resolved
  final String? requestId;
  final String ago;
  int? priceCents;
  String? includes;
  int version = 1;
  int? myStars;
  final List<TimelineEvent> timeline = [];
}

class _FMsg {
  _FMsg(this.id, this.kind, this.text, this.mine, this.at, {this.imageUrl, this.systemType, this.orderId});
  final String id;
  final String kind;
  final String text;
  final bool mine;
  final DateTime at;
  final String? imageUrl;
  final String? systemType;
  final String? orderId;
}

class _FConv {
  _FConv(this.id, {required this.providerId, required this.clientName, required this.asClient, this.requestId});
  final String id;
  final String providerId;
  final String clientName;

  /// true: yo hablo como cliente con el prestador `providerId`.
  final bool asClient;
  final String? requestId;
  final List<_FMsg> msgs = [];
  int unread = 0;
  bool blocked = false;
  int replies = 0;
}

class _FNotif {
  _FNotif(this.id, this.title, this.body, this.deepLink, this.action, this.icon, this.ago);
  final String id;
  final String title;
  final String body;
  final String? deepLink;
  final String? action;
  final String icon;
  final String ago;
  bool read = false;
}

/// Respuestas con los datos de la maqueta, en memoria. Simula también lo que
/// haría la otra parte (un prestador que se interesa, que acepta el pedido o
/// que responde el chat) para poder recorrer todos los flujos.
class FakeNexoApi implements NexoApi {
  FakeNexoApi(this.ctx) {
    _seedClientDemo();
  }

  final FakeContext ctx;

  final _provs = seedProviders();
  final _works = seedWorks();
  final _reqs = seedRequests();
  final _exps = seedExps().toList();
  final _orders = <_FOrder>[];
  final _convs = <_FConv>[];
  final _notifs = <_FNotif>[];
  final _savedP = <String>{};
  final _savedW = <String>{};
  final _savedR = <String>{};
  final _myInterest = <String>{};

  FProv? _me; // mi perfil de prestador, cuando lo creo
  GeoPoint _loc = fakeZones['Centro']!;
  int _radius = 10;
  String? _phone;
  bool _phoneOk = false;
  String? _photoUrl;
  String? _nameOverride;
  bool _pendingDeletion = false;
  int _seq = 100;

  String _id(String p) => '$p${_seq++}';
  Future<void> _lag([int ms = 260]) => Future<void>.delayed(Duration(milliseconds: ms));
  String get _myName => _nameOverride ?? (ctx.name().isEmpty ? 'Tú' : ctx.name());

  // ------------------------------------------------------------------ util
  static double _dist(GeoPoint a, GeoPoint b) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(b.lat - a.lat), dLng = rad(b.lng - a.lng);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.lat)) * math.cos(rad(b.lat)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(h.toDouble()));
  }

  static String kmText(double d) =>
      d < 1 ? 'a ${(d * 1000 / 50).round() * 50} m' : 'a ~${d < 10 ? d.toStringAsFixed(1) : d.round()} km';

  static String zoneOf(GeoPoint p) {
    String best = 'Centro';
    var bd = double.infinity;
    fakeZones.forEach((k, v) {
      final d = _dist(p, v);
      if (d < bd) {
        bd = d;
        best = k;
      }
    });
    return bd > 6 ? 'Tu zona' : best;
  }

  bool _serves(FProv p, GeoPoint at) =>
      p.attention == 'shop' ? _dist(p.loc, at) <= 12 : _dist(p.loc, at) <= p.rad + 0.5;

  static const _days = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

  OpenStatus _status(FProv p) {
    if (p.schedule.every((d) => d == null)) return const OpenStatus(false, 'Horario no publicado');
    final now = DateTime.now();
    final today = now.weekday - 1;
    final mins = now.hour * 60 + now.minute;
    final t = p.schedule[today];
    if (t != null && mins >= t[0] * 60 && mins < t[1] * 60) {
      return OpenStatus(true, 'Abierto ahora · cierra a las ${t[1]}:00');
    }
    if (t != null && mins < t[0] * 60) return OpenStatus(false, 'Cerrado · abre hoy a las ${t[0]}:00');
    for (var i = 1; i <= 7; i++) {
      final d = (today + i) % 7;
      final s = p.schedule[d];
      if (s != null) {
        return OpenStatus(false, 'Cerrado · abre ${i == 1 ? 'mañana' : 'el ${_days[d]}'} a las ${s[0]}:00');
      }
    }
    return const OpenStatus(false, 'Cerrado');
  }

  String _attText(FProv p) =>
      p.attention == 'shop' ? 'En su local' : p.attention == 'both' ? 'Local y a domicilio' : 'Va a domicilio';

  String _upd(int d) => d == 0 ? 'Actualizado hoy' : d == 1 ? 'Actualizado ayer' : 'Actualizado hace $d días';

  Rating _rating(String pid) {
    final ex = _exps.where((e) => e.p == pid).toList();
    if (ex.isEmpty) return const Rating(0, 0);
    final avg = ex.fold<int>(0, (a, e) => a + e.stars) / ex.length;
    return Rating(double.parse(avg.toStringAsFixed(1)), ex.length);
  }

  FProv _prov(String id) {
    if (id == 'me' && _me != null) return _me!;
    return _provs.firstWhere((p) => p.id == id,
        orElse: () => throw const ApiException(code: 'provider.not_found', status: 404, detail: 'Este perfil ya no existe.'));
  }

  ProviderProfile _profile(FProv p, {GeoPoint? at}) {
    final d = _dist(p.loc, at ?? _loc);
    final st = _status(p);
    final priced = p.prices.where((x) => x.pesos != null).toList()
      ..sort((a, b) => a.pesos!.compareTo(b.pesos!));
    final min = priced.isEmpty ? null : priced.first;
    final badges = <ProviderBadge>[
      if (p.ok) const ProviderBadge('phoneVerified', 'Teléfono confirmado', level: 'verified'),
      if (p.isNew) const ProviderBadge('isNew', 'Perfil nuevo'),
      if (p.upd >= 7) const ProviderBadge('stale', 'Sin actualizar'),
    ];
    final visitMode = p.visit == null ? 'hidden' : p.visit == 0 ? 'free' : 'paid';
    return ProviderProfile(
      id: p.id,
      name: p.name,
      kind: p.kind,
      photoUrl: p.photoUrl,
      coverUrl: p.coverUrl,
      categories: p.cats,
      specialties: p.specs,
      bio: p.bio,
      owner: p.owner,
      activity: p.activity,
      experience: int.tryParse(p.exp.split(' ').first),
      crew: p.crew,
      attention: p.attention,
      attentionText: _attText(p),
      zoneLabel: p.zone,
      distanceKm: d,
      distanceText: kmText(d),
      radiusKm: p.rad,
      shopLocation: p.attention == 'home' ? null : p.loc,
      zonePoint: fakeZones[p.zone] ?? p.loc,
      status: st,
      days: [for (final s in p.schedule) s == null ? null : DayHours('${s[0]}:00', '${s[1]}:00')],
      urgent: p.urgent,
      visitMode: visitMode,
      visitText: visitMode == 'hidden'
          ? null
          : visitMode == 'free'
              ? 'Visita sin costo'
              : 'Visita ${formatMoney(p.visit! * 100)}',
      minPriceText: min == null ? null : 'Desde ${formatMoney(min.pesos! * 100)}',
      minPriceCents: min == null ? null : min.pesos! * 100,
      prices: [
        for (final x in p.prices)
          PriceItem(service: x.service, fromCents: x.pesos == null ? null : x.pesos! * 100, unit: x.pesos == null ? 'quote' : 'from', suffix: x.suffix)
      ],
      payment: p.pay,
      responseTime: p.resp,
      warranty: p.warr,
      invoice: p.inv,
      web: p.web,
      portfolio: const [],
      badges: badges,
      rating: _rating(p.id),
      recs: p.recs,
      jobs: p.jobs,
      channelChat: p.chat,
      channelCall: p.call,
      updatedText: _upd(p.upd),
      phoneVerified: p.ok,
      isNew: p.isNew,
    );
  }

  Work _work(FWork w) {
    final p = _prov(w.p);
    final d = _dist(p.loc, _loc);
    return Work(
      id: w.id,
      provider: ProviderMini(id: p.id, name: p.name, photoUrl: p.photoUrl, kind: p.kind, phoneVerified: p.ok),
      category: w.cat,
      title: w.title,
      text: w.text,
      images: [for (final u in w.images) Img(u)],
      zoneLabel: w.zone,
      distanceText: kmText(d),
      recs: w.recs,
      tag: w.tag,
      ago: w.ago,
      saved: _savedW.contains(w.id),
      recommended: w.recommended,
      canContact: w.p != 'me',
    );
  }

  static const _urgText = {'today': 'Hoy', 'week': 'Esta semana', 'noRush': 'Sin prisa'};

  ServiceRequest _request(FReq r) {
    final ints = r.interested.map(_prov).toList();
    final me = _me;
    final d = me == null ? _dist(r.loc, _loc) : _dist(r.loc, me.loc);
    final order = r.orderId == null ? null : _orders.where((o) => o.id == r.orderId).firstOrNull;
    String summary;
    if (r.closed && r.pick == null) {
      summary = 'Resuelta';
    } else if (order != null) {
      summary = {
            'pending': 'Pedido enviado · esperando respuesta',
            'accepted': 'Pedido aceptado',
            'resolved': order.myStars != null ? 'Servicio resuelto · lo calificaste' : 'Servicio resuelto · ¿cómo te fue?',
          }[order.status] ??
          'Pedido ${order.status}';
    } else if (ints.isEmpty) {
      final n = _provs.where((p) => p.cats.contains(r.cat) && _serves(p, r.loc)).length;
      summary = 'Aún sin interesados · $n ${n == 1 ? 'prestador atiende' : 'prestadores atienden'} tu zona';
    } else {
      summary = '${ints.length} ${ints.length == 1 ? 'interesado' : 'interesados'} · Compara y elige a quién pedirle';
    }
    return ServiceRequest(
      id: r.id,
      category: r.cat,
      title: r.title,
      description: r.text,
      urgency: r.urg,
      urgencyText: _urgText[r.urg] ?? 'Esta semana',
      zoneLabel: r.zone,
      distanceText: kmText(d),
      imageUrl: r.imageUrl,
      status: r.closed ? 'closed' : 'open',
      interestCount: ints.length,
      interestedPreview: [
        for (final p in ints.take(4)) ProviderMini(id: p.id, name: p.name, photoUrl: p.photoUrl, kind: p.kind, phoneVerified: p.ok)
      ],
      interestedMoreCount: math.max(0, ints.length - 4),
      summaryText: summary,
      picked: r.pick == null
          ? null
          : (() {
              final p = _prov(r.pick!);
              return ProviderMini(id: p.id, name: p.name, photoUrl: p.photoUrl, kind: p.kind, phoneVerified: p.ok);
            })(),
      ago: r.ago,
      iAmInterested: _myInterest.contains(r.id),
      inMyRadius: me == null ? true : _dist(r.loc, me.loc) <= me.rad + 0.5,
      matchesMyService: me != null && me.cats.contains(r.cat),
      clientName: r.mine ? _myName : r.user,
      saved: _savedR.contains(r.id),
      mine: r.mine,
      orderId: r.orderId,
    );
  }

  static const _statusText = {
    'pending': 'Pendiente',
    'accepted': 'Aceptado',
    'rejected': 'Rechazado',
    'cancelled': 'Cancelado',
    'resolved': 'Resuelto',
  };

  Order _order(_FOrder o) {
    final p = _prov(o.providerId);
    final role = o.mine ? 'client' : 'provider';
    final actions = <String>[
      'message',
      if (o.status == 'pending' && !o.mine) ...['accept', 'reject'],
      if (o.status == 'pending' && o.mine) 'cancel',
      if (o.status == 'accepted') 'cancel',
      if (o.status == 'accepted' && !o.mine) 'resolve',
      if (o.status != 'resolved' && o.status != 'cancelled' && o.status != 'rejected' && o.mine && o.attention != 'shop')
        'updateAddress',
      if (o.status == 'accepted' || o.mine) 'copyPhone',
    ];
    final statusText = o.status == 'pending'
        ? (o.mine ? 'Enviado · esperando respuesta' : 'Esperando tu respuesta')
        : _statusText[o.status] ?? o.status;
    final exact = o.mine || o.status != 'pending';
    final conv = _convs.where((c) => c.providerId == o.providerId && c.asClient == o.mine).firstOrNull;
    return Order(
      id: o.id,
      status: o.status,
      statusText: statusText,
      role: role,
      counterpart: o.mine
          ? Counterpart(id: p.id, displayName: p.name, photoUrl: p.photoUrl, kind: 'provider', canCopyPhone: true, providerId: p.id)
          : Counterpart(id: 'c-${o.id}', displayName: o.clientName, kind: 'client', canCopyPhone: o.status == 'accepted'),
      category: o.cat,
      description: o.desc,
      attention: o.attention,
      placeZone: o.attention == 'shop' ? p.zone : o.zone,
      address: exact ? o.address : null,
      addressNote: exact ? o.addressNote : null,
      location: o.attention == 'shop' ? p.loc : (exact ? o.location : fakeZones[o.zone]),
      agreedPrice: o.priceCents == null ? null : Money(o.priceCents!, includes: o.includes),
      requestId: o.requestId,
      requestTitle: o.requestId == null ? null : _reqs.where((r) => r.id == o.requestId).firstOrNull?.title,
      conversationId: conv?.id,
      ago: o.ago,
      allowedActions: actions,
      version: o.version,
      canReview: o.mine && o.status == 'resolved' && o.myStars == null,
      myReviewStars: o.myStars,
      timeline: List.of(o.timeline),
      providerId: p.id,
      mapExact: exact,
    );
  }

  _FOrder _ord(String id) => _orders.firstWhere((o) => o.id == id,
      orElse: () => throw const ApiException(code: 'order.not_found', status: 404, detail: 'Este pedido ya no existe.'));

  void _checkVersion(_FOrder o, Order seen) {
    if (o.version != seen.version) {
      throw const ApiException(
          code: 'order.version_conflict', status: 412, detail: 'El pedido cambió. Revisa su estado antes de continuar.');
    }
  }

  _FConv _convFor({required String providerId, required bool asClient, required String clientName, String? requestId}) {
    final c = _convs.where((c) => c.providerId == providerId && c.asClient == asClient && c.clientName == clientName).firstOrNull;
    if (c != null) return c;
    final n = _FConv(_id('cv'), providerId: providerId, clientName: clientName, asClient: asClient, requestId: requestId);
    _convs.insert(0, n);
    return n;
  }

  void _sys(_FOrder o, String text, String type) {
    final c = _convFor(providerId: o.providerId, asClient: o.mine, clientName: o.clientName, requestId: o.requestId);
    c.msgs.add(_FMsg(_id('m'), 'system', text, false, DateTime.now(), systemType: type, orderId: o.id));
  }

  void _notify(String title, String body, String? link, String? action, {String icon = 'bell'}) {
    _notifs.insert(0, _FNotif(_id('n'), title, body, link, action, icon, 'ahora'));
  }

  // ------------------------------------------------------------- semillas
  void _seedClientDemo() {
    final ma2 = _FOrder(
      id: 'ma2',
      providerId: 'p2',
      clientName: 'Tú',
      mine: true,
      cat: 'electricidad',
      desc: 'Cambiar el contacto de la cocina y revisar la línea.',
      attention: 'home',
      zone: 'Centro',
      address: 'Morelos 15, casa azul',
      location: const GeoPoint(20.0547, -99.3434),
      status: 'resolved',
      requestId: 'ra2',
      ago: 'hace 2 días',
      priceCents: 35000,
      includes: 'Incluye el contacto nuevo',
    )..version = 3;
    ma2.timeline.addAll(const [
      TimelineEvent('created', 'client', 'Le hiciste el pedido'),
      TimelineEvent('accepted', 'provider', 'Aceptó el pedido · \$350'),
      TimelineEvent('resolved', 'provider', 'Lo marcó como resuelto'),
    ]);
    _orders.add(ma2);

    final now = DateTime.now();
    final c1 = _convFor(providerId: 'p2', asClient: true, clientName: 'Tú', requestId: 'ra2');
    c1.msgs.addAll([
      _FMsg(_id('m'), 'text', 'Hola, vi tu solicitud del contacto. Puedo ir hoy a las 5.', false, now.subtract(const Duration(days: 3, hours: 2))),
      _FMsg(_id('m'), 'text', 'Perfecto, te espero. Es en Morelos 15.', true, now.subtract(const Duration(days: 3, hours: 1))),
      _FMsg(_id('m'), 'system', 'Electro Servicios Ruiz aceptó tu pedido · Precio acordado \$350', false,
          now.subtract(const Duration(days: 3)), systemType: 'orderAccepted', orderId: 'ma2'),
      _FMsg(_id('m'), 'system', 'Electro Servicios Ruiz marcó el servicio como resuelto', false,
          now.subtract(const Duration(days: 2)), systemType: 'orderResolved', orderId: 'ma2'),
      _FMsg(_id('m'), 'text', 'Listo, quedó el contacto nuevo. Cualquier cosa me avisas.', false, now.subtract(const Duration(days: 2))),
    ]);
    final c2 = _convFor(providerId: 'p1', asClient: true, clientName: 'Tú', requestId: 'ra1');
    c2.msgs.addAll([
      _FMsg(_id('m'), 'text', 'Hola, me interesa tu solicitud de la válvula del calentador. ¿Es de paso o de depósito?', false,
          now.subtract(const Duration(minutes: 35))),
    ]);
    c2.unread = 1;

    _notify('2 prestadores interesados', 'En «Fuga en la válvula del calentador». Ya puedes comparar y elegir.',
        'nexolocal://requests/ra1/interested', 'Ver y elegir', icon: 'thumb');
    _notify('¿Cómo te fue con Electro Servicios Ruiz?', 'Marcó tu servicio como resuelto. Califícalo para ayudar a otros.',
        'nexolocal://orders/ma2', 'Calificar', icon: 'star');
  }

  /// Al crear el perfil de prestador llega un pedido de ejemplo (`m1`).
  void _seedProviderDemo() {
    if (_orders.any((o) => o.id == 'm1')) return;
    final m1 = _FOrder(
      id: 'm1',
      providerId: 'me',
      clientName: 'Laura Gómez',
      mine: false,
      cat: _me!.cats.first,
      desc: 'Revisar la fuga del calentador y cambiar la válvula.',
      attention: 'home',
      zone: 'Centro',
      address: 'Hidalgo 24, portón negro',
      location: const GeoPoint(20.0561, -99.3392),
      status: 'pending',
      ago: 'hace 10 min',
    );
    m1.timeline.add(const TimelineEvent('created', 'client', 'Te hizo el pedido desde tu perfil'));
    _orders.add(m1);
    final c = _convFor(providerId: 'me', asClient: false, clientName: 'Laura Gómez');
    c.msgs.add(_FMsg(_id('m'), 'text', 'Hola, ¿podrías venir hoy en la tarde? Te hice el pedido.', false, DateTime.now()));
    c.unread = 1;
    _notify('Laura Gómez te hizo un pedido', 'Revisa los detalles y acéptalo o recházalo.', 'nexolocal://orders/m1', 'Ver pedido',
        icon: 'check');
  }

  // ================================================================ cuenta
  @override
  Future<AccountScreen> accountScreen() async {
    await _lag();
    final me = _me;
    final mp = me == null ? null : _myProviderSync();
    final todo = mp?.todo.where((t) => !t.done).toList() ?? const <TodoItem>[];
    return AccountScreen(
      name: _myName,
      photoUrl: _photoUrl,
      phone: _phone,
      phoneVerified: _phoneOk,
      status: _pendingDeletion ? 'pendingDeletion' : 'active',
      mode: ctx.mode(),
      hasProvider: me != null,
      providerId: me?.id,
      providerName: me?.name,
      completeness: mp?.completeness ?? 0,
      nextTodo: todo.isEmpty ? null : todo.first.label,
      requests: _reqs.where((r) => r.mine).length,
      orders: _orders.where((o) => o.mine).length,
      views: me?.views ?? 0,
      contactClicks: me?.clicks ?? 0,
      interestsGiven: _myInterest.length,
      ordersResolved: _orders.where((o) => !o.mine && o.status == 'resolved').length,
      providerRating: me == null ? const Rating(0, 0) : _rating('me'),
      saved: SavedCounts(provider: _savedP.length, work: _savedW.length, request: _savedR.length),
      zoneLabel: zoneOf(_loc),
      radiusKm: _radius,
    );
  }

  @override
  Future<void> updateMe({String? name, String? photoUploadId}) async {
    await _lag();
    if (name != null && name.trim().isNotEmpty) _nameOverride = name.trim();
    if (photoUploadId != null) _photoUrl = photoUploadId;
  }

  @override
  Future<AuthTokens?> switchMode(String mode) async {
    await _lag();
    if (mode == 'provider' && _me == null) {
      throw const ApiException(code: 'mode.provider_profile_required', status: 409, detail: 'Primero crea tu perfil de prestador.');
    }
    return null; // la sesión guarda el modo localmente
  }

  @override
  Future<String> requestDeletion({required String password, String? reason}) async {
    await _lag();
    if (password.length < 8) throw const ApiException(code: 'auth.invalid_credentials', status: 401);
    _pendingDeletion = true;
    return 'Tu cuenta se eliminará en 30 días. Si entras antes, puedes cancelarlo.';
  }

  @override
  Future<void> cancelDeletion() async {
    await _lag();
    _pendingDeletion = false;
  }

  @override
  Future<String> addPhone(String phone) async {
    await _lag();
    _phone = phone;
    _phoneOk = false;
    final d = phone.replaceAll(RegExp(r'\D'), '');
    return '••• ••• ${d.length >= 4 ? d.substring(d.length - 4) : d}';
  }

  @override
  Future<void> confirmPhone(String code) async {
    await _lag();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const ApiException(code: 'phone.code_invalid', status: 400, detail: 'El código no es correcto.');
    }
    _phoneOk = true;
    if (_me != null) _me!.ok = true;
  }

  // ======================================================= perfil prestador
  @override
  Future<ProviderProfile> provider(String id, {GeoPoint? at}) async {
    await _lag();
    final p = _prov(id);
    if (id != 'me') p.views++;
    return _profile(p, at: at);
  }

  MyProvider _myProviderSync() {
    final p = _me!;
    final todo = [
      TodoItem('photo', 'Foto de perfil', 7, p.photoUrl != null),
      TodoItem('hours', 'Horario de atención', 14, p.schedule.any((d) => d != null)),
      TodoItem('prices', 'Precios de referencia', 14, p.prices.isNotEmpty),
      TodoItem('terms', 'Pago, respuesta y garantía', 10, p.resp != null),
      TodoItem('works', 'Publica un trabajo', 14, _works.any((w) => w.p == 'me')),
      TodoItem('phone', 'Confirma tu teléfono', 10, p.ok),
      TodoItem('bio', 'Cuéntanos sobre ti', 7, p.bio.trim().length >= 30),
    ];
    final got = 24 + todo.where((t) => t.done).fold<int>(0, (a, t) => a + t.points);
    return MyProvider(
      profile: _profile(p),
      completeness: math.min(100, got),
      todo: todo,
      views: p.views,
      contactClicks: p.clicks,
      location: p.loc,
    );
  }

  @override
  Future<MyProvider?> myProvider() async {
    await _lag(150);
    return _me == null ? null : _myProviderSync();
  }

  @override
  Future<String> createProvider(ProviderDraft d, {required String idempotencyKey}) async {
    await _lag(500);
    if (_me != null) return 'me';
    final loc = d.location ?? fakeZones['Centro']!;
    _me = FProv(
      id: 'me',
      name: d.name.trim(),
      kind: d.kind,
      cats: d.categories.isEmpty ? ['otros'] : List.of(d.categories),
      specs: List.of(d.specialties),
      zone: zoneOf(loc),
      phone: _phone ?? '',
      ok: _phoneOk,
      upd: 0,
      jobs: 0,
      recs: 0,
      exp: d.experience == null ? 'Experiencia no indicada' : '${d.experience} años de experiencia',
      bio: d.bio,
      kw: d.specialties.join(' ').toLowerCase(),
      schedule: List<List<int>?>.filled(7, null),
      loc: loc,
      rad: d.attention == 'shop' ? 0 : d.radiusKm,
      attention: d.attention,
      owner: d.kind == 'business' ? d.owner : null,
      activity: d.activity.isEmpty ? null : d.activity,
      crew: d.crew,
      isNew: true,
    )
      ..photoUrl = d.photoUploadId
      ..coverUrl = d.coverUploadId
      ..call = false;
    _seedProviderDemo();
    return 'me';
  }

  @override
  Future<void> patchProvider(String section, Json body) async {
    await _lag();
    final p = _me;
    if (p == null) throw const ApiException(code: 'provider.not_found', status: 404);
    p.upd = 0;
    switch (section) {
      case 'basic':
        if (body['name'] is String) p.name = body['name'] as String;
        if (body['bio'] is String) p.bio = body['bio'] as String;
        if (body.containsKey('photoUploadId')) p.photoUrl = body['photoUploadId'] as String?;
        if (body.containsKey('coverUploadId')) p.coverUrl = body['coverUploadId'] as String?;
      case 'services':
        if (body['categories'] is List) p.cats = (body['categories'] as List).map((e) => '$e').toList();
        if (body['specialties'] is List) p.specs = (body['specialties'] as List).map((e) => '$e').toList();
      case 'zone':
        final l = body['location'];
        if (l is Map) {
          p.loc = GeoPoint.fromJson(Json.from(l));
          p.zone = zoneOf(p.loc);
        }
        if (body['radiusKm'] is num) p.rad = (body['radiusKm'] as num).toInt();
        if (body['attention'] is String) p.attention = body['attention'] as String;
      case 'hours':
        final s = body['schedule'];
        if (s is Map) {
          final days = s['days'];
          if (days is List) {
            p.schedule = [
              for (final d in days)
                d is Map ? [int.parse('${d['open']}'.split(':').first), int.parse('${d['close']}'.split(':').first)] : null
            ];
          }
          p.urgent = s['urgent'] == true;
        }
      case 'prices':
        final v = body['visit'];
        if (v is Map) {
          final mode = '${v['mode']}';
          p.visit = mode == 'hidden' ? null : mode == 'free' ? 0 : ((v['amountCents'] as num?)?.toInt() ?? 0) ~/ 100;
        }
        final pr = body['prices'];
        if (pr is List) {
          p.prices = [
            for (final x in pr.whereType<Map>())
              FPrice('${x['service']}', x['fromCents'] == null ? null : (x['fromCents'] as num).toInt() ~/ 100, suffix: '${x['suffix'] ?? ''}')
          ];
        }
      case 'terms':
        if (body['payment'] is List) {
          const names = {'cash': 'Efectivo', 'transfer': 'Transferencia', 'card': 'Tarjeta', 'deposit': 'Depósito', 'other': 'Otro'};
          p.pay = (body['payment'] as List).map((e) => names['$e'] ?? '$e').toList();
        }
        if (body['responseTime'] is String) {
          const names = {'sameDay': 'Mismo día', 'h24': 'Menos de 1 día', 'h48': 'Menos de 2 días', 'week': 'Esta semana'};
          p.resp = names[body['responseTime']] ?? '${body['responseTime']}';
        }
        if (body.containsKey('warranty')) p.warr = body['warranty'] as String?;
        if (body['invoice'] is bool) p.inv = body['invoice'] as bool;
        final ch = body['channels'];
        if (ch is Map) {
          p.chat = ch['chat'] != false;
          p.call = ch['call'] == true;
        }
    }
  }

  @override
  Future<CompareResult> compare(List<String> ids, {GeoPoint? at}) async {
    await _lag();
    final ps = ids.map(_prov).toList();
    final pf = ps.map((p) => _profile(p, at: at)).toList();
    int? bestMax(List<num> v) {
      if (v.length < 2 || v[0] == v[1]) return null;
      return v[0] > v[1] ? 0 : 1;
    }

    int? bestMin(List<num?> v) {
      if (v.length < 2 || v[0] == null || v[1] == null || v[0] == v[1]) return null;
      return v[0]! < v[1]! ? 0 : 1;
    }

    return CompareResult(
      [for (final p in pf) ProviderMini(id: p.id, name: p.name, photoUrl: p.photoUrl, kind: p.kind, phoneVerified: p.phoneVerified)],
      [
        CompareRow('attention', 'Atención', [for (final p in pf) p.attentionText], null),
        CompareRow('status', 'Ahora', [for (final p in pf) p.status.short], pf.where((p) => p.status.open).length == 1 ? pf.indexWhere((p) => p.status.open) : null),
        CompareRow('distance', 'Distancia', [for (final p in pf) p.distanceText], bestMin([for (final p in pf) p.distanceKm])),
        CompareRow('minPrice', 'Desde', [for (final p in pf) p.minPriceText ?? 'No publicó'], bestMin([for (final p in pf) p.minPriceCents])),
        CompareRow('visit', 'Visita', [for (final p in pf) p.visitText ?? 'No publicó'], null),
        CompareRow('rating', 'Calificación', [for (final p in pf) p.rating.count == 0 ? 'Sin calificaciones' : '★ ${p.rating.avg} (${p.rating.count})'],
            bestMax([for (final p in pf) p.rating.avg])),
        CompareRow('recs', 'Recomiendan', [for (final p in pf) '${p.recs}'], bestMax([for (final p in pf) p.recs])),
        CompareRow('response', 'Responde en', [for (final p in pf) p.responseTime ?? 'No publicó'], null),
        CompareRow('warranty', 'Garantía', [for (final p in pf) p.warranty ?? 'No publicó'], null),
        CompareRow('phone', 'Teléfono confirmado', [for (final p in pf) p.phoneVerified ? 'Sí' : 'No'], null),
        CompareRow('updated', 'Actualizado', [for (final p in pf) p.updatedText.replaceFirst('Actualizado ', '')], null),
      ],
    );
  }

  // ========================================================= descubrimiento
  @override
  Future<List<ServiceCategory>> categories() async {
    await _lag(120);
    return [
      for (final c in fakeCats)
        ServiceCategory(
          slug: c.id,
          name: c.name,
          icon: c.icon,
          c1: c.c1,
          c2: c.c2,
          specialties: [for (final s in c.specs) Specialty(s.toLowerCase().replaceAll(' ', '-'), s)],
          businessLabel: c.giro,
          tradeLabel: c.oficio,
        )
    ];
  }

  @override
  Future<FeedPage> feed({required GeoPoint at, String? cursor}) async {
    await _lag();
    final near = _works.where((w) {
      final p = _prov(w.p);
      return _dist(p.loc, at) <= math.max(p.rad, 3) + 6;
    }).toList();
    return FeedPage(zoneLabel: zoneOf(at), page: CursorPage(near.map(_work).toList()));
  }

  @override
  Future<MapNearby> mapNearby({required GeoPoint at, required int radiusKm, required String kind}) async {
    await _lag(150);
    if (kind == 'requests') {
      final rs = _reqs.where((r) => !r.mine && !r.closed && _dist(r.loc, at) <= radiusKm).toList();
      return MapNearby(
        points: [
          for (final r in rs)
            MapPoint(id: r.id, point: r.loc, state: r.urg, title: r.title, subtitle: '${fcat(r.cat).name} · ${_urgText[r.urg]}')
        ],
        summary: '${rs.length} ${rs.length == 1 ? 'solicitud' : 'solicitudes'} en tu radio',
      );
    }
    final ps = _provs.where((p) => _serves(p, at) || _dist(p.loc, at) <= radiusKm).toList();
    return MapNearby(
      points: [
        for (final p in ps)
          MapPoint(id: p.id, point: p.loc, state: _status(p).open ? 'open' : 'closed', title: p.name, subtitle: fcat(p.cats.first).name)
      ],
      summary: '${ps.length} ${ps.length == 1 ? 'prestador atiende' : 'prestadores atienden'} esta zona',
    );
  }

  static String norm(String s) {
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    var out = s.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out;
  }

  @override
  Future<SearchResult> searchProviders(SearchFilters f, {required GeoPoint at, required int radiusKm}) async {
    await _lag();
    final terms = norm(f.q.trim()).split(RegExp(r'\s+')).where((t) => t.length > 1).toList();
    bool matchQ(FProv p) {
      if (terms.isEmpty) return true;
      final hay = norm('${p.name} ${p.kw} ${p.specs.join(' ')} ${p.cats.map((c) => fcat(c).name).join(' ')} ${p.bio}');
      return terms.any(hay.contains);
    }

    var list = _provs.where((p) {
      if (f.cat != null && !p.cats.contains(f.cat)) return false;
      if (!matchQ(p)) return false;
      if (f.open && !_status(p).open) return false;
      if (f.free && p.visit != 0) return false;
      if (f.prices && p.prices.every((x) => x.pesos == null)) return false;
      if (f.urgent && !p.urgent) return false;
      if (f.attention == 'home' && p.attention == 'shop') return false;
      if (f.attention == 'shop' && p.attention == 'home') return false;
      return true;
    }).toList();
    final inZone = list.where((p) => _serves(p, at)).toList();
    final outOfZone = inZone.isEmpty && list.isNotEmpty;
    if (!f.expanded && !outOfZone) list = inZone;
    switch (f.sort) {
      case 'near':
        list.sort((a, b) => _dist(a.loc, at).compareTo(_dist(b.loc, at)));
      case 'recs':
        list.sort((a, b) => b.recs.compareTo(a.recs));
      default:
        list.sort((a, b) {
          final o = (b.ok ? 1 : 0) - (a.ok ? 1 : 0);
          return o != 0 ? o : a.upd.compareTo(b.upd);
        });
    }
    return SearchResult(
      items: list.map((p) => _profile(p, at: at)).toList(),
      total: list.length,
      outOfZone: outOfZone,
      notice: outOfZone ? 'Nadie con esos filtros atiende tu zona. Te mostramos los más cercanos.' : null,
    );
  }

  @override
  Future<List<Suggestion>> suggest(String q, {required GeoPoint at}) async {
    await _lag(80);
    final n = norm(q.trim());
    if (n.isEmpty) return const [];
    final out = <Suggestion>[];
    for (final c in fakeCats) {
      if (norm(c.name).contains(n)) out.add(Suggestion('category', c.id, c.name));
      for (final s in c.specs) {
        if (norm(s).contains(n)) out.add(Suggestion('specialty', c.id, s));
      }
    }
    for (final w in ['fuga', 'boiler', 'calentador', 'chapa', 'llave', 'closet', 'pintar', 'corto', 'apagador', 'poda', 'tinaco']) {
      if (w.startsWith(n)) out.add(Suggestion('term', '', w));
    }
    return out.take(8).toList();
  }

  @override
  Future<LocationResult> setLocation(GeoPoint p, {required int radiusKm, String source = 'map'}) async {
    await _lag();
    _loc = p;
    _radius = radiusKm;
    final n = _provs.where((x) => _serves(x, p)).length;
    return LocationResult(point: p, zoneLabel: zoneOf(p), radiusKm: radiusKm, summary: '$n prestadores atienden aquí');
  }

  // ============================================================== trabajos
  @override
  Future<Work> createWork({
    required String category,
    required String title,
    required String text,
    String? tag,
    GeoPoint? location,
    List<String> imageUploadIds = const [],
  }) async {
    await _lag(500);
    final me = _me;
    if (me == null) throw const ApiException(code: 'provider.required', status: 403, detail: 'Crea tu perfil de prestador para publicar.');
    final w = FWork(_id('w'), 'me', category, zoneOf(location ?? me.loc), title, text, 'ahora', 0, tag,
        imageUploadIds.isEmpty ? demoImgs(category, 1) : List.of(imageUploadIds));
    _works.insert(0, w);
    me.jobs++;
    me.upd = 0;
    return _work(w);
  }

  @override
  Future<void> deleteWork(String id) async {
    await _lag();
    _works.removeWhere((w) => w.id == id && w.p == 'me');
  }

  @override
  Future<Work> recommend(Work w, bool on) async {
    await _lag(120);
    final f = _works.firstWhere((x) => x.id == w.id);
    if (f.recommended != on) {
      f.recommended = on;
      f.recs += on ? 1 : -1;
    }
    return _work(f);
  }

  @override
  Future<List<Work>> providerWorks(String providerId) async {
    await _lag();
    return _works.where((w) => w.p == providerId).map(_work).toList();
  }

  // ========================================================== solicitudes
  @override
  Future<ServiceRequest> createRequest({
    required String category,
    required String title,
    required String description,
    required String urgency,
    required String contact,
    required GeoPoint location,
    String? imageUploadId,
    required String idempotencyKey,
  }) async {
    await _lag(500);
    final r = FReq(
      id: _id('r'),
      user: 'Tú',
      cat: category,
      zone: zoneOf(location),
      title: title,
      text: description,
      urg: urgency,
      ago: 'ahora',
      contact: contact,
      loc: location,
      mine: true,
      imageUrl: imageUploadId,
    );
    _reqs.insert(0, r);
    // Prototipo: hasta 3 prestadores de la zona se interesan unos segundos después.
    if (ctx.simulateCounterpart) {
      Timer(const Duration(seconds: 4), () {
      if (r.closed || r.pick != null) return;
      final c = _provs.where((p) => p.cats.contains(r.cat) && _serves(p, r.loc)).take(3).toList();
      if (c.isEmpty) return;
      for (final p in c) {
        if (!r.interested.contains(p.id)) r.interested.add(p.id);
      }
      _notify('${c.length} ${c.length == 1 ? 'prestador se interesó' : 'prestadores se interesaron'}', 'En «${r.title}».',
          'nexolocal://requests/${r.id}/interested', 'Ver y elegir', icon: 'thumb');
      ctx.notify('${c.length} ${c.length == 1 ? 'prestador se interesó' : 'prestadores se interesaron'} en tu solicitud');
    });
    }
    return _request(r);
  }

  @override
  Future<List<ServiceRequest>> myRequests() async {
    await _lag();
    return _reqs.where((r) => r.mine).map(_request).toList();
  }

  @override
  Future<List<ServiceRequest>> opportunities(OppFilters f) async {
    await _lag();
    final me = _me;
    final terms = norm(f.q.trim()).split(RegExp(r'\s+')).where((t) => t.length > 1).toList();
    var list = _reqs.where((r) {
      if (r.mine || r.closed) return false;
      if (f.cat != null && r.cat != f.cat) return false;
      if (f.today && r.urg != 'today') return false;
      if (me != null && f.inRadius && _dist(r.loc, me.loc) > me.rad + 0.5) return false;
      if (me != null && f.myServiceOnly && !me.cats.contains(r.cat)) return false;
      if (terms.isNotEmpty) {
        final hay = norm('${r.title} ${r.text} ${fcat(r.cat).name}');
        if (!terms.every(hay.contains)) return false;
      }
      return true;
    }).toList();
    const order = {'today': 0, 'week': 1, 'noRush': 2};
    int match(FReq r) => me != null && me.cats.contains(r.cat) ? 1 : 0;
    list.sort((a, b) {
      final m = match(b) - match(a);
      return m != 0 ? m : (order[a.urg] ?? 1).compareTo(order[b.urg] ?? 1);
    });
    return list.map(_request).toList();
  }

  @override
  Future<void> closeRequest(String id, {required String outcome, String? pickedProviderId}) async {
    await _lag();
    final r = _reqs.firstWhere((x) => x.id == id);
    r.closed = true;
    if (pickedProviderId != null) r.pick = pickedProviderId;
  }

  // ============================================================== interés
  @override
  Future<void> setInterest(String requestId, bool on, {String? note}) async {
    await _lag(200);
    if (_me == null) throw const ApiException(code: 'provider.required', status: 403, detail: 'Crea tu perfil de prestador.');
    final r = _reqs.firstWhere((x) => x.id == requestId);
    if (on) {
      _myInterest.add(requestId);
      if (!r.interested.contains('me')) r.interested.add('me');
    } else {
      _myInterest.remove(requestId);
      r.interested.remove('me');
    }
  }

  @override
  Future<InterestedPage> interested(String requestId, {String sort = 'rate'}) async {
    await _lag();
    final r = _reqs.firstWhere((x) => x.id == requestId,
        orElse: () => throw const ApiException(code: 'request.not_found', status: 404, detail: 'Esta solicitud ya no existe.'));
    final items = r.interested.where((id) => id != 'me').map((id) {
      final p = _prov(id);
      final o = _orders.where((o) => o.mine && o.providerId == id && o.requestId == requestId).firstOrNull;
      final conv = _convs.where((c) => c.asClient && c.providerId == id).firstOrNull;
      return Interested(
        provider: _profile(p, at: r.loc),
        note: id == 'p1' ? 'Puedo pasar hoy por la tarde' : null,
        conversationId: conv?.id,
        orderStatus: o?.status,
        canOrder: o == null && !r.closed,
      );
    }).toList();
    switch (sort) {
      case 'recs':
        items.sort((a, b) => b.provider.recs.compareTo(a.provider.recs));
      case 'open':
        items.sort((a, b) => (b.provider.status.open ? 1 : 0) - (a.provider.status.open ? 1 : 0));
      default:
        items.sort((a, b) {
          final c = b.provider.rating.avg.compareTo(a.provider.rating.avg);
          return c != 0 ? c : b.provider.recs.compareTo(a.provider.recs);
        });
    }
    return InterestedPage(requestId: r.id, title: r.title, status: r.closed ? 'closed' : 'open', items: items);
  }

  // ============================================================== pedidos
  @override
  Future<Order> createOrder({
    required String providerId,
    String? requestId,
    required String category,
    required String description,
    required String attention,
    String? address,
    String? addressNote,
    GeoPoint? location,
    required String idempotencyKey,
  }) async {
    await _lag(500);
    final dup = _orders.where((o) => o.mine && o.providerId == providerId && (o.status == 'pending' || o.status == 'accepted')).firstOrNull;
    if (dup != null) {
      throw const ApiException(code: 'order.already_active', status: 409, detail: 'Ya tienes un pedido activo con este prestador.');
    }
    final p = _prov(providerId);
    final o = _FOrder(
      id: _id('o'),
      providerId: providerId,
      clientName: 'Tú',
      mine: true,
      cat: category,
      desc: description,
      attention: attention,
      zone: zoneOf(location ?? _loc),
      address: address,
      addressNote: addressNote,
      location: location ?? _loc,
      status: 'pending',
      requestId: requestId,
      ago: 'ahora',
    );
    o.timeline.add(TimelineEvent('created', 'client', requestId == null ? 'Le hiciste el pedido desde su perfil' : 'Le hiciste el pedido desde tu solicitud'));
    _orders.insert(0, o);
    if (requestId != null) {
      final r = _reqs.where((x) => x.id == requestId).firstOrNull;
      r?.orderId = o.id;
    }
    _sys(o, 'Le enviaste un pedido a ${p.name}', 'orderCreated');
    // Prototipo: el prestador acepta unos segundos después.
    if (ctx.simulateCounterpart) {
      Timer(const Duration(seconds: 6), () {
      if (o.status != 'pending') return;
      o.status = 'accepted';
      o.version++;
      o.timeline.add(const TimelineEvent('accepted', 'provider', 'Aceptó el pedido'));
      final r = requestId == null ? null : _reqs.where((x) => x.id == requestId).firstOrNull;
      if (r != null) r.pick = providerId;
      _sys(o, '${p.name} aceptó tu pedido', 'orderAccepted');
      _notify('${p.name} aceptó tu pedido', 'Ya puedes ver los detalles y escribirle.', 'nexolocal://orders/${o.id}', 'Ver pedido',
          icon: 'check');
      ctx.notify('${p.name} aceptó tu pedido');
    });
    }
    return _order(o);
  }

  @override
  Future<OrdersPage> orders({required String role, String status = 'all'}) async {
    await _lag();
    final mine = role == 'client';
    final all = _orders.where((o) => o.mine == mine).toList();
    final filtered = status == 'all'
        ? all
        : status == 'active'
            ? all.where((o) => o.status == 'pending' || o.status == 'accepted').toList()
            : all.where((o) => o.status == status).toList();
    int n(String s) => all.where((o) => o.status == s).length;
    return OrdersPage(filtered.map(_order).toList(), pending: n('pending'), accepted: n('accepted'), resolved: n('resolved'));
  }

  @override
  Future<Order> order(String id) async {
    await _lag();
    return _order(_ord(id));
  }

  @override
  Future<Order> acceptOrder(Order seen, {int? amountCents, String? includes}) async {
    await _lag();
    final o = _ord(seen.id);
    _checkVersion(o, seen);
    o
      ..status = 'accepted'
      ..priceCents = amountCents
      ..includes = includes
      ..version += 1;
    o.timeline.add(TimelineEvent('accepted', 'provider', amountCents == null ? 'Aceptaste el pedido' : 'Aceptaste · ${formatMoney(amountCents)}'));
    _sys(o, 'Aceptaste el pedido${amountCents == null ? '' : ' · Precio acordado ${formatMoney(amountCents)}'}', 'orderAccepted');
    return _order(o);
  }

  @override
  Future<Order> rejectOrder(Order seen, {required String reason, String? note}) async {
    await _lag();
    final o = _ord(seen.id);
    _checkVersion(o, seen);
    o
      ..status = 'rejected'
      ..version += 1;
    o.timeline.add(const TimelineEvent('rejected', 'provider', 'Rechazaste el pedido'));
    _sys(o, 'Rechazaste el pedido', 'orderRejected');
    return _order(o);
  }

  @override
  Future<Order> cancelOrder(Order seen, {required String reason}) async {
    await _lag();
    final o = _ord(seen.id);
    _checkVersion(o, seen);
    o
      ..status = 'cancelled'
      ..version += 1;
    o.timeline.add(TimelineEvent('cancelled', o.mine ? 'client' : 'provider', 'Se canceló el pedido'));
    _sys(o, 'Se canceló el pedido', 'orderCancelled');
    if (o.requestId != null) {
      final r = _reqs.where((x) => x.id == o.requestId).firstOrNull;
      if (r != null && r.orderId == o.id) {
        r.orderId = null;
        r.pick = null;
      }
    }
    return _order(o);
  }

  @override
  Future<Order> resolveOrder(Order seen, {int? finalPriceCents, String? note}) async {
    await _lag();
    final o = _ord(seen.id);
    _checkVersion(o, seen);
    o
      ..status = 'resolved'
      ..priceCents = finalPriceCents ?? o.priceCents
      ..version += 1;
    o.timeline.add(const TimelineEvent('resolved', 'provider', 'Lo marcaste como resuelto'));
    _sys(o, 'El servicio se marcó como resuelto', 'orderResolved');
    if (!o.mine && _me != null) _me!.jobs++;
    return _order(o);
  }

  @override
  Future<Order> updateAddress(Order seen, {required String address, String? addressNote, GeoPoint? location}) async {
    await _lag();
    final o = _ord(seen.id);
    _checkVersion(o, seen);
    o
      ..address = address
      ..addressNote = addressNote
      ..location = location ?? o.location
      ..zone = zoneOf(location ?? o.location ?? _loc)
      ..version += 1;
    return _order(o);
  }

  // ============================================================= opiniones
  @override
  Future<void> review({required String orderId, required int stars, required String text, required bool recommend}) async {
    await _lag();
    final o = _ord(orderId);
    if (o.status != 'resolved') {
      throw const ApiException(code: 'review.order_not_resolved', status: 409, detail: 'Solo puedes calificar un servicio resuelto.');
    }
    if (o.myStars != null) throw const ApiException(code: 'review.already_exists', status: 409, detail: 'Ya calificaste este servicio.');
    o.myStars = stars;
    final p = _prov(o.providerId);
    if (recommend) p.recs++;
    _exps.insert(0, FExp(p.id, _myName.split(' ').first, text.isEmpty ? 'Sin comentario.' : text, recommend, stars, 'ahora'));
  }

  @override
  Future<ReviewsPage> reviews(String providerId) async {
    await _lag();
    final ex = _exps.where((e) => e.p == providerId).toList();
    final r = _rating(providerId);
    return ReviewsPage(
      avg: r.avg,
      count: r.count,
      recommendCount: ex.where((e) => e.rec).length,
      items: [
        for (var i = 0; i < ex.length; i++)
          Review(id: '$providerId-$i', stars: ex[i].stars, text: ex[i].text, recommend: ex[i].rec, author: ex[i].user, ago: ex[i].ago)
      ],
    );
  }

  // ============================================================== mensajes
  Counterpart _cp(_FConv c) {
    if (c.asClient) {
      final p = _prov(c.providerId);
      return Counterpart(id: p.id, displayName: p.name, photoUrl: p.photoUrl, kind: 'provider', providerId: p.id);
    }
    return Counterpart(id: 'c-${c.id}', displayName: c.clientName, kind: 'client');
  }

  ActiveOrder? _activeOrder(_FConv c) {
    final o = _orders
        .where((o) => o.providerId == c.providerId && o.mine == c.asClient && o.clientName == (c.asClient ? 'Tú' : c.clientName))
        .firstOrNull;
    if (o == null) return null;
    return ActiveOrder(o.id, o.status, _order(o).statusText);
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'ahora';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    if (d.inDays == 1) return 'ayer';
    return 'hace ${d.inDays} días';
  }

  @override
  Future<(List<Conversation>, int)> conversations({required String role, String filter = 'all'}) async {
    await _lag(180);
    final asClient = role == 'client';
    final list = _convs.where((c) => c.asClient == asClient).toList()
      ..sort((a, b) {
        final ta = a.msgs.isEmpty ? DateTime(2000) : a.msgs.last.at;
        final tb = b.msgs.isEmpty ? DateTime(2000) : b.msgs.last.at;
        return tb.compareTo(ta);
      });
    final total = list.where((c) => !c.blocked).fold<int>(0, (a, c) => a + c.unread);
    final shown = filter == 'unread' ? list.where((c) => c.unread > 0 && !c.blocked).toList() : list;
    return (
      [
        for (final c in shown)
          Conversation(
            id: c.id,
            counterpart: _cp(c),
            lastPreview: c.msgs.isEmpty
                ? 'Nueva conversación'
                : c.msgs.last.kind == 'system'
                    ? c.msgs.last.text
                    : '${c.msgs.last.mine ? 'Tú: ' : ''}${c.msgs.last.kind == 'image' ? 'Foto' : c.msgs.last.text}',
            ago: c.msgs.isEmpty ? '' : _ago(c.msgs.last.at),
            unread: c.unread,
            requestId: c.requestId,
            activeOrder: _activeOrder(c),
            blocked: c.blocked,
            blockedByMe: c.blocked,
          )
      ],
      total
    );
  }

  @override
  Future<String> openConversation({String? providerId, String? requestId}) async {
    await _lag(200);
    if (providerId != null) {
      final p = _prov(providerId);
      p.clicks++;
      return _convFor(providerId: providerId, asClient: true, clientName: 'Tú', requestId: requestId).id;
    }
    // El prestador le escribe al cliente de una solicitud.
    final r = _reqs.firstWhere((x) => x.id == requestId);
    if (_me == null) throw const ApiException(code: 'provider.required', status: 403);
    return _convFor(providerId: 'me', asClient: false, clientName: r.user, requestId: r.id).id;
  }

  _FConv _conv(String id) => _convs.firstWhere((c) => c.id == id,
      orElse: () => throw const ApiException(code: 'conversation.not_found', status: 404, detail: 'Esta conversación ya no existe.'));

  @override
  Future<ChatThread> messages(String conversationId, {String? before}) async {
    await _lag(120);
    final c = _conv(conversationId);
    return ChatThread(
      id: c.id,
      counterpart: _cp(c),
      messages: [
        for (final m in c.msgs)
          Message(
            id: m.id,
            kind: m.kind,
            text: m.text,
            imageUrl: m.imageUrl,
            mine: m.mine,
            createdAt: m.at,
            readAt: m.mine ? m.at.add(const Duration(minutes: 1)) : null,
            systemType: m.systemType,
            orderId: m.orderId,
          )
      ],
      activeOrder: _activeOrder(c),
      blocked: c.blocked,
      canSend: !c.blocked,
      quickReplies: c.asClient
          ? const ['¿Cuándo podrías venir?', '¿Cuánto costaría?', '¿Atiendes en mi zona?']
          : const ['Hola, ¿me compartes una foto?', 'Puedo ir hoy', '¿Cuál es tu dirección?'],
    );
  }

  @override
  Future<Message> sendMessage(String conversationId, {String? text, String? imageUploadId}) async {
    await _lag(150);
    final c = _conv(conversationId);
    if (c.blocked) throw const ApiException(code: 'conversation.blocked', status: 403, detail: 'Desbloquea la conversación para escribir.');
    final m = _FMsg(_id('m'), imageUploadId != null ? 'image' : 'text', text ?? '', true, DateTime.now(), imageUrl: imageUploadId);
    c.msgs.add(m);
    if (ctx.simulateCounterpart && c.replies < fakeReplies.length) {
      final reply = c.asClient ? fakeReplies[c.replies] : 'Gracias, aquí te espero.';
      c.replies++;
      Timer(const Duration(seconds: 3), () {
        if (c.blocked) return;
        c.msgs.add(_FMsg(_id('m'), 'text', reply, false, DateTime.now()));
        c.unread++;
        ctx.notify('chat');
      });
    }
    return Message(id: m.id, kind: m.kind, text: m.text, imageUrl: m.imageUrl, mine: true, createdAt: m.at);
  }

  @override
  Future<void> markRead(String conversationId, String upToMessageId) async {
    final c = _conv(conversationId);
    c.unread = 0;
  }

  @override
  Future<bool> block(String conversationId, bool blocked, {bool alsoReport = false}) async {
    await _lag();
    final c = _conv(conversationId);
    c.blocked = blocked;
    return blocked;
  }

  // ============================================================= guardados
  SavedCounts get _counts => SavedCounts(provider: _savedP.length, work: _savedW.length, request: _savedR.length);

  @override
  Future<(List<SavedItem>, SavedCounts)> saved({String? kind}) async {
    await _lag();
    final items = <SavedItem>[
      if (kind == null || kind == 'provider')
        for (final id in _savedP) SavedItem(kind: 'provider', targetId: id, provider: _profile(_prov(id))),
      if (kind == null || kind == 'work')
        for (final id in _savedW)
          if (_works.any((w) => w.id == id))
            SavedItem(kind: 'work', targetId: id, work: _work(_works.firstWhere((w) => w.id == id)))
          else
            SavedItem(kind: 'work', targetId: id, available: false),
      if (kind == null || kind == 'request')
        for (final id in _savedR)
          SavedItem(kind: 'request', targetId: id, request: _request(_reqs.firstWhere((r) => r.id == id))),
    ];
    return (items, _counts);
  }

  @override
  Future<SavedCounts> setSaved(String kind, String id, bool on) async {
    await _lag(120);
    final s = kind == 'provider'
        ? _savedP
        : kind == 'work'
            ? _savedW
            : _savedR;
    on ? s.add(id) : s.remove(id);
    return _counts;
  }

  // ===================================================== contacto/reportes
  @override
  Future<PhoneReveal> revealPhone({required String targetId, required String targetType, required String context}) async {
    await _lag();
    if (targetType == 'provider') {
      final p = _prov(targetId);
      p.clicks++;
      return PhoneReveal(p.phone, p.name);
    }
    if (targetType == 'order') {
      final o = _ord(targetId);
      return o.mine ? PhoneReveal(_prov(o.providerId).phone, _prov(o.providerId).name) : PhoneReveal('771 555 0221', o.clientName);
    }
    return const PhoneReveal('771 555 0200', '');
  }

  @override
  Future<String> report({required String targetType, required String targetId, required String category, required String reason}) async {
    await _lag(400);
    return 'Recibimos tu reporte. Lo revisará una persona del equipo.';
  }

  // ======================================================== notificaciones
  @override
  Future<(List<NotificationItem>, int)> notifications({String filter = 'all'}) async {
    await _lag(150);
    final list = filter == 'unread' ? _notifs.where((n) => !n.read).toList() : _notifs;
    return (
      [
        for (final n in list)
          NotificationItem(
              id: n.id, title: n.title, body: n.body, deepLink: n.deepLink, actionLabel: n.action, icon: n.icon, read: n.read, ago: n.ago)
      ],
      _notifs.where((n) => !n.read).length
    );
  }

  @override
  Future<void> markNotificationsRead(List<String> ids) async {
    for (final n in _notifs) {
      if (ids.contains(n.id)) n.read = true;
    }
  }

  // =============================================================== imágenes
  @override
  Future<String> upload(PickedImage img, {required String purpose}) async {
    await _lag(400);
    // En modo de prueba la "URL" es el archivo local; NexoImage lo muestra.
    return 'file://${img.path}';
  }

  // ============================================ asistente (solo de prueba)
  /// La maqueta NO es IA: arma una plantilla para probar la pantalla. Solo
  /// existe en depuración o con API_MODE=fake; en un release el asistente
  /// caído se informa y la persona escribe a mano (spec 049, AC-003).
  @override
  Future<AssistDraft> assistDraft({
    required String kind,
    required String category,
    required String userText,
    int lengthLimit = 600,
  }) async {
    if (!ctx.simulateCounterpart) {
      throw const ApiException(code: 'assist.unavailable', status: 503);
    }
    await _lag(600);
    final what = fcat(category).name.toLowerCase();
    var base = userText.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (base.isNotEmpty && !RegExp(r'[.!?]$').hasMatch(base)) base = '$base.';
    if (base.isNotEmpty) base = base[0].toUpperCase() + base.substring(1);
    final text = kind == 'work'
        ? 'Trabajo de $what. $base Se revisó el problema, se explicó al cliente qué se haría y se dejó todo limpio.'
        : 'Busco a alguien de $what. $base ¿Me puedes decir cuándo podrías revisarlo? Puedo mandar fotos por el chat.';
    final out = text.length > lengthLimit ? text.substring(0, lengthLimit) : text;
    return AssistDraft(text: out, modelVersion: 'demo-plantilla');
  }

  // ============================================== dispositivos (sin push)
  @override
  Future<String> registerDevice({required String fcmToken, required String appVersion}) async => 'dev_demo';

  @override
  Future<void> removeDevice(String deviceId) async {}
}
