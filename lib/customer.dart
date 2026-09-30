import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'data.dart';
import 'widgets.dart';
import 'customer_services.dart';
import 'profile_page.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const ShopAppBar(),
        body:
            IndexedStack(index: tab, children: const [HomeTab(), HistoryTab()]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          ],
        ),
      );
}

// ---------------------------------------------------------------- HOME
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ShopStore>();
    final mine = s.myOrders;
    final active = mine.where((o) => o.isActive).toList()
      ..sort((a, b) {
        if ((a.status == OrderStatus.ready) !=
            (b.status == OrderStatus.ready)) {
          return a.status == OrderStatus.ready ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    final inProgress =
        active.where((o) => o.status != OrderStatus.ready).length;
    final ready = active.where((o) => o.status == OrderStatus.ready).length;
    final h = DateTime.now().hour;
    final greeting =
        h < 12 ? 'Good morning' : (h < 18 ? 'Good afternoon' : 'Good evening');
    final parts = [
      if (inProgress > 0) '$inProgress in progress',
      if (ready > 0) '$ready ready for pickup',
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('$greeting, ${s.customerName}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(parts.isEmpty ? 'No active orders' : parts.join(', '),
            style: const TextStyle(color: Colors.black54, fontSize: 15)),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 60)),
          onPressed: s.acceptingOrders
              ? () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NewOrderPage()))
              : null,
          icon: const Icon(Icons.add),
          label: const Text('New Order',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ),
        if (!s.acceptingOrders)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
                'The shop has paused new orders. Please check back soon.',
                style: TextStyle(color: Colors.black54)),
          ),
        const SizedBox(height: 16),
        AppCard(
          child: Row(children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.shopOpen ? Colors.black : Colors.white,
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        s.shopOpen
                            ? 'Open now'
                            : (s.acceptingOrders ? 'Closed' : 'Orders paused'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Text(ShopStore.hoursText,
                        style: TextStyle(color: Colors.black54, fontSize: 13)),
                  ]),
            ),
            const Icon(Icons.storefront_outlined),
          ]),
        ),
        const SizedBox(height: 28),
        const SectionTitle('Active orders'),
        if (active.isEmpty)
          const AppCard(
              child: Center(
                  child: Padding(
            padding: EdgeInsets.all(12),
            child: Text('Nothing in progress. Start a new order!',
                style: TextStyle(color: Colors.black54)),
          )))
        else
          for (final o in active)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActiveOrderCard(o)),
      ],
    );
  }
}

class ActiveOrderCard extends StatelessWidget {
  final Order o;
  const ActiveOrderCard(this.o, {super.key});
  @override
  Widget build(BuildContext context) {
    final ready = o.status == OrderStatus.ready;
    final fg = ready ? Colors.white : Colors.black;
    final sub = ready ? Colors.white70 : Colors.black54;
    return AppCard(
      dark: ready,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (ready)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text('READY FOR PICKUP',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontSize: 12)),
            ]),
          ),
        Row(children: [
          Text('#${o.id}',
              style: TextStyle(
                  color: fg, fontWeight: FontWeight.w800, fontSize: 16)),
          const Spacer(),
          Text(ago(o.createdAt), style: TextStyle(color: sub, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.picture_as_pdf_outlined, size: 18, color: sub),
          const SizedBox(width: 6),
          Expanded(
              child: Text(o.fileName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg))),
        ]),
        const SizedBox(height: 2),
        Text(o.spec.summary, style: TextStyle(color: sub, fontSize: 12)),
        const SizedBox(height: 16),
        StatusStepper(o.status, inverted: ready),
        const SizedBox(height: 14),
        Row(children: [
          Text(peso(o.price),
              style: TextStyle(
                  color: fg, fontWeight: FontWeight.w800, fontSize: 18)),
          const Spacer(),
          Text(
              ready
                  ? 'Show #${o.id} at the counter'
                  : 'Est. pickup ${DateFormat('h:mm a').format(o.pickup)}',
              style: TextStyle(color: sub, fontSize: 12)),
        ]),
      ]),
    );
  }
}

// ---------------------------------------------------------------- HISTORY
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});
  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ShopStore>();
    final allPast = s.myOrders.where((o) => !o.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (allPast.isEmpty) return const Center(child: Text('No past orders yet'));

    final past = switch (filter) {
      'Done' => allPast.where((o) => o.status == OrderStatus.done).toList(),
      'Rejected' => allPast.where((o) => o.status == OrderStatus.rejected).toList(),
      _ => allPast,
    };
    final totalSpent = allPast
        .where((o) => o.status == OrderStatus.done)
        .fold(0.0, (a, o) => a + o.price);

    final groups = <String, List<Order>>{};
    for (final o in past) {
      groups.putIfAbsent(DateFormat('MMMM y').format(o.createdAt), () => []).add(o);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        AppCard(
          dark: true,
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total spent', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(peso(totalSpent),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
            ),
            Container(width: 1, height: 34, color: Colors.white24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Orders', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('${allPast.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final f in const ['All', 'Done', 'Rejected'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: filter == f,
                  onSelected: (_) => setState(() => filter = f),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 20),
        if (past.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: Text('No orders in this filter', style: TextStyle(color: Colors.black54))),
          ),
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Text(entry.key,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black54)),
          ),
          for (final o in entry.value)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: _HistoryCard(o)),
        ],
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Order o;
  const _HistoryCard(this.o);
  @override
  Widget build(BuildContext context) {
    final s = context.read<ShopStore>();
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: Colors.black.withOpacity(.05), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.picture_as_pdf_outlined, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(o.fileName, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            const SizedBox(height: 2),
            Text('#${o.id} · ${DateFormat('MMM d').format(o.createdAt)} · ${o.spec.summary}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54, fontSize: 11.5)),
          ]),
        ),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(peso(o.price), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 4),
          StatusChip(o.status),
        ]),
        IconButton(
          tooltip: 'Reorder',
          visualDensity: VisualDensity.compact,
          onPressed: s.acceptingOrders
              ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewOrderPage(from: o)))
              : null,
          icon: const Icon(Icons.replay),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- NEW ORDER
class NewOrderPage extends StatefulWidget {
  final Order? from;
  final PrintSpec? presetSpec;
  final String? presetLabel;
  const NewOrderPage({super.key, this.from, this.presetSpec, this.presetLabel});
  @override
  State<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends State<NewOrderPage> {
  String? fileName;
  int sizeKb = 0, pages = 1;
  String? error;
  late PrintSpec spec;
  final notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final f = widget.from;
    spec = f?.spec.copy() ?? widget.presetSpec?.copy() ?? PrintSpec();
    if (f != null) {
      fileName = f.fileName;
      sizeKb = f.sizeKb;
      pages = f.pages;
      notes.text = f.notes;
    }
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (f == null) return;

    final fileSize = f.lengthSync() ?? await f.length() ?? 0;

    if (fileSize > ShopStore.maxFileMb * 1024 * 1024) {
      setState(() =>
          error = 'File is ${(fileSize / 1048576).toStringAsFixed(1)} MB. '
              'Max is ${ShopStore.maxFileMb} MB.');
      return;
    }

    setState(() {
      error = null;
      fileName = f.name;
      sizeKb = max(1, (fileSize / 1024).ceil());

      // Rough guess; the customer can correct it.
      pages = max(1, min(500, (sizeKb / 60).round()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ShopStore>();
    final total = s.price(spec, pages);
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.from == null
              ? 'New order'
              : 'Reorder #${widget.from!.id}')),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.black12))),
          child: Row(children: [
            Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimated total',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Text(peso(total),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                ]),
            const SizedBox(width: 20),
            Expanded(
              child: FilledButton(
                onPressed: fileName == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ConfirmPage(
                                fileName: fileName!,
                                sizeKb: sizeKb,
                                pages: pages,
                                spec: spec.copy(),
                                notes: notes.text.trim()))),
                child: const Text('Review order'),
              ),
            ),
          ]),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const SectionTitle('1. Document'),
        AppCard(
          onTap: pick,
          child: Row(children: [
            const Icon(Icons.upload_file, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fileName ?? 'Upload a PDF',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                        fileName == null
                            ? 'PDF only · max ${ShopStore.maxFileMb} MB'
                            : '${(sizeKb / 1024).toStringAsFixed(1)} MB · tap to replace',
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12)),
                  ]),
            ),
          ]),
        ),
        if (widget.presetLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              dark: true,
              child: Row(children: [
                const Icon(Icons.bolt, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        'Using "${widget.presetLabel}" — options pre-filled, adjust anytime.',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12.5))),
              ]),
            ),
          ),
        if (error != null)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(height: 24),
        const SectionTitle('2. Print options'),
        _Stepper(
            label: 'Pages (adjust if needed)',
            value: pages,
            min: 1,
            max: 500,
            onChanged: (v) => setState(() => pages = v)),
        const SizedBox(height: 14),
        _Drop(
            label: 'Paper size',
            value: spec.paper,
            items: s.options('paper'),
            onChanged: (v) => setState(() => spec.paper = v)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('Black & White')),
              ButtonSegment(value: true, label: Text('Color')),
            ],
            selected: {spec.color},
            onSelectionChanged: (v) => setState(() => spec.color = v.first),
          ),
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Double-sided'),
          subtitle: const Text('10% off page cost'),
          value: spec.duplex,
          onChanged: (v) => setState(() => spec.duplex = v),
        ),
        _Stepper(
            label: 'Copies',
            value: spec.copies,
            min: 1,
            max: 200,
            onChanged: (v) => setState(() => spec.copies = v)),
        const SizedBox(height: 14),
        _Drop(
            label: 'Binding / lamination',
            value: spec.finish,
            items: s.options('finish'),
            onChanged: (v) => setState(() => spec.finish = v)),
        const SizedBox(height: 24),
        const SectionTitle('3. Notes for the shop'),
        TextField(
          controller: notes,
          maxLines: 3,
          decoration:
              const InputDecoration(hintText: 'e.g. Print pages 1–10 only'),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _Drop extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  const _Drop(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => InputDecorator(
        decoration: InputDecoration(
            labelText: label,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            dropdownColor: Colors.white,
            value: items.contains(value) ? value : null,
            hint: const Text('Unavailable'),
            items: [
              for (final i in items) DropdownMenuItem(value: i, child: Text(i))
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      );
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value, min, max;
  final ValueChanged<int> onChanged;
  const _Stepper(
      {required this.label,
      required this.value,
      required this.min,
      required this.max,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
        IconButton.outlined(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove)),
        SizedBox(
            width: 52,
            child: Center(
                child: Text('$value',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)))),
        IconButton.outlined(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add)),
      ]);
}

// ---------------------------------------------------------------- CONFIRM
class ConfirmPage extends StatelessWidget {
  final String fileName, notes;
  final int sizeKb, pages;
  final PrintSpec spec;
  const ConfirmPage(
      {super.key,
      required this.fileName,
      required this.sizeKb,
      required this.pages,
      required this.spec,
      required this.notes});

  @override
  Widget build(BuildContext context) {
    final s = context.read<ShopStore>();
    final total = s.price(spec, pages);
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm order')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        AppCard(
          child: Column(children: [
            KV('File', fileName),
            KV('Pages', '$pages'),
            KV('Paper', spec.paper),
            KV('Color', spec.color ? 'Color' : 'Black & White'),
            KV('Sides', spec.duplex ? 'Double-sided' : 'Single-sided'),
            KV('Copies', '${spec.copies}'),
            KV('Finish', spec.finish),
            if (notes.isNotEmpty) KV('Notes', notes),
          ]),
        ),
        const SizedBox(height: 16),
        AppCard(
          dark: true,
          child: Row(children: [
            const Text('Total',
                style: TextStyle(color: Colors.white70, fontSize: 15)),
            const Spacer(),
            Text(peso(total),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 8),
        const Text(
            'Pay at pickup. You will be notified when your order is ready.',
            style: TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            final messenger = ScaffoldMessenger.of(context);
            final o = s.placeOrder(
                fileName: fileName,
                sizeKb: sizeKb,
                pages: pages,
                spec: spec,
                notes: notes);
            Navigator.popUntil(context, (r) => r.isFirst);
            messenger.showSnackBar(SnackBar(
                backgroundColor: Colors.black,
                content: Text('Order #${o.id} placed')));
          },
          child: const Text('Place order'),
        ),
      ]),
    );
  }
}
