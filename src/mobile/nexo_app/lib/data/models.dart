// Modelos de los endpoints de Nexo. Los nombres de campo son los de los
// contratos (docs/endpoints). Cada `fromJson` lee lo que la app usa; los
// campos que faltan en una respuesta quedan en su valor por defecto.

typedef Json = Map<String, dynamic>;

String? _s(Object? v) => v?.toString();
String _sd(Object? v, [String d = '']) => v?.toString() ?? d;
int _i(Object? v, [int d = 0]) => v is num ? v.toInt() : int.tryParse('$v') ?? d;
double? _dn(Object? v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
bool _b(Object? v) => v == true || v == 'true';
List<String> _ls(Object? v) => v is List ? v.map((e) => '$e').toList() : const [];
List<T> _lo<T>(Object? v, T Function(Json) f) =>
    v is List ? v.whereType<Map>().map((e) => f(Json.from(e))).toList() : <T>[];
Json? _m(Object? v) => v is Map ? Json.from(v) : null;

/// Página por cursor (`{ items, nextCursor, hasMore }`).
class CursorPage<T> {
  const CursorPage(this.items, {this.nextCursor, this.hasMore = false, this.total});
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
  final int? total;
}

class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  factory GeoPoint.fromJson(Json j) => GeoPoint(_dn(j['lat']) ?? 0, _dn(j['lng']) ?? 0);
  final double lat;
  final double lng;
  Json toJson() => {'lat': lat, 'lng': lng};
}

class Img {
  const Img(this.url, {this.thumbUrl});
  factory Img.fromJson(Json j) => Img(_sd(j['url']), thumbUrl: _s(j['thumbUrl']));
  final String url;
  final String? thumbUrl;
}

class Rating {
  const Rating(this.avg, this.count);
  factory Rating.fromJson(Json? j) => Rating(_dn(j?['avg']) ?? 0, _i(j?['count']));
  final double avg;
  final int count;
  String get text => count == 0 ? 'Sin calificaciones' : '${avg.toStringAsFixed(1)} ($count)';
}

class OpenStatus {
  const OpenStatus(this.open, this.text);
  factory OpenStatus.fromJson(Json? j) =>
      OpenStatus(_b(j?['open']), _sd(j?['text'], 'Horario no publicado'));
  final bool open;
  final String text;
  String get short => open ? 'Abierto ahora' : (text.startsWith('Horario') ? text : 'Cerrado');
}

// ---------- catálogo ----------

class Specialty {
  const Specialty(this.slug, this.name);
  final String slug;
  final String name;
}

class ServiceCategory {
  const ServiceCategory({
    required this.slug,
    required this.name,
    required this.icon,
    required this.c1,
    required this.c2,
    this.specialties = const [],
    this.businessLabel = '',
    this.tradeLabel = '',
  });

  factory ServiceCategory.fromJson(Json j) {
    final g = _m(j['gradient']);
    return ServiceCategory(
      slug: _sd(j['slug']),
      name: _sd(j['name']),
      icon: _sd(j['icon'], 'dots'),
      c1: _sd(g?['from'], '#9AA7AD'),
      c2: _sd(g?['to'], '#6B7A82'),
      specialties: _lo(j['specialties'], (s) => Specialty(_sd(s['slug']), _sd(s['name']))),
      businessLabel: _sd(j['businessLabel']),
      tradeLabel: _sd(j['tradeLabel']),
    );
  }

  final String slug;
  final String name;
  final String icon;
  final String c1;
  final String c2;
  final List<Specialty> specialties;
  final String businessLabel;
  final String tradeLabel;
}

// ---------- prestadores ----------

/// Resumen de prestador (feed, chat, guardados, interesados).
class ProviderMini {
  const ProviderMini({required this.id, required this.name, this.photoUrl, this.kind = 'trade', this.phoneVerified = false});
  factory ProviderMini.fromJson(Json j) => ProviderMini(
        id: _sd(j['providerId'] ?? j['id']),
        name: _sd(j['name'] ?? j['displayName']),
        photoUrl: _s(j['photoUrl']),
        kind: _sd(j['kind'], 'trade'),
        phoneVerified: _ls(j['badges']).contains('phoneVerified'),
      );
  final String id;
  final String name;
  final String? photoUrl;
  final String kind;
  final bool phoneVerified;
}

class PriceItem {
  const PriceItem({required this.service, this.fromCents, this.unit = 'from', this.suffix = ''});
  factory PriceItem.fromJson(Json j) => PriceItem(
        service: _sd(j['service']),
        fromCents: j['fromCents'] == null ? null : _i(j['fromCents']),
        unit: _sd(j['unit'], 'from'),
        suffix: _sd(j['suffix']),
      );
  final String service;
  final int? fromCents;
  final String unit;
  final String suffix;
  Json toJson() => {'service': service, 'fromCents': fromCents ?? 0, 'unit': unit, 'suffix': suffix};
}

class DayHours {
  const DayHours(this.open, this.close);
  final String open;
  final String close;
}

class ProviderBadge {
  const ProviderBadge(this.key, this.label, {this.level = 'declared'});
  final String key;
  final String label;
  final String level;
}

/// Tarjeta de resultados de búsqueda / interesados (también sirve para el perfil).
class ProviderProfile {
  const ProviderProfile({
    required this.id,
    required this.name,
    this.kind = 'trade',
    this.photoUrl,
    this.coverUrl,
    this.categories = const [],
    this.specialties = const [],
    this.bio = '',
    this.owner,
    this.activity,
    this.experience,
    this.crew,
    this.attention = 'home',
    this.attentionText = '',
    this.zoneLabel = '',
    this.distanceKm,
    this.distanceText = '',
    this.radiusKm = 0,
    this.shopLocation,
    this.zonePoint,
    this.status = const OpenStatus(false, 'Horario no publicado'),
    this.days = const [],
    this.urgent = false,
    this.visitMode = 'hidden',
    this.visitText,
    this.minPriceText,
    this.minPriceCents,
    this.prices = const [],
    this.payment = const [],
    this.responseTime,
    this.warranty,
    this.invoice = false,
    this.web,
    this.portfolio = const [],
    this.badges = const [],
    this.rating = const Rating(0, 0),
    this.recs = 0,
    this.jobs = 0,
    this.channelChat = true,
    this.channelCall = false,
    this.updatedText = '',
    this.phoneVerified = false,
    this.isNew = false,
  });

  factory ProviderProfile.fromJson(Json j) {
    final trust = _m(j['trust']);
    final op = _m(trust?['userOpinion']);
    final badgesRaw = j['badges'];
    final badges = badgesRaw is List
        ? badgesRaw.map((b) => b is Map
            ? ProviderBadge(_sd(b['key']), _sd(b['label']), level: _sd(b['level'], 'declared'))
            : ProviderBadge('$b', '$b' == 'phoneVerified' ? 'Teléfono confirmado' : '$b')).toList()
        : <ProviderBadge>[];
    final sched = _m(j['schedule']);
    final days = sched?['days'] is List
        ? (sched!['days'] as List)
            .map((d) => d is Map ? DayHours(_sd(d['open']), _sd(d['close'])) : null)
            .toList()
        : <DayHours?>[];
    final visit = _m(j['visit']);
    final minP = _m(j['minPrice']);
    final channels = _m(j['channels']);
    return ProviderProfile(
      id: _sd(j['providerId'] ?? j['id']),
      name: _sd(j['name']),
      kind: _sd(j['kind'], 'trade'),
      photoUrl: _s(j['photoUrl']),
      coverUrl: _s(j['coverUrl']),
      categories: _ls(j['categories']),
      specialties: _ls(j['specialties']),
      bio: _sd(j['bio'] ?? j['bioExcerpt']),
      owner: _s(j['owner']),
      activity: _s(j['activity']),
      experience: j['experience'] == null ? null : _i(j['experience']),
      crew: _s(j['crew']),
      attention: _sd(j['attention'], 'home'),
      attentionText: _sd(j['attentionText']),
      zoneLabel: _sd(j['zoneLabel'] ?? _m(j['publicZone'])?['label']),
      distanceKm: _dn(j['distanceKm']),
      distanceText: _sd(j['distanceText']),
      radiusKm: _i(j['radiusKm']),
      shopLocation: _m(j['shopLocation']) == null ? null : GeoPoint.fromJson(_m(j['shopLocation'])!),
      zonePoint: _m(_m(j['publicZone'])?['point']) == null ? null : GeoPoint.fromJson(_m(_m(j['publicZone'])!['point'])!),
      status: OpenStatus.fromJson(_m(j['status'])),
      days: days,
      urgent: _b(sched?['urgent'] ?? j['urgent']),
      visitMode: _sd(visit?['mode'], 'hidden'),
      visitText: _s(visit?['text']),
      minPriceText: _s(minP?['text']),
      minPriceCents: minP?['fromCents'] == null ? null : _i(minP!['fromCents']),
      prices: _lo(j['prices'], PriceItem.fromJson),
      payment: _ls(j['payment']),
      responseTime: _s(j['responseTime']),
      warranty: _s(j['warranty']),
      invoice: _b(j['invoice']),
      web: _s(j['web']),
      portfolio: _lo(j['portfolio'], Img.fromJson),
      badges: badges,
      rating: Rating.fromJson(_m(j['rating']) ?? _m(op?['rating'])),
      recs: _i(j['recs'] ?? op?['recs']),
      jobs: _i(j['jobs']),
      channelChat: channels == null ? true : _b(channels['chat']),
      channelCall: _b(channels?['call']),
      updatedText: _sd(j['updatedText']),
      phoneVerified: _b(j['phoneVerified']) || badges.any((b) => b.key == 'phoneVerified'),
      isNew: _b(j['isNew']) || badges.any((b) => b.key == 'isNew'),
    );
  }

  final String id;
  final String name;
  final String kind;
  final String? photoUrl;
  final String? coverUrl;
  final List<String> categories;
  final List<String> specialties;
  final String bio;
  final String? owner;
  final String? activity;
  final int? experience;
  final String? crew;
  final String attention;
  final String attentionText;
  final String zoneLabel;
  final double? distanceKm;
  final String distanceText;
  final int radiusKm;
  final GeoPoint? shopLocation;
  final GeoPoint? zonePoint;
  final OpenStatus status;
  final List<DayHours?> days;
  final bool urgent;
  final String visitMode;
  final String? visitText;
  final String? minPriceText;
  final int? minPriceCents;
  final List<PriceItem> prices;
  final List<String> payment;
  final String? responseTime;
  final String? warranty;
  final bool invoice;
  final String? web;
  final List<Img> portfolio;
  final List<ProviderBadge> badges;
  final Rating rating;
  final int recs;
  final int jobs;
  final bool channelChat;
  final bool channelCall;
  final String updatedText;
  final bool phoneVerified;
  final bool isNew;

  bool get isBusiness => kind == 'business';
  bool get hasShop => attention == 'shop' || attention == 'both';
  ProviderMini get mini =>
      ProviderMini(id: id, name: name, photoUrl: photoUrl, kind: kind, phoneVerified: phoneVerified);
}

/// `GET /providers/me`: el perfil propio con lo que falta por completar.
class MyProvider {
  const MyProvider({required this.profile, this.completeness = 0, this.todo = const [], this.views = 0, this.contactClicks = 0, this.location});
  factory MyProvider.fromJson(Json j) {
    final st = _m(j['stats']);
    return MyProvider(
      profile: ProviderProfile.fromJson(j),
      completeness: _i(j['completeness']),
      todo: _lo(j['todo'], (t) => TodoItem(_sd(t['key']), _sd(t['label']), _i(t['points']), _b(t['done']))),
      views: _i(st?['views']),
      contactClicks: _i(st?['contactClicks']),
      location: _m(j['location']) == null ? null : GeoPoint.fromJson(_m(j['location'])!),
    );
  }
  final ProviderProfile profile;
  final int completeness;
  final List<TodoItem> todo;
  final int views;
  final int contactClicks;
  final GeoPoint? location;
}

class TodoItem {
  const TodoItem(this.key, this.label, this.points, this.done);
  final String key;
  final String label;
  final int points;
  final bool done;
}

// ---------- trabajos ----------

class Work {
  const Work({
    required this.id,
    required this.provider,
    required this.category,
    required this.title,
    this.text = '',
    this.images = const [],
    this.zoneLabel = '',
    this.distanceText = '',
    this.recs = 0,
    this.tag,
    this.ago = '',
    this.saved = false,
    this.recommended = false,
    this.canContact = true,
  });

  factory Work.fromJson(Json j, {ProviderMini? provider}) => Work(
        id: _sd(j['workId']),
        provider: provider ?? ProviderMini.fromJson(_m(j['provider']) ?? const {}),
        category: _sd(j['category'], 'otros'),
        title: _sd(j['title']),
        text: _sd(j['text'] ?? j['textExcerpt']),
        images: _lo(j['images'], Img.fromJson),
        zoneLabel: _sd(j['zoneLabel']),
        distanceText: _sd(j['distanceText']),
        recs: _i(j['recs']),
        tag: _s(j['tag']),
        ago: _sd(j['ago']),
        saved: _b(j['saved']),
        recommended: _b(j['recommended']),
        canContact: j['canContact'] == null ? true : _b(j['canContact']),
      );

  final String id;
  final ProviderMini provider;
  final String category;
  final String title;
  final String text;
  final List<Img> images;
  final String zoneLabel;
  final String distanceText;
  final int recs;
  final String? tag;
  final String ago;
  final bool saved;
  final bool recommended;
  final bool canContact;

  Work copyWith({bool? saved, bool? recommended, int? recs}) => Work(
        id: id, provider: provider, category: category, title: title, text: text, images: images,
        zoneLabel: zoneLabel, distanceText: distanceText, recs: recs ?? this.recs, tag: tag, ago: ago,
        saved: saved ?? this.saved, recommended: recommended ?? this.recommended, canContact: canContact,
      );
}

class FeedPage {
  const FeedPage({required this.zoneLabel, required this.page, this.guest = false});
  final String zoneLabel;
  final CursorPage<Work> page;
  final bool guest;
}

// ---------- solicitudes ----------

class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.category,
    required this.title,
    this.description = '',
    this.urgency = 'week',
    this.urgencyText = 'Esta semana',
    this.zoneLabel = '',
    this.distanceText = '',
    this.imageUrl,
    this.status = 'open',
    this.interestCount = 0,
    this.interestedPreview = const [],
    this.interestedMoreCount = 0,
    this.summaryText = '',
    this.picked,
    this.ago = '',
    this.iAmInterested = false,
    this.inMyRadius = true,
    this.matchesMyService = false,
    this.clientName = '',
    this.clientPhoto,
    this.saved = false,
    this.mine = false,
    this.orderId,
  });

  factory ServiceRequest.fromJson(Json j, {bool mine = false}) {
    final client = _m(j['client']);
    final pick = _m(j['pickedProvider']);
    return ServiceRequest(
      id: _sd(j['requestId']),
      category: _sd(j['category'], 'otros'),
      title: _sd(j['title']),
      description: _sd(j['description'] ?? j['descriptionExcerpt']),
      urgency: _sd(j['urgency'], 'week'),
      urgencyText: _sd(j['urgencyText'], 'Esta semana'),
      zoneLabel: _sd(j['zoneLabel']),
      distanceText: _sd(j['distanceText']),
      imageUrl: _s(j['imageUrl']),
      status: _sd(j['status'], 'open'),
      interestCount: _i(j['interestCount']),
      interestedPreview: _lo(j['interestedPreview'], ProviderMini.fromJson),
      interestedMoreCount: _i(j['interestedMoreCount']),
      summaryText: _sd(j['summaryText']),
      picked: pick == null ? null : ProviderMini.fromJson(pick),
      ago: _sd(j['ago']),
      iAmInterested: _b(j['iAmInterested']),
      inMyRadius: j['inMyRadius'] == null ? true : _b(j['inMyRadius']),
      matchesMyService: _b(j['matchesMyService']),
      clientName: _sd(client?['displayName']),
      clientPhoto: _s(client?['photoUrl']),
      saved: _b(j['saved']),
      mine: mine,
      orderId: _s(j['orderId']),
    );
  }

  final String id;
  final String category;
  final String title;
  final String description;
  final String urgency;
  final String urgencyText;
  final String zoneLabel;
  final String distanceText;
  final String? imageUrl;
  final String status;
  final int interestCount;
  final List<ProviderMini> interestedPreview;
  final int interestedMoreCount;
  final String summaryText;
  final ProviderMini? picked;
  final String ago;
  final bool iAmInterested;
  final bool inMyRadius;
  final bool matchesMyService;
  final String clientName;
  final String? clientPhoto;
  final bool saved;
  final bool mine;
  final String? orderId;

  bool get closed => status == 'closed';
}

class Interested {
  const Interested({required this.provider, this.note, this.conversationId, this.orderStatus, this.canOrder = true, this.canMessage = true});
  factory Interested.fromJson(Json j) {
    final a = _m(j['actions']);
    return Interested(
      provider: ProviderProfile.fromJson(j),
      note: _s(j['note']),
      conversationId: _s(j['conversationId']),
      orderStatus: _s(j['orderStatus']),
      canOrder: a == null ? true : _b(a['canOrder']),
      canMessage: a == null ? true : _b(a['canMessage']),
    );
  }
  final ProviderProfile provider;
  final String? note;
  final String? conversationId;
  final String? orderStatus;
  final bool canOrder;
  final bool canMessage;
}

class InterestedPage {
  const InterestedPage({required this.requestId, required this.title, required this.status, required this.items});
  final String requestId;
  final String title;
  final String status;
  final List<Interested> items;
}

// ---------- pedidos ----------

class Counterpart {
  const Counterpart({required this.id, required this.displayName, this.photoUrl, this.kind = 'client', this.canCopyPhone = false, this.providerId});
  factory Counterpart.fromJson(Json? j) => Counterpart(
        id: _sd(j?['accountId'] ?? j?['id']),
        providerId: _s(j?['providerId'] ?? (_sd(j?['kind']) == 'provider' ? (j?['id']) : null)),
        displayName: _sd(j?['displayName'] ?? j?['name']),
        photoUrl: _s(j?['photoUrl']),
        kind: _sd(j?['kind'], 'client'),
        canCopyPhone: _b(j?['canCopyPhone']),
      );
  final String id;
  final String displayName;
  final String? photoUrl;
  final String kind;
  final bool canCopyPhone;

  /// Si la contraparte es un prestador, su perfil público.
  final String? providerId;
}

class Money {
  const Money(this.amountCents, {this.includes, this.text});
  factory Money.fromJson(Json j) =>
      Money(_i(j['amountCents']), includes: _s(j['includes']), text: _s(j['text']));
  final int amountCents;
  final String? includes;
  final String? text;
  String get display => text ?? formatMoney(amountCents);
}

String formatMoney(int cents) {
  final pesos = cents ~/ 100;
  final s = pesos.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '\$$s';
}

class TimelineEvent {
  const TimelineEvent(this.type, this.actor, this.text);
  final String type;
  final String actor;
  final String text;
}

class Order {
  const Order({
    required this.id,
    required this.status,
    required this.statusText,
    required this.role,
    required this.counterpart,
    required this.category,
    this.description = '',
    this.attention = 'home',
    this.placeZone = '',
    this.address,
    this.addressNote,
    this.location,
    this.agreedPrice,
    this.requestId,
    this.requestTitle,
    this.conversationId,
    this.ago = '',
    this.allowedActions = const [],
    this.version = 1,
    this.canReview = false,
    this.myReviewStars,
    this.timeline = const [],
    this.providerId,
    this.mapExact = false,
    this.directionsUrl,
  });

  factory Order.fromJson(Json j) {
    final price = _m(j['agreedPrice']);
    final review = _m(j['review']);
    final map = _m(j['map']);
    final req = _m(j['request']);
    return Order(
      id: _sd(j['orderId']),
      status: _sd(j['status'], 'pending'),
      statusText: _sd(j['statusText']),
      role: _sd(j['role'], 'client'),
      counterpart: Counterpart.fromJson(_m(j['counterpart'])),
      category: _sd(j['category'], 'otros'),
      description: _sd(j['description'] ?? j['descriptionExcerpt']),
      attention: _sd(j['attention'], 'home'),
      placeZone: _sd(j['placeZone']),
      address: _s(j['address']),
      addressNote: _s(j['addressNote']),
      location: _m(j['location'] ?? map?['point']) == null ? null : GeoPoint.fromJson(_m(j['location'] ?? map?['point'])!),
      agreedPrice: price == null ? null : Money.fromJson(price),
      requestId: _s(j['requestId'] ?? req?['requestId']),
      requestTitle: _s(req?['title']),
      conversationId: _s(j['conversationId']),
      ago: _sd(j['ago']),
      allowedActions: _ls(j['allowedActions']),
      version: _i(j['version'], 1),
      canReview: _b(j['canReview'] ?? review?['canReview']),
      myReviewStars: j['myReviewStars'] == null ? null : _i(j['myReviewStars']),
      timeline: _lo(j['timeline'], (t) => TimelineEvent(_sd(t['type']), _sd(t['actor']), _sd(t['text']))),
      providerId: _s(j['providerId']),
      mapExact: _sd(map?['kind']) == 'exact',
      directionsUrl: _s(map?['directionsUrl']),
    );
  }

  final String id;
  final String status;
  final String statusText;
  final String role;
  final Counterpart counterpart;
  final String category;
  final String description;
  final String attention;
  final String placeZone;
  final String? address;
  final String? addressNote;
  final GeoPoint? location;
  final Money? agreedPrice;
  final String? requestId;
  final String? requestTitle;
  final String? conversationId;
  final String ago;
  final List<String> allowedActions;
  final int version;
  final bool canReview;
  final int? myReviewStars;
  final List<TimelineEvent> timeline;
  final String? providerId;
  final bool mapExact;
  final String? directionsUrl;

  bool get iAmProvider => role == 'provider';
  bool can(String a) => allowedActions.contains(a);
}

class OrdersPage {
  const OrdersPage(this.items, {this.pending = 0, this.accepted = 0, this.resolved = 0});
  final List<Order> items;
  final int pending;
  final int accepted;
  final int resolved;
}

// ---------- opiniones ----------

class Review {
  const Review({required this.id, required this.stars, required this.text, required this.recommend, required this.author, this.authorPhoto, this.ago = ''});
  factory Review.fromJson(Json j) {
    final a = _m(j['author']);
    return Review(
      id: _sd(j['reviewId']),
      stars: _i(j['stars']),
      text: _sd(j['text']),
      recommend: _b(j['recommend']),
      author: _sd(a?['displayName']),
      authorPhoto: _s(a?['photoUrl']),
      ago: _sd(j['ago']),
    );
  }
  final String id;
  final int stars;
  final String text;
  final bool recommend;
  final String author;
  final String? authorPhoto;
  final String ago;
}

class ReviewsPage {
  const ReviewsPage({required this.avg, required this.count, required this.recommendCount, required this.items});
  factory ReviewsPage.fromJson(Json j) {
    final s = _m(j['summary']);
    return ReviewsPage(
      avg: _dn(s?['avg']) ?? 0,
      count: _i(s?['count']),
      recommendCount: _i(s?['recommendCount']),
      items: _lo(j['items'], Review.fromJson),
    );
  }
  final double avg;
  final int count;
  final int recommendCount;
  final List<Review> items;
}

// ---------- mensajes ----------

class ActiveOrder {
  const ActiveOrder(this.orderId, this.status, this.statusText);
  static ActiveOrder? fromJson(Json? j) =>
      j == null ? null : ActiveOrder(_sd(j['orderId']), _sd(j['status']), _sd(j['statusText']));
  final String orderId;
  final String status;
  final String statusText;
}

class Conversation {
  const Conversation({
    required this.id,
    required this.counterpart,
    this.lastPreview = '',
    this.ago = '',
    this.unread = 0,
    this.requestId,
    this.activeOrder,
    this.blocked = false,
    this.blockedByMe = false,
  });
  factory Conversation.fromJson(Json j) => Conversation(
        id: _sd(j['conversationId']),
        counterpart: Counterpart.fromJson(_m(j['counterpart'])),
        lastPreview: _sd(j['lastPreview']),
        ago: _sd(j['ago']),
        unread: _i(j['unread']),
        requestId: _s(j['requestId']),
        activeOrder: ActiveOrder.fromJson(_m(j['activeOrder'])),
        blocked: _b(j['blocked']),
        blockedByMe: _b(j['blockedByMe']),
      );
  final String id;
  final Counterpart counterpart;
  final String lastPreview;
  final String ago;
  final int unread;
  final String? requestId;
  final ActiveOrder? activeOrder;
  final bool blocked;
  final bool blockedByMe;
}

class Message {
  const Message({required this.id, required this.kind, this.text = '', this.imageUrl, required this.mine, this.createdAt, this.readAt, this.systemType, this.orderId});
  factory Message.fromJson(Json j) {
    final sys = _m(j['system']);
    return Message(
      id: _sd(j['messageId']),
      kind: _sd(j['kind'], 'text'),
      text: _sd(j['text']),
      imageUrl: _s(j['thumbUrl'] ?? j['imageUrl']),
      mine: _b(j['mine']),
      createdAt: DateTime.tryParse(_sd(j['createdAt']))?.toLocal(),
      readAt: DateTime.tryParse(_sd(j['readAt']))?.toLocal(),
      systemType: _s(sys?['type']),
      orderId: _s(sys?['orderId']),
    );
  }
  final String id;
  final String kind;
  final String text;
  final String? imageUrl;
  final bool mine;
  final DateTime? createdAt;
  final DateTime? readAt;
  final String? systemType;
  final String? orderId;
}

class ChatThread {
  const ChatThread({required this.id, required this.counterpart, required this.messages, this.activeOrder, this.blocked = false, this.canSend = true, this.quickReplies = const [], this.hasMore = false, this.nextCursor});
  final String id;
  final Counterpart counterpart;
  final List<Message> messages; // del más viejo al más nuevo
  final ActiveOrder? activeOrder;
  final bool blocked;
  final bool canSend;
  final List<String> quickReplies;
  final bool hasMore;
  final String? nextCursor;
}

// ---------- guardados, notificaciones, cuenta ----------

class SavedItem {
  const SavedItem({required this.kind, required this.targetId, this.available = true, this.provider, this.work, this.request});
  final String kind;
  final String targetId;
  final bool available;
  final ProviderProfile? provider;
  final Work? work;
  final ServiceRequest? request;
}

class SavedCounts {
  const SavedCounts({this.provider = 0, this.work = 0, this.request = 0});
  factory SavedCounts.fromJson(Json? j) =>
      SavedCounts(provider: _i(j?['provider']), work: _i(j?['work']), request: _i(j?['request']));
  final int provider;
  final int work;
  final int request;
  int get total => provider + work + request;
}

class NotificationItem {
  const NotificationItem({required this.id, required this.title, this.body = '', this.deepLink, this.actionLabel, this.icon = 'bell', this.read = false, this.ago = ''});
  factory NotificationItem.fromJson(Json j) => NotificationItem(
        id: _sd(j['notificationId']),
        title: _sd(j['title']),
        body: _sd(j['body']),
        deepLink: _s(j['deepLink']),
        actionLabel: _s(j['actionLabel']),
        icon: _sd(j['icon'], 'bell'),
        read: j['readAt'] != null,
        ago: _sd(j['ago']),
      );
  final String id;
  final String title;
  final String body;
  final String? deepLink;
  final String? actionLabel;
  final String icon;
  final bool read;
  final String ago;
}

class AccountScreen {
  const AccountScreen({
    required this.name,
    this.email = '',
    this.photoUrl,
    this.phone,
    this.phoneVerified = false,
    this.status = 'active',
    this.deletionRequestedAt,
    this.mode = 'client',
    this.hasProvider = false,
    this.providerId,
    this.providerName,
    this.completeness = 0,
    this.nextTodo,
    this.requests = 0,
    this.orders = 0,
    this.views = 0,
    this.contactClicks = 0,
    this.interestsGiven = 0,
    this.ordersResolved = 0,
    this.providerRating = const Rating(0, 0),
    this.saved = const SavedCounts(),
    this.zoneLabel = 'Centro',
    this.radiusKm = 10,
    this.privacyUrl,
    this.termsUrl,
  });

  factory AccountScreen.fromJson(Json j) {
    final a = _m(j['account']);
    final m = _m(j['mode']);
    final p = _m(j['provider']);
    final st = _m(j['stats']);
    final asC = _m(st?['asClient']);
    final asP = _m(st?['asProvider']);
    final search = _m(j['search']);
    final links = _m(j['links']);
    return AccountScreen(
      name: _sd(a?['name']),
      email: _sd(a?['email']),
      photoUrl: _s(a?['photoUrl']),
      phone: _s(a?['phone']),
      phoneVerified: _b(a?['phoneVerified']),
      status: _sd(a?['status'], 'active'),
      deletionRequestedAt: _s(a?['deletionRequestedAt']),
      mode: _sd(m?['current'], 'client'),
      hasProvider: _b(m?['hasProvider']),
      providerId: _s(p?['providerId']),
      providerName: _s(p?['name']),
      completeness: _i(p?['completeness']),
      nextTodo: _s(_m(p?['nextTodo'])?['label']),
      requests: _i(asC?['requests']),
      orders: _i(asC?['orders']),
      views: _i(asP?['views']),
      contactClicks: _i(asP?['contactClicks']),
      interestsGiven: _i(asP?['interestsGiven']),
      ordersResolved: _i(asP?['ordersResolved']),
      providerRating: Rating.fromJson(_m(asP?['rating'])),
      saved: SavedCounts.fromJson(_m(j['savedCounts'])),
      zoneLabel: _sd(search?['zoneLabel'], 'Centro'),
      radiusKm: _i(search?['radiusKm'], 10),
      privacyUrl: _s(links?['privacy']),
      termsUrl: _s(links?['terms']),
    );
  }

  final String name;
  final String email;
  final String? photoUrl;
  final String? phone;
  final bool phoneVerified;
  final String status;
  final String? deletionRequestedAt;
  final String mode;
  final bool hasProvider;
  final String? providerId;
  final String? providerName;
  final int completeness;
  final String? nextTodo;
  final int requests;
  final int orders;
  final int views;
  final int contactClicks;
  final int interestsGiven;
  final int ordersResolved;
  final Rating providerRating;
  final SavedCounts saved;
  final String zoneLabel;
  final int radiusKm;
  final String? privacyUrl;
  final String? termsUrl;

  bool get pendingDeletion => status == 'pendingDeletion';
}

class MapPoint {
  const MapPoint({required this.id, required this.point, required this.state, required this.title, this.subtitle = ''});
  factory MapPoint.fromJson(Json j) => MapPoint(
        id: _sd(j['id']),
        point: GeoPoint.fromJson(_m(j['point']) ?? const {}),
        state: _sd(j['state']),
        title: _sd(j['title']),
        subtitle: _sd(j['subtitle']),
      );
  final String id;
  final GeoPoint point;
  final String state; // open | closed | today | week…
  final String title;
  final String subtitle;
}

class MapNearby {
  const MapNearby({required this.points, required this.summary});
  final List<MapPoint> points;
  final String summary;
}

class LocationResult {
  const LocationResult({required this.point, required this.zoneLabel, required this.radiusKm, this.summary = ''});
  final GeoPoint point;
  final String zoneLabel;
  final int radiusKm;
  final String summary;
}

class CompareRow {
  const CompareRow(this.key, this.label, this.values, this.best);
  final String key;
  final String label;
  final List<String> values;
  final int? best;
}

class CompareResult {
  const CompareResult(this.providers, this.rows);
  final List<ProviderMini> providers;
  final List<CompareRow> rows;
  static CompareResult fromJson(Json j) => CompareResult(
        _lo(j['providers'], ProviderMini.fromJson),
        _lo(j['rows'], (r) => CompareRow(_sd(r['key']), _sd(r['label']), _ls(r['values']), r['best'] == null ? null : _i(r['best']))),
      );
}

class Suggestion {
  const Suggestion(this.kind, this.slug, this.label);
  final String kind;
  final String slug;
  final String label;
}

class PhoneReveal {
  const PhoneReveal(this.displayPhone, this.targetName);
  final String displayPhone;
  final String targetName;
}

class UploadTicket {
  const UploadTicket({required this.uploadId, required this.uploadUrl, required this.headers});
  final String uploadId;
  final String uploadUrl;
  final Map<String, String> headers;
}

/// Filtros de búsqueda de prestadores (`GET /search/providers`).
class SearchFilters {
  const SearchFilters({this.q = '', this.cat, this.open = false, this.free = false, this.prices = false, this.urgent = false, this.attention, this.sort = 'relevance', this.expanded = false});
  final String q;
  final String? cat;
  final bool open;
  final bool free;
  final bool prices;
  final bool urgent;
  final String? attention; // home | shop
  final String sort; // relevance | near | recs
  final bool expanded;

  int get count => (cat != null ? 1 : 0) + (open ? 1 : 0) + (free ? 1 : 0) + (prices ? 1 : 0) + (urgent ? 1 : 0) + (attention != null ? 1 : 0) + (sort != 'relevance' ? 1 : 0);

  SearchFilters copyWith({String? q, Object? cat = _keep, bool? open, bool? free, bool? prices, bool? urgent, Object? attention = _keep, String? sort, bool? expanded}) => SearchFilters(
        q: q ?? this.q,
        cat: identical(cat, _keep) ? this.cat : cat as String?,
        open: open ?? this.open,
        free: free ?? this.free,
        prices: prices ?? this.prices,
        urgent: urgent ?? this.urgent,
        attention: identical(attention, _keep) ? this.attention : attention as String?,
        sort: sort ?? this.sort,
        expanded: expanded ?? this.expanded,
      );
}

/// Filtros del prestador sobre solicitudes (`GET /requests/opportunities`).
class OppFilters {
  const OppFilters({this.q = '', this.cat, this.today = false, this.inRadius = true, this.myServiceOnly = false});
  final String q;
  final String? cat;
  final bool today;
  final bool inRadius;
  final bool myServiceOnly;
  int get count => (cat != null ? 1 : 0) + (today ? 1 : 0) + (inRadius ? 0 : 1) + (myServiceOnly ? 1 : 0);
  OppFilters copyWith({String? q, Object? cat = _keep, bool? today, bool? inRadius, bool? myServiceOnly}) => OppFilters(
        q: q ?? this.q,
        cat: identical(cat, _keep) ? this.cat : cat as String?,
        today: today ?? this.today,
        inRadius: inRadius ?? this.inRadius,
        myServiceOnly: myServiceOnly ?? this.myServiceOnly,
      );
}

const Object _keep = Object();

class SearchResult {
  const SearchResult({required this.items, this.total = 0, this.outOfZone = false, this.notice});
  final List<ProviderProfile> items;
  final int total;
  final bool outOfZone;
  final String? notice;
}
