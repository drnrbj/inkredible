import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

enum Role { customer, admin }

class Session extends ChangeNotifier {
  Role? role;
  void set(Role? r) {
    role = r;
    notifyListeners();
  }
}

enum OrderStatus {
  pending('Pending'),
  accepted('Accepted'),
  ready('Ready'),
  done('Done'),
  rejected('Rejected');

  final String label;
  const OrderStatus(this.label);
  static const flow = [pending, accepted, ready, done];
  OrderStatus? get next {
    final i = flow.indexOf(this);
    return (i >= 0 && i < flow.length - 1) ? flow[i + 1] : null;
  }
}

class PrintSpec {
  String paper;
  bool color;
  bool duplex;
  int copies;
  String finish;
  PrintSpec({
    this.paper = 'A4',
    this.color = false,
    this.duplex = false,
    this.copies = 1,
    this.finish = 'None',
  });
  PrintSpec copy() => PrintSpec(
      paper: paper,
      color: color,
      duplex: duplex,
      copies: copies,
      finish: finish);
  String get summary =>
      '$paper • ${color ? 'Color' : 'B&W'} • ${duplex ? '2-sided' : '1-sided'} • '
      '$copies ${copies == 1 ? 'copy' : 'copies'}'
      '${finish == 'None' ? '' : ' • $finish'}';
}

class OrderFile {
  final String name;
  final int sizeKb;
  final int totalPages;
  const OrderFile(
      {required this.name, required this.sizeKb, required this.totalPages});
}

class Order {
  final String id, customer, phone;
  final List<OrderFile> files;
  final PrintSpec spec;
  final double price;
  final bool printAll;
  final String? pageRange;
  OrderStatus status;
  final DateTime createdAt;
  DateTime pickup;
  String notes, internalNotes;
  String? rejectReason;
  Order({
    required this.id,
    required this.customer,
    required this.phone,
    required this.files,
    required this.spec,
    required this.price,
    required this.printAll,
    this.pageRange,
    required this.status,
    required this.createdAt,
    required this.pickup,
    this.notes = '',
    this.internalNotes = '',
    this.rejectReason,
  });
  bool get isActive =>
      status != OrderStatus.done && status != OrderStatus.rejected;
  String get fileName =>
      files.length == 1 ? files.first.name : '${files.length} files';
  int get totalPages => files.fold(0, (a, f) => a + f.totalPages);
  int get sizeKb => files.fold(0, (a, f) => a + f.sizeKb);
}

class AppNotification {
  final String id, title, body;
  final DateTime time;
  final String? orderId;
  final OrderStatus? status;
  bool read;
  AppNotification({
    required this.id,
    required this.title,
    this.body = '',
    required this.time,
    this.orderId,
    this.status,
    this.read = false,
  });
}

/// category: 'paper' (per page), 'color' (per page), 'finish' (per copy)
class Service {
  final String id;
  String name, category;
  double price;
  bool enabled;
  Service(
      {required this.id,
      required this.name,
      required this.category,
      required this.price,
      this.enabled = true});
  String get unit => category == 'finish' ? 'per copy' : 'per page';
}

class ShopStore extends ChangeNotifier {
  String customerName = 'Customer';
  static const hoursText = 'Mon–Sat · 8:00 AM – 7:00 PM';
  static const maxFileMb = 20;

  bool acceptingOrders = true;
  final orders = <Order>[];
  final notifications = <AppNotification>[];
  int get unread => notifications.where((n) => !n.read).length;
  int _seq = 1049;

  void setCustomerName(String name) {
    final n = name.trim();
    if (n.isEmpty || n == customerName) return;
    customerName = n;
    notifyListeners();
  }

  final services = <Service>[
    Service(id: 'p1', name: 'A4', category: 'paper', price: 1.0),
    Service(id: 'p2', name: 'Short', category: 'paper', price: 1.0),
    Service(id: 'p3', name: 'Legal', category: 'paper', price: 1.5),
    Service(id: 'p4', name: 'A3', category: 'paper', price: 4.0),
    Service(id: 'c1', name: 'B&W', category: 'color', price: 2.0),
    Service(id: 'c2', name: 'Color', category: 'color', price: 8.0),
    Service(id: 'f1', name: 'None', category: 'finish', price: 0),
    Service(id: 'f2', name: 'Staple', category: 'finish', price: 5),
    Service(id: 'f3', name: 'Spiral', category: 'finish', price: 45),
    Service(id: 'f4', name: 'Lamination', category: 'finish', price: 30),
  ];

  ShopStore() {
    _seed();
  }

  // ---------- shop state ----------
  bool get withinHours {
    final n = DateTime.now();
    return n.weekday != DateTime.sunday && n.hour >= 8 && n.hour < 19;
  }

  bool get shopOpen => acceptingOrders && withinHours;

  void touch() => notifyListeners();

  void setAccepting(bool v) {
    acceptingOrders = v;
    notifyListeners();
  }

  // ---------- pricing ----------
  List<String> options(String cat) => services
      .where((s) => s.category == cat && s.enabled)
      .map((s) => s.name)
      .toList();

  double _rate(String cat, String name) {
    for (final s in services) {
      if (s.category == cat && s.name == name) return s.price;
    }
    return 0;
  }

  /// Double-sided gets a flat 10% off the per-page total.
  double price(PrintSpec s, int pages) {
    final perPage =
        _rate('paper', s.paper) + _rate('color', s.color ? 'Color' : 'B&W');
    final sheets = pages * s.copies * perPage * (s.duplex ? 0.9 : 1.0);
    return sheets + _rate('finish', s.finish) * s.copies;
  }

  // ---------- orders ----------
  List<Order> get myOrders =>
      orders.where((o) => o.customer == customerName).toList();

  Order placeOrder({
    required List<OrderFile> files,
    required PrintSpec spec,
    required bool printAll,
    String? pageRange,
    required String notes,
  }) {
    final now = DateTime.now();
    final total = files.fold(0.0, (a, f) => a + price(spec, f.totalPages));
    final o = Order(
      id: '${++_seq}',
      customer: customerName,
      phone: '0917 123 4567',
      files: files,
      spec: spec,
      price: total,
      printAll: printAll,
      pageRange: printAll ? null : pageRange,
      status: OrderStatus.pending,
      createdAt: now,
      pickup: now.add(const Duration(hours: 2)),
      notes: notes,
    );
    orders.insert(0, o);
    _push('New order #${o.id} from ${o.customer}');
    notifyListeners();
    return o;
  }

  void setStatus(Order o, OrderStatus s) {
    o.status = s;
    _push(
      s == OrderStatus.ready
          ? 'Order #${o.id} is ready for pickup'
          : 'Order #${o.id} is now ${s.label}',
      body: s == OrderStatus.ready
          ? 'Show your order number at the counter.'
          : o.fileName,
      order: o,
    );
    notifyListeners();
  }

  void reject(Order o, String reason) {
    o.status = OrderStatus.rejected;
    o.rejectReason = reason;
    _push('Order #${o.id} was rejected', body: reason, order: o);
    notifyListeners();
  }

  void saveNote(Order o, String n) {
    o.internalNotes = n;
    notifyListeners();
  }

  void addService(Service s) {
    services.add(s);
    notifyListeners();
  }

  void _push(String title, {String body = '', Order? order}) {
    notifications.insert(
      0,
      AppNotification(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        body: body,
        time: DateTime.now(),
        orderId: order?.id,
        status: order?.status,
      ),
    );
  }

  void markRead() {
    if (unread == 0) return;
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  void removeNotification(AppNotification n) {
    notifications.remove(n);
    notifyListeners();
  }

  void clearNotifications() {
    notifications.clear();
    notifyListeners();
  }

  // ---------- analytics ----------
  Iterable<Order> get _done =>
      orders.where((o) => o.status == OrderStatus.done);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int count(OrderStatus s) => orders.where((o) => o.status == s).length;

  double get todaySales => _done
      .where((o) => sameDay(o.createdAt, DateTime.now()))
      .fold(0.0, (a, o) => a + o.price);

  int get completedToday =>
      _done.where((o) => sameDay(o.createdAt, DateTime.now())).length;

  int get rejectedToday => orders
      .where((o) =>
          o.status == OrderStatus.rejected &&
          sameDay(o.createdAt, DateTime.now()))
      .length;

  int get completedTotal => _done.length;
  int get cancelledTotal => count(OrderStatus.rejected);

  (String, double) _bucket(String label, bool Function(DateTime) test) => (
        label,
        _done.where((o) => test(o.createdAt)).fold(0.0, (a, o) => a + o.price)
      );

  /// period: 0 = daily (7d), 1 = weekly (4w), 2 = monthly (6m)
  List<(String, double)> sales(int period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (period == 0) {
      return [
        for (var i = 6; i >= 0; i--)
          _bucket(DateFormat.E().format(today.subtract(Duration(days: i))),
              (t) => sameDay(t, today.subtract(Duration(days: i))))
      ];
    }
    if (period == 1) {
      return [
        for (var i = 3; i >= 0; i--)
          _bucket(
              DateFormat('MMM d')
                  .format(today.subtract(Duration(days: 7 * i + 6))), (t) {
            final d = DateTime(t.year, t.month, t.day);
            final end = today.subtract(Duration(days: 7 * i));
            final start = end.subtract(const Duration(days: 6));
            return !d.isBefore(start) && !d.isAfter(end);
          })
      ];
    }
    return [
      for (var i = 5; i >= 0; i--)
        _bucket(DateFormat.MMM().format(DateTime(now.year, now.month - i)),
            (t) {
          final m = DateTime(now.year, now.month - i);
          return t.year == m.year && t.month == m.month;
        })
    ];
  }

  List<int> get hourly {
    final h = List<int>.filled(24, 0);
    for (final o in orders) {
      if (o.status != OrderStatus.rejected) h[o.createdAt.hour]++;
    }
    return h;
  }

  List<MapEntry<String, int>> get popular {
    final m = <String, int>{};
    for (final o in _done) {
      void add(String k) => m[k] = (m[k] ?? 0) + 1;
      add(o.spec.paper);
      add(o.spec.color ? 'Color' : 'B&W');
      if (o.spec.finish != 'None') add(o.spec.finish);
    }
    final l = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return l.take(6).toList();
  }

  List<MapEntry<String, double>> get topCustomers {
    final m = <String, double>{};
    for (final o in _done) {
      m[o.customer] = (m[o.customer] ?? 0) + o.price;
    }
    final l = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return l.take(5).toList();
  }

  // ---------- sample data ----------
  void _add(String id, String cust, String file, int pages, PrintSpec spec,
      OrderStatus st, int minsAgo) {
    final t = DateTime.now().subtract(Duration(minutes: minsAgo));
    orders.add(Order(
      id: id,
      customer: cust,
      phone: '09${17 + id.hashCode % 8} 555 ${1000 + id.hashCode.abs() % 9000}',
      files: [OrderFile(name: file, sizeKb: pages * 60, totalPages: pages)],
      spec: spec,
      price: price(spec, pages),
      printAll: true,
      status: st,
      createdAt: t,
      pickup: t.add(const Duration(hours: 2)),
    ));
  }

  void _seed() {
    _add(
        '1041',
        'Jay',
        'Thesis_Draft_v3.pdf',
        48,
        PrintSpec(duplex: true, copies: 2, finish: 'Spiral'),
        OrderStatus.accepted,
        90);
    _add('1042', 'Jay', 'Assignment_4.pdf', 12, PrintSpec(paper: 'Short'),
        OrderStatus.ready, 200);
    _add('1043', 'Jay', 'Flyer_Promo.pdf', 2,
        PrintSpec(color: true, copies: 20), OrderStatus.pending, 10);
    _add(
        '1044',
        'Maria Santos',
        'Contract_Final.pdf',
        8,
        PrintSpec(paper: 'Legal', copies: 3, finish: 'Staple'),
        OrderStatus.pending,
        25);
    _add('1045', 'Carlo Reyes', 'Research_Paper.pdf', 30,
        PrintSpec(duplex: true), OrderStatus.accepted, 60);
    _add(
        '1046',
        'Ana Dizon',
        'Presentation.pdf',
        20,
        PrintSpec(color: true, finish: 'Lamination'),
        OrderStatus.accepted,
        120);
    _add('1047', 'Paolo Cruz', 'Receipts_Q3.pdf', 5, PrintSpec(),
        OrderStatus.ready, 240);
    _add('1048', 'Liza Tan', 'Assignment_2.pdf', 10, PrintSpec(copies: 2),
        OrderStatus.done, 300);
    _add('1049', 'Miguel Ramos', 'Poster_Draft.pdf', 1,
        PrintSpec(paper: 'A3', color: true), OrderStatus.done, 330);

    final r = Random(7);
    const names = [
      'Maria Santos',
      'Carlo Reyes',
      'Ana Dizon',
      'Paolo Cruz',
      'Liza Tan',
      'Miguel Ramos',
      'Jay'
    ];
    const files = [
      'Thesis_Draft.pdf',
      'Research_Paper.pdf',
      'Contract.pdf',
      'Flyer.pdf',
      'Assignment.pdf',
      'Receipts.pdf',
      'Slides.pdf'
    ];
    const papers = ['A4', 'Short', 'Legal'];
    const finishes = ['None', 'None', 'Staple', 'Spiral', 'Lamination'];
    final now = DateTime.now();
    for (var i = 0; i < 110; i++) {
      final hour = r.nextBool() ? 10 + r.nextInt(6) : 8 + r.nextInt(11);
      final spec = PrintSpec(
        paper: papers[r.nextInt(3)],
        color: r.nextInt(4) == 0,
        duplex: r.nextBool(),
        copies: 1 + r.nextInt(3),
        finish: finishes[r.nextInt(5)],
      );
      final pages = 2 + r.nextInt(60);
      final file = files[r.nextInt(files.length)];
      final t = DateTime(now.year, now.month, now.day - (1 + r.nextInt(180)),
          hour, r.nextInt(60));
      final rejected = r.nextInt(10) == 0;
      orders.add(Order(
        id: '${900 + i}',
        customer: names[r.nextInt(names.length)],
        phone: '0917 555 ${1000 + r.nextInt(9000)}',
        files: [OrderFile(name: file, sizeKb: pages * 60, totalPages: pages)],
        spec: spec,
        price: price(spec, pages),
        printAll: true,
        status: rejected ? OrderStatus.rejected : OrderStatus.done,
        createdAt: t,
        pickup: t.add(const Duration(hours: 2)),
        rejectReason: rejected ? 'File unreadable' : null,
      ));
    }
    final n = DateTime.now();
    notifications.addAll([
      AppNotification(
        id: 's1',
        title: 'Order #1042 is ready for pickup',
        body: 'Show your order number at the counter.',
        time: n.subtract(const Duration(minutes: 8)),
        orderId: '1042',
        status: OrderStatus.ready,
      ),
      AppNotification(
        id: 's2',
        title: 'Order #1041 is now Printing',
        body: 'Thesis_Draft_v3.pdf',
        time: n.subtract(const Duration(minutes: 40)),
        orderId: '1041',
        status: OrderStatus.accepted,
      ),
      AppNotification(
        id: 's3',
        title: 'Order #1048 is now Completed',
        body: 'Assignment_2.pdf',
        time: n.subtract(const Duration(days: 1, hours: 2)),
        orderId: '1048',
        status: OrderStatus.done,
        read: true,
      ),
    ]);
  }
}
