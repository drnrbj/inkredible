import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'data.dart';
import 'widgets.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int tab = 0;
  static const titles = ['INKREDIBLE', 'ORDERS', 'SERVICES', 'ANALYTICS'];
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: ShopAppBar(title: titles[tab]),
        body: IndexedStack(index: tab, children: const [
          OverviewTab(),
          OrdersTab(),
          ServicesTab(),
          AnalyticsTab(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined), label: 'Today'),
            NavigationDestination(
                icon: Icon(Icons.inbox_outlined), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.tune), label: 'Services'),
            NavigationDestination(
                icon: Icon(Icons.bar_chart), label: 'Analytics'),
          ],
        ),
      );
}

// ---------------------------------------------------------------- OVERVIEW
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<ShopStore>();
    Widget tile(String label, String value, {bool dark = false}) => AppCard(
          dark: dark,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : Colors.black)),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: dark ? Colors.white70 : Colors.black54)),
              ]),
        );
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text(DateFormat('EEEE, MMM d').format(DateTime.now()),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(
          s.shopOpen
              ? 'Shop is open'
              : (s.acceptingOrders
                  ? 'Outside opening hours'
                  : 'New orders paused'),
          style: const TextStyle(color: Colors.black54)),
      const SizedBox(height: 16),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          tile('New (Pending)', '${s.count(OrderStatus.pending)}', dark: true),
          tile('Accepted', '${s.count(OrderStatus.accepted)}'),
          tile('Ready for pickup', '${s.count(OrderStatus.ready)}'),
          tile('Completed today', '${s.completedToday}'),
          tile("Today's sales", peso(s.todaySales)),
          tile('Rejected today', '${s.rejectedToday}'),
        ],
      ),
      const SizedBox(height: 24),
      const SectionTitle('Sales · last 7 days'),
      AppCard(child: SizedBox(height: 180, child: SalesChart(s.sales(0)))),
    ]);
  }
}

// ---------------------------------------------------------------- ORDERS QUEUE
class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});
  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  static const filters = [
    OrderStatus.pending,
    OrderStatus.accepted,
    OrderStatus.ready,
    OrderStatus.done,
    OrderStatus.rejected,
  ];
  int sel = 0; // 0 = all active
  bool newest = true;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ShopStore>();
    final list = s.orders
        .where((o) => sel == 0 ? o.isActive : o.status == filters[sel - 1])
        .toList()
      ..sort((a, b) => newest
          ? b.createdAt.compareTo(a.createdAt)
          : a.pickup.compareTo(b.pickup));
    final labels = ['Active', ...filters.map((f) => f.label)];

    return Column(children: [
      SizedBox(
        height: 52,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          scrollDirection: Axis.horizontal,
          itemCount: labels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => ChoiceChip(
            label: Text(labels[i],
                style:
                    TextStyle(color: sel == i ? Colors.white : Colors.black)),
            selected: sel == i,
            onSelected: (_) => setState(() => sel = i),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        child: Row(children: [
          Text('${list.length} orders',
              style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: true, label: Text('Newest')),
              ButtonSegment(value: false, label: Text('Deadline')),
            ],
            selected: {newest},
            onSelectionChanged: (v) => setState(() => newest = v.first),
          ),
        ]),
      ),
      Expanded(
        child: list.isEmpty
            ? const Center(child: Text('No orders here'))
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _QueueCard(list[i]),
              ),
      ),
    ]);
  }
}

class _QueueCard extends StatelessWidget {
  final Order o;
  const _QueueCard(this.o);
  @override
  Widget build(BuildContext context) {
    final s = context.read<ShopStore>();
    final next = o.status.next;
    return AppCard(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => OrderDetailPage(o))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('#${o.id}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(o.customer,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          StatusChip(o.status),
        ]),
        const SizedBox(height: 6),
        Text(o.fileName, overflow: TextOverflow.ellipsis),
        Text('${o.totalPages} pages • ${o.spec.summary}',
            style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 8),
        Row(children: [
          Text(peso(o.price),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          Text(
              'Received ${ago(o.createdAt)} • Due ${DateFormat('h:mm a').format(o.pickup)}',
              style: const TextStyle(color: Colors.black54, fontSize: 11)),
        ]),
        if (o.status == OrderStatus.pending) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: FilledButton(
                    style: compact,
                    onPressed: () => s.setStatus(o, OrderStatus.accepted),
                    child: const Text('Accept'))),
            const SizedBox(width: 8),
            Expanded(
                child: OutlinedButton(
                    style: compact,
                    onPressed: () => rejectDialog(context, s, o),
                    child: const Text('Reject'))),
          ]),
        ] else if (next != null) ...[
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  style: compact,
                  onPressed: () => s.setStatus(o, next),
                  child: Text('Mark ${next.label}'))),
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------------- ORDER DETAIL
class OrderDetailPage extends StatefulWidget {
  final Order order;
  const OrderDetailPage(this.order, {super.key});
  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final TextEditingController note =
      TextEditingController(text: widget.order.internalNotes);
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ShopStore>();
    final o = widget.order;
    return Scaffold(
      appBar: AppBar(title: Text('Order #${o.id}')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        AppCard(
          child: Row(children: [
            const Icon(Icons.picture_as_pdf_outlined, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.fileName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                        '${o.totalPages} pages · ${(o.sizeKb / 1024).toStringAsFixed(1)} MB',
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12)),
                  ]),
            ),
            OutlinedButton(
              style: compact,
              // TODO: open the Firebase Storage download URL (url_launcher).
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Connect Firebase Storage to open the file'))),
              child: const Text('Open'),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Print specification'),
        AppCard(
          child: Column(children: [
            KV('Paper', o.spec.paper),
            KV('Color', o.spec.color ? 'Color' : 'Black & White'),
            KV('Sides', o.spec.duplex ? 'Double-sided' : 'Single-sided'),
            KV('Copies', '${o.spec.copies}'),
            KV('Finish', o.spec.finish),
            KV('Total', peso(o.price)),
            KV('Customer note', o.notes.isEmpty ? '—' : o.notes),
          ]),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Customer'),
        AppCard(
          child: Column(children: [
            KV('Name', o.customer),
            KV('Phone', o.phone),
            KV('Received', DateFormat('MMM d, h:mm a').format(o.createdAt)),
          ]),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Status'),
        if (o.status == OrderStatus.rejected)
          AppCard(child: KV('Rejected', o.rejectReason ?? ''))
        else ...[
          InputDecorator(
            decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<OrderStatus>(
                isExpanded: true,
                dropdownColor: Colors.white,
                value: o.status,
                items: [
                  for (final st in OrderStatus.flow)
                    DropdownMenuItem(value: st, child: Text(st.label))
                ],
                onChanged: (v) {
                  if (v != null) s.setStatus(o, v);
                },
              ),
            ),
          ),
          if (o.status == OrderStatus.pending) ...[
            const SizedBox(height: 10),
            OutlinedButton(
                onPressed: () => rejectDialog(context, s, o),
                child: const Text('Reject order')),
          ],
        ],
        const SizedBox(height: 20),
        const SectionTitle('Internal notes'),
        TextField(
          controller: note,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Only visible to staff'),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () {
            s.saveNote(o, note.text.trim());
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Note saved')));
          },
          child: const Text('Save note'),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- SERVICES
class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});

  Future<void> _edit(BuildContext context, ShopStore s, [Service? svc]) async {
    final name = TextEditingController(text: svc?.name ?? '');
    final price = TextEditingController(text: svc?.price.toString() ?? '');
    String cat = svc?.category ?? 'finish';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dc) => StatefulBuilder(
        builder: (dc, setD) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(svc == null ? 'Add service' : 'Edit service'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            if (svc == null)
              InputDecorator(
                decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    value: cat,
                    items: const [
                      DropdownMenuItem(
                          value: 'paper', child: Text('Paper size (per page)')),
                      DropdownMenuItem(
                          value: 'color', child: Text('Color mode (per page)')),
                      DropdownMenuItem(
                          value: 'finish',
                          child: Text('Binding / lamination (per copy)')),
                    ],
                    onChanged: (v) => setD(() => cat = v ?? cat),
                  ),
                ),
              ),
            if (svc == null) const SizedBox(height: 12),
            TextField(
              controller: price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (₱)'),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dc, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.black))),
            FilledButton(
                style: compact,
                onPressed: () => Navigator.pop(dc, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final p = double.tryParse(price.text) ?? 0;
    if (svc == null) {
      s.addService(Service(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name.text.trim(),
          category: cat,
          price: p));
    } else {
      svc.name = name.text.trim();
      svc.price = p;
      s.touch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ShopStore>();
    const sections = {
      'paper': 'Paper sizes · surcharge per page',
      'color': 'Color vs. B&W · rate per page',
      'finish': 'Binding & lamination · flat fee per copy',
    };
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () => _edit(context, s),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            AppCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Accept new orders',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle:
                    const Text('Turn off when the shop is busy or closed'),
                value: s.acceptingOrders,
                onChanged: s.setAccepting,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                  'Price = pages × copies × (paper + color rate) − 10% if double-sided, plus finish fee × copies.',
                  style: TextStyle(color: Colors.black54, fontSize: 12)),
            ),
            for (final e in sections.entries) ...[
              const SizedBox(height: 12),
              SectionTitle(e.value),
              for (final svc in s.services.where((x) => x.category == e.key))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(svc.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: svc.enabled
                                          ? Colors.black
                                          : Colors.black38)),
                              Text('${peso(svc.price)} ${svc.unit}',
                                  style: const TextStyle(
                                      color: Colors.black54, fontSize: 12)),
                            ]),
                      ),
                      IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _edit(context, s, svc)),
                      Switch(
                          value: svc.enabled,
                          onChanged: (v) {
                            svc.enabled = v;
                            s.touch();
                          }),
                    ]),
                  ),
                ),
            ],
          ]),
    );
  }
}

// ---------------------------------------------------------------- ANALYTICS
class SalesChart extends StatelessWidget {
  final List<(String, double)> data;
  const SalesChart(this.data, {super.key});
  @override
  Widget build(BuildContext context) {
    const hidden = AxisTitles(sideTitles: SideTitles(showTitles: false));
    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: hidden,
        rightTitles: hidden,
        topTitles: hidden,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (v, m) {
              final i = v.toInt();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(i >= 0 && i < data.length ? data[i].$1 : '',
                    style: const TextStyle(fontSize: 10)),
              );
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
              peso(rod.toY),
              const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
      barGroups: [
        for (var i = 0; i < data.length; i++)
          BarChartGroupData(x: i, barRods: [
            BarChartRodData(
                toY: data[i].$2,
                color: Colors.black,
                width: data.length > 6 ? 14 : 22,
                borderRadius: BorderRadius.circular(4)),
          ]),
      ],
    ));
  }
}

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});
  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  int period = 0;

  static String _hour(int h) =>
      h == 0 ? '12a' : (h < 12 ? '${h}a' : (h == 12 ? '12p' : '${h - 12}p'));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ShopStore>();
    final sales = s.sales(period);
    final total = sales.fold(0.0, (a, e) => a + e.$2);
    final hourly = s.hourly;
    final popular = s.popular;
    final maxPop = popular.isEmpty ? 1 : popular.first.value;
    final done = s.completedTotal, cancelled = s.cancelledTotal;

    const hidden = AxisTitles(sideTitles: SideTitles(showTitles: false));
    return ListView(padding: const EdgeInsets.all(20), children: [
      SegmentedButton<int>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: 0, label: Text('Daily')),
          ButtonSegment(value: 1, label: Text('Weekly')),
          ButtonSegment(value: 2, label: Text('Monthly')),
        ],
        selected: {period},
        onSelectionChanged: (v) => setState(() => period = v.first),
      ),
      const SizedBox(height: 20),
      SectionTitle('Sales',
          trailing: Text(peso(total),
              style: const TextStyle(fontWeight: FontWeight.w800))),
      AppCard(child: SizedBox(height: 200, child: SalesChart(sales))),
      const SizedBox(height: 28),
      const SectionTitle('Busy hours (orders received)'),
      AppCard(
        child: SizedBox(
          height: 170,
          child: LineChart(LineChartData(
            minX: 8,
            maxX: 19,
            minY: 0,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: hidden,
              rightTitles: hidden,
              topTitles: hidden,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 2,
                  reservedSize: 26,
                  getTitlesWidget: (v, m) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_hour(v.toInt()),
                          style: const TextStyle(fontSize: 10))),
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var h = 8; h <= 19; h++)
                    FlSpot(h.toDouble(), hourly[h].toDouble())
                ],
                isCurved: true,
                color: Colors.black,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: Colors.black12),
              ),
            ],
          )),
        ),
      ),
      const SizedBox(height: 28),
      const SectionTitle('Most popular services'),
      AppCard(
        child: Column(children: [
          for (final e in popular)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                SizedBox(width: 90, child: Text(e.key)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        value: e.value / maxPop,
                        minHeight: 10,
                        color: Colors.black,
                        backgroundColor: Colors.black12),
                  ),
                ),
                SizedBox(
                    width: 36,
                    child: Text('${e.value}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w700))),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 28),
      const SectionTitle('Completed vs. cancelled'),
      AppCard(
        child: Row(children: [
          SizedBox(
            width: 130,
            height: 130,
            child: PieChart(PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: [
                PieChartSectionData(
                    value: done.toDouble(),
                    color: Colors.black,
                    radius: 28,
                    title: '$done',
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                PieChartSectionData(
                    value: cancelled.toDouble(),
                    color: Colors.black26,
                    radius: 28,
                    title: '$cancelled',
                    titleStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ],
            )),
          ),
          const SizedBox(width: 20),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 12, height: 12, color: Colors.black),
                const SizedBox(width: 8),
                Text('Completed  $done'),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Container(width: 12, height: 12, color: Colors.black26),
                const SizedBox(width: 8),
                Text('Cancelled  $cancelled'),
              ]),
              const SizedBox(height: 8),
              Text(
                  '${done + cancelled == 0 ? 0 : (done * 100 / (done + cancelled)).round()}% completion rate',
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 28),
      const SectionTitle('Top customers'),
      AppCard(
        child: Column(children: [
          for (var i = 0; i < s.topCustomers.length; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black,
                  child: Text('${i + 1}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12))),
              title: Text(s.topCustomers[i].key),
              trailing: Text(peso(s.topCustomers[i].value),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ]),
      ),
    ]);
  }
}
