// Datos de ejemplo copiados de la maqueta V1.00.002 (P, X, POSTS, REQ, EXPS,
// cuentas demo). Solo los usa FakeNexoApi mientras el backend publica cada
// grupo de endpoints.

import '../models.dart';

class FCat {
  const FCat(this.id, this.name, this.c1, this.c2, this.icon, this.specs, this.giro, this.oficio);
  final String id;
  final String name;
  final String c1;
  final String c2;
  final String icon;
  final List<String> specs;
  final String giro;
  final String oficio;
}

const fakeCats = <FCat>[
  FCat(
      'plomeria',
      'Plomería',
      '#46A3F0',
      '#2B72D1',
      'drop',
      [
        'Fugas y reparaciones',
        'Instalación de boilers y calentadores',
        'Destapes y drenaje',
        'Tinacos y cisternas',
        'Instalación de baños y cocinas'
      ],
      'Plomería y fontanería',
      'Plomero/a'),
  FCat(
      'electricidad',
      'Electricidad',
      '#FFC043',
      '#F08A1C',
      'bolt',
      [
        'Instalaciones residenciales',
        'Instalaciones comerciales',
        'Centros de carga y tableros',
        'Reparación de cortos',
        'Iluminación y alumbrado exterior'
      ],
      'Instalaciones eléctricas',
      'Electricista'),
  FCat(
      'carpinteria',
      'Carpintería',
      '#C79062',
      '#94623B',
      'hammer',
      [
        'Closets y cocinas integrales',
        'Puertas y ventanas',
        'Muebles a la medida',
        'Reparación de muebles',
        'Restauración y barnizado'
      ],
      'Carpintería y mueblería',
      'Carpintero/a'),
  FCat(
      'pintura',
      'Pintura',
      '#F27AA8',
      '#CC4C86',
      'brush',
      [
        'Pintura de interiores',
        'Pintura de exteriores y fachadas',
        'Impermeabilizado',
        'Acabados decorativos',
        'Preparación de muros'
      ],
      'Pintura e impermeabilizantes',
      'Pintor/a'),
  FCat(
      'jardineria',
      'Jardinería',
      '#5CC593',
      '#2F9468',
      'leaf',
      [
        'Mantenimiento de jardines',
        'Poda y retiro de árboles',
        'Diseño de áreas verdes',
        'Sistemas de riego',
        'Instalación de pasto'
      ],
      'Jardinería y paisajismo',
      'Jardinero/a'),
  FCat(
      'cerrajeria',
      'Cerrajería',
      '#8A8FF2',
      '#5C63D6',
      'key',
      [
        'Apertura de puertas',
        'Cambio de chapas',
        'Duplicado de llaves',
        'Chapas multipunto y de seguridad',
        'Cerrajería automotriz'
      ],
      'Cerrajería y seguridad',
      'Cerrajero/a'),
  FCat('otros', 'Otros servicios', '#9AA7AD', '#6B7A82', 'dots', [], 'Otro giro', 'Otro oficio'),
];

FCat fcat(String id) => fakeCats.firstWhere((c) => c.id == id, orElse: () => fakeCats.last);

const fakeZones = <String, GeoPoint>{
  'Centro': GeoPoint(20.0535, -99.3425),
  'Jardines': GeoPoint(20.0790, -99.3300),
  'San Marcos': GeoPoint(20.0300, -99.3600),
  'Las Flores': GeoPoint(20.0750, -99.3750),
};

class FPrice {
  const FPrice(this.service, this.pesos, {this.suffix = ''});
  final String service;
  final int? pesos; // null = a cotizar
  final String suffix;
}

class FProv {
  FProv({
    required this.id,
    required this.name,
    required this.kind,
    required this.cats,
    required this.specs,
    required this.zone,
    required this.phone,
    required this.ok,
    required this.upd,
    required this.jobs,
    required this.recs,
    required this.exp,
    required this.bio,
    required this.kw,
    required this.schedule,
    required this.loc,
    required this.rad,
    this.attention = 'home',
    this.visit,
    this.visitNote,
    this.urgent = false,
    this.resp,
    this.pay = const ['Efectivo'],
    this.warr,
    this.inv = false,
    this.prices = const [],
    this.owner,
    this.isNew = false,
    this.activity,
    this.crew,
  });

  final String id;
  String name;
  String kind; // business | trade
  List<String> cats;
  List<String> specs;
  String zone;
  String phone;
  bool ok;
  int upd;
  int jobs;
  int recs;
  String exp;
  String bio;
  String kw;
  List<List<int>?> schedule; // 7 días, lunes primero
  GeoPoint loc;
  int rad;
  String attention; // home | shop | both
  int? visit; // pesos; 0 = sin costo
  String? visitNote;
  bool urgent;
  String? resp;
  List<String> pay;
  String? warr;
  bool inv;
  List<FPrice> prices;
  String? owner;
  bool isNew;
  String? activity;
  String? crew;
  String? photoUrl;
  String? coverUrl;
  bool chat = true;
  bool call = true;
  String? web;
  int views = 0;
  int clicks = 0;
}

List<FProv> seedProviders() => [
      FProv(
          id: 'p1',
          name: 'Hernández Plomería',
          kind: 'business',
          cats: ['plomeria'],
          specs: ['Fugas y reparaciones', 'Instalación de boilers y calentadores', 'Destapes y drenaje'],
          zone: 'Centro',
          phone: '771 555 0101',
          ok: true,
          upd: 2,
          jobs: 24,
          recs: 31,
          exp: '12 años de experiencia',
          bio:
              'Fugas, llaves, boilers y desazolve. Trabajamos con material de marca y damos aviso antes de cada visita.',
          kw: 'fuga llave boiler tinaco desazolve tuberia agua calentador',
          schedule: [
            [8, 18],
            [8, 18],
            [8, 18],
            [8, 18],
            [8, 18],
            [8, 18],
            null
          ],
          loc: const GeoPoint(20.0548, -99.3437),
          rad: 6,
          attention: 'both',
          visit: 200,
          visitNote: 'Se descuenta si contratas el trabajo',
          resp: 'Menos de 1 hora',
          pay: ['Efectivo', 'Transferencia'],
          warr: '30 días en mano de obra',
          inv: true,
          prices: const [
            FPrice('Reparación de fuga', 350),
            FPrice('Cambio de llave mezcladora', 450),
            FPrice('Destape de drenaje', 500),
            FPrice('Instalación de boiler', 900),
          ]),
      FProv(
          id: 'p2',
          name: 'Electro Servicios Ruiz',
          kind: 'business',
          cats: ['electricidad'],
          specs: ['Instalaciones residenciales', 'Instalaciones comerciales', 'Centros de carga y tableros'],
          zone: 'Centro',
          phone: '771 555 0102',
          ok: true,
          upd: 1,
          jobs: 17,
          recs: 22,
          exp: '8 años de experiencia',
          bio: 'Instalaciones eléctricas en casas y locales, centros de carga, apagadores y revisión de cortos.',
          kw: 'corto luz apagador contacto cableado centro de carga',
          schedule: [
            [9, 19],
            [9, 19],
            [9, 19],
            [9, 19],
            [9, 19],
            null,
            null
          ],
          loc: const GeoPoint(20.0519, -99.3444),
          rad: 6,
          visit: 150,
          visitNote: 'Incluye diagnóstico',
          resp: 'Mismo día',
          pay: ['Efectivo', 'Transferencia', 'Tarjeta'],
          warr: '60 días en instalación',
          inv: true,
          prices: const [
            FPrice('Cambio de apagador o contacto', 120),
            FPrice('Búsqueda de corto', 400),
            FPrice('Instalación de centro de carga', 1200),
          ]),
      FProv(
          id: 'p3',
          name: 'Carpintería Don Beto',
          kind: 'trade',
          cats: ['carpinteria'],
          specs: ['Closets y cocinas integrales', 'Puertas y ventanas', 'Muebles a la medida'],
          zone: 'Centro',
          phone: '771 555 0103',
          ok: false,
          upd: 9,
          jobs: 11,
          recs: 14,
          exp: '25 años de experiencia',
          bio: 'Closets, cocinas integrales, puertas y reparación de muebles. Trabajo a la medida.',
          kw: 'closet cocina puerta mueble madera',
          schedule: [
            [9, 17],
            [9, 17],
            [9, 17],
            [9, 17],
            [9, 17],
            [9, 17],
            null
          ],
          loc: const GeoPoint(20.0551, -99.3463),
          rad: 6,
          visit: 0,
          visitNote: 'Medición y cotización sin costo',
          resp: 'Menos de 1 día',
          pay: ['Efectivo'],
          warr: '6 meses en estructura',
          crew: 'alone',
          prices: const [
            FPrice('Ajuste o reparación de puerta', 350),
            FPrice('Closet a la medida', null),
            FPrice('Cocina integral', null),
          ]),
      FProv(
          id: 'p4',
          name: 'Marisol Vega',
          kind: 'trade',
          cats: ['pintura'],
          specs: ['Pintura de interiores', 'Pintura de exteriores y fachadas', 'Impermeabilizado'],
          zone: 'Jardines',
          phone: '771 555 0104',
          ok: true,
          upd: 3,
          jobs: 9,
          recs: 9,
          exp: '6 años de experiencia',
          bio: 'Pintura de interiores y exteriores, impermeabilizado y acabados en muro.',
          kw: 'pintar muro impermeabilizar pared',
          schedule: [
            [8, 16],
            [8, 16],
            [8, 16],
            [8, 16],
            [8, 16],
            [8, 16],
            null
          ],
          loc: const GeoPoint(20.0774, -99.3319),
          rad: 6,
          visit: 0,
          visitNote: 'Visita para medir y cotizar',
          resp: 'Menos de 1 hora',
          pay: ['Efectivo', 'Transferencia'],
          warr: '3 meses en acabados',
          crew: 'withHelpers',
          prices: const [
            FPrice('Pintura interior', 55, suffix: 'por m²'),
            FPrice('Impermeabilizado', 90, suffix: 'por m²'),
          ]),
      FProv(
          id: 'p5',
          name: 'Jardines Verdes',
          kind: 'business',
          cats: ['jardineria'],
          specs: ['Mantenimiento de jardines', 'Poda y retiro de árboles', 'Sistemas de riego'],
          zone: 'Las Flores',
          phone: '771 555 0105',
          ok: true,
          upd: 5,
          jobs: 19,
          recs: 18,
          exp: '10 años de experiencia',
          bio: 'Mantenimiento de jardines, poda, diseño de áreas verdes y riego.',
          kw: 'poda pasto jardin riego plantas',
          schedule: [
            null,
            [8, 15],
            [8, 15],
            [8, 15],
            [8, 15],
            [8, 15],
            [8, 13]
          ],
          loc: const GeoPoint(20.0734, -99.3769),
          rad: 6,
          visit: 0,
          visitNote: 'Visita de valoración',
          resp: 'Mismo día',
          pay: ['Efectivo', 'Transferencia', 'Tarjeta'],
          inv: true,
          prices: const [
            FPrice('Mantenimiento de jardín', 400, suffix: 'por visita'),
            FPrice('Poda de árboles y arbustos', 300),
          ]),
      FProv(
          id: 'p6',
          name: 'Cerrajería Express',
          kind: 'business',
          cats: ['cerrajeria'],
          specs: ['Apertura de puertas', 'Cambio de chapas', 'Duplicado de llaves'],
          zone: 'San Marcos',
          phone: '771 555 0106',
          ok: true,
          upd: 1,
          jobs: 15,
          recs: 20,
          exp: '9 años de experiencia',
          bio: 'Apertura de puertas, cambio de chapas, duplicado de llaves y chapas multipunto.',
          kw: 'chapa llave puerta abrir candado',
          schedule: [
            [7, 22],
            [7, 22],
            [7, 22],
            [7, 22],
            [7, 22],
            [7, 22],
            [7, 22]
          ],
          loc: const GeoPoint(20.0316, -99.3581),
          rad: 8,
          visit: 100,
          visitNote: 'Se descuenta del servicio',
          urgent: true,
          resp: 'Menos de 30 minutos',
          pay: ['Efectivo', 'Transferencia'],
          warr: '90 días en chapas instaladas',
          prices: const [
            FPrice('Apertura de puerta', 350),
            FPrice('Cambio de chapa (mano de obra)', 450),
            FPrice('Duplicado de llave', 30),
          ]),
      FProv(
          id: 'p7',
          name: 'Luis Ortega',
          kind: 'trade',
          cats: ['plomeria', 'electricidad'],
          specs: ['Fugas y reparaciones', 'Reparación de cortos'],
          zone: 'Jardines',
          phone: '771 555 0107',
          ok: false,
          upd: 0,
          jobs: 3,
          recs: 2,
          exp: '4 años de experiencia',
          bio: 'Plomería y electricidad doméstica. Perfil recién creado, con trabajos recientes.',
          kw: 'boiler fuga corto apagador',
          schedule: [
            [10, 18],
            [10, 18],
            [10, 18],
            [10, 18],
            [10, 18],
            null,
            null
          ],
          loc: const GeoPoint(20.0758, -99.3281),
          rad: 6,
          isNew: true,
          crew: 'alone'),
      FProv(
          id: 'p8',
          name: 'Cerrajería El Candado',
          kind: 'business',
          cats: ['cerrajeria'],
          specs: ['Duplicado de llaves', 'Chapas multipunto y de seguridad'],
          zone: 'Centro',
          phone: '771 555 0108',
          ok: true,
          upd: 1,
          jobs: 12,
          recs: 16,
          exp: '15 años en operación',
          bio:
              'Local de cerrajería en el Centro: duplicado de llaves comunes y de seguridad, venta de chapas y candados. Ven al local sin cita.',
          kw: 'llave duplicado copia chapa candado local',
          schedule: [
            [9, 19],
            [9, 19],
            [9, 19],
            [9, 19],
            [9, 19],
            [9, 19],
            null
          ],
          loc: const GeoPoint(20.0561, -99.3409),
          rad: 0,
          attention: 'shop',
          resp: 'Menos de 1 hora',
          pay: ['Efectivo', 'Tarjeta'],
          warr: 'Copias garantizadas',
          owner: 'Rosa Mendoza',
          prices: const [
            FPrice('Duplicado de llave', 25),
            FPrice('Duplicado de llave de seguridad', 120),
            FPrice('Candado de seguridad', 180),
          ]),
    ];

class FWork {
  FWork(this.id, this.p, this.cat, this.zone, this.title, this.text, this.ago, this.recs, this.tag, this.images);
  final String id;
  final String p;
  final String cat;
  final String zone;
  final String title;
  final String text;
  final String ago;
  int recs;
  final String? tag;
  final List<String> images;
  bool recommended = false;
}

/// Fotos de ejemplo: `demo://<categoría>/<n>` se dibuja como mosaico de color.
List<String> demoImgs(String cat, int n) => [for (var i = 0; i < n; i++) 'demo://$cat/$i'];

List<FWork> seedWorks() => [
      FWork(
          'w1',
          'p1',
          'plomeria',
          'Centro',
          'Cambio de llave mezcladora',
          'Sustituimos la llave de cocina y sellamos una fuga bajo la tarja. Trabajo resuelto en una mañana.',
          'hace 2 h',
          12,
          'Antes y después',
          demoImgs('plomeria', 1)),
      FWork(
          'w2',
          'p2',
          'electricidad',
          'Centro',
          'Centro de carga nuevo en local',
          'Reemplazo del centro de carga y reorganización de circuitos en un local comercial pequeño.',
          'hace 5 h',
          8,
          'Local comercial',
          demoImgs('electricidad', 1)),
      FWork(
          'w3',
          'p4',
          'pintura',
          'Jardines',
          'Sala y comedor en dos tonos',
          'Preparación de muros, sellador y dos manos de pintura. Entregado en dos días.',
          'ayer',
          15,
          'Interior',
          demoImgs('pintura', 2)),
      FWork(
          'w4',
          'p3',
          'carpinteria',
          'Centro',
          'Closet empotrado a la medida',
          'Closet de madera con entrepaños ajustables y puertas corredizas para una recámara.',
          'ayer',
          19,
          'A la medida',
          demoImgs('carpinteria', 2)),
      FWork(
          'w5',
          'p7',
          'plomeria',
          'Jardines',
          'Reparación de boiler de paso',
          'Cambio de válvula y limpieza de intercambiador. El boiler quedó funcionando el mismo día.',
          'hace 2 días',
          3,
          'Reparación',
          demoImgs('plomeria', 1)),
      FWork(
          'w6',
          'p5',
          'jardineria',
          'Las Flores',
          'Mantenimiento de jardín frontal',
          'Poda de arbustos, resiembra de pasto y ajuste del riego por goteo.',
          'hace 3 días',
          11,
          'Mantenimiento',
          demoImgs('jardineria', 2)),
      FWork(
          'w7',
          'p6',
          'cerrajeria',
          'San Marcos',
          'Cambio de chapa multipunto',
          'Retiramos una chapa dañada y colocamos una multipunto con tres llaves.',
          'hace 3 días',
          7,
          'Seguridad',
          demoImgs('cerrajeria', 1)),
      FWork(
          'w8',
          'p1',
          'plomeria',
          'Centro',
          'Calentador solar instalado',
          'Instalación completa de calentador solar con conexión a la red de agua caliente existente.',
          'hace 4 días',
          21,
          'Instalación',
          demoImgs('plomeria', 3)),
      FWork(
          'w9',
          'p8',
          'cerrajeria',
          'Centro',
          'Copias de llaves de seguridad al momento',
          'Duplicamos llaves de seguridad tipo puntos mientras esperas. Trae tu llave al local, sin cita.',
          'hace 1 día',
          9,
          'En el local',
          demoImgs('cerrajeria', 1)),
    ];

class FReq {
  FReq({
    required this.id,
    required this.user,
    required this.cat,
    required this.zone,
    required this.title,
    required this.text,
    required this.urg,
    required this.ago,
    required this.contact,
    required this.loc,
    this.mine = false,
    List<String>? interested,
    this.pick,
    this.closed = false,
    this.orderId,
    this.imageUrl,
  }) : interested = interested ?? [];

  final String id;
  final String user;
  final String cat;
  final String zone;
  final String title;
  final String text;
  final String urg; // today | week | noRush
  final String ago;
  final String contact; // chat | chatCall
  final GeoPoint loc;
  final bool mine;
  final List<String> interested;
  String? pick;
  bool closed;
  String? orderId;
  String? imageUrl;
}

GeoPoint _jit(String zone, int a, int b) {
  final z = fakeZones[zone]!;
  return GeoPoint(z.lat + a * 0.0016, z.lng + b * 0.0018);
}

List<FReq> seedRequests() => [
      FReq(
          id: 'r1',
          user: 'Ana Morales',
          cat: 'plomeria',
          zone: 'Centro',
          title: 'Fuga debajo del lavabo del baño',
          text: 'Hay una fuga y el piso está húmedo. Busco a alguien que pueda venir hoy o mañana a revisarla.',
          urg: 'today',
          ago: 'hace 40 min',
          contact: 'chat',
          loc: _jit('Centro', 1, -2)),
      FReq(
          id: 'r2',
          user: 'Cocina Doña Mary',
          cat: 'electricidad',
          zone: 'Centro',
          title: 'Revisión eléctrica en cocina de negocio',
          text:
              'Se botan las pastillas del centro de carga cuando se enciende la estufa eléctrica y el refrigerador. Necesito diagnóstico y presupuesto.',
          urg: 'week',
          ago: 'hace 3 h',
          contact: 'chatCall',
          loc: _jit('Centro', -2, 1)),
      FReq(
          id: 'r3',
          user: 'Jorge Ríos',
          cat: 'carpinteria',
          zone: 'Las Flores',
          title: 'Reparar puerta de madera que no cierra',
          text: 'La puerta principal se hinchó y roza con el marco. Quiero que la ajusten o la cepillen.',
          urg: 'noRush',
          ago: 'ayer',
          contact: 'chatCall',
          loc: _jit('Las Flores', 0, 2)),
      FReq(
          id: 'r4',
          user: 'Paola Núñez',
          cat: 'pintura',
          zone: 'Jardines',
          title: 'Pintar recámara y pasillo',
          text: 'Dos espacios de unos 30 m² en total. Ya tengo elegido el color y busco quien pinte y prepare el muro.',
          urg: 'week',
          ago: 'ayer',
          contact: 'chat',
          loc: _jit('Jardines', 2, 0)),
      FReq(
          id: 'r6',
          user: 'Daniela Cruz',
          cat: 'plomeria',
          zone: 'Jardines',
          title: 'Instalar boiler de paso',
          text: 'Compré el boiler y necesito quien lo instale y revise la conexión de gas y agua.',
          urg: 'week',
          ago: 'hace 5 h',
          contact: 'chat',
          loc: _jit('Jardines', -1, -1)),
      FReq(
          id: 'r7',
          user: 'Tienda La Esquina',
          cat: 'pintura',
          zone: 'Centro',
          title: 'Pintar fachada del local',
          text: 'Fachada de unos 25 m². Busco presupuesto y fecha disponible.',
          urg: 'noRush',
          ago: 'ayer',
          contact: 'chatCall',
          loc: _jit('Centro', 3, 3)),
      FReq(
          id: 'r8',
          user: 'Raúl Mendoza',
          cat: 'electricidad',
          zone: 'Jardines',
          title: 'Instalar contactos en cochera',
          text: 'Necesito dos contactos nuevos y una lámpara exterior en la cochera.',
          urg: 'week',
          ago: 'hace 1 día',
          contact: 'chat',
          loc: _jit('Jardines', -3, 2)),
      FReq(
          id: 'r5',
          user: 'Miguel Torres',
          cat: 'cerrajeria',
          zone: 'San Marcos',
          title: 'Cambiar la chapa de la puerta principal',
          text: 'Perdí un juego de llaves y prefiero cambiar la chapa completa por una más segura.',
          urg: 'today',
          ago: 'hace 2 h',
          contact: 'chat',
          loc: _jit('San Marcos', 1, 1)),
      // Casos de prueba de la cuenta demo (Ana): una abierta con interesados y otra resuelta.
      FReq(
          id: 'ra1',
          user: 'Tú',
          cat: 'plomeria',
          zone: 'Centro',
          title: 'Fuga en la válvula del calentador',
          text:
              'Gotea por la válvula de arriba del calentador y ya mojó la pared. Busco quien pueda venir esta semana.',
          urg: 'week',
          ago: 'hace 1 día',
          contact: 'chat',
          loc: const GeoPoint(20.0547, -99.3434),
          mine: true,
          interested: ['p1', 'p7']),
      FReq(
          id: 'ra2',
          user: 'Tú',
          cat: 'electricidad',
          zone: 'Centro',
          title: 'Contacto que echa chispas en la cocina',
          text:
              'Al conectar el horno de microondas el contacto echa chispas. Necesito cambiarlo y que revisen la línea.',
          urg: 'today',
          ago: 'hace 3 días',
          contact: 'chat',
          loc: const GeoPoint(20.0547, -99.3434),
          mine: true,
          interested: ['p2', 'p7'],
          pick: 'p2',
          closed: true,
          orderId: 'ma2'),
    ];

class FExp {
  const FExp(this.p, this.user, this.text, this.rec, this.stars, this.ago);
  final String p;
  final String user;
  final String text;
  final bool rec;
  final int stars;
  final String ago;
}

List<FExp> seedExps() => [
      const FExp(
          'p1',
          'Laura G.',
          'Llegó a la hora acordada y me explicó qué había fallado antes de empezar a trabajar.',
          true,
          5,
          'hace 1 semana'),
      const FExp('p1', 'Ricardo S.', 'Resolvió la fuga el mismo día. El precio final fue el que habíamos hablado.',
          true, 5, 'hace 2 semanas'),
      const FExp(
          'p2', 'Teresa P.', 'Trabajo limpio y ordenado. Dejó el centro de carga etiquetado.', true, 5, 'hace 5 días'),
      const FExp('p3', 'Héctor M.', 'Tardó más de lo acordado, pero el closet quedó bien terminado.', true, 4,
          'hace 3 semanas'),
    ];

/// Respuestas automáticas del prototipo (`replyFor`).
const fakeReplies = [
  '¡Hola! Claro, con gusto te ayudo. ¿Me compartes una foto para darte un precio?',
  'Puedo pasar mañana por la mañana. ¿Te queda bien?',
  'Perfecto, quedamos así. Cualquier cosa me escribes por aquí.',
];
