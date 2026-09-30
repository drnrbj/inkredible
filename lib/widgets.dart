import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_actions.dart';

String peso(double v) => '₱${NumberFormat('#,##0.00').format(v)}';

String ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return DateFormat('MMM d').format(t);
}

const compact = ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, 40)));

class AppCard extends StatelessWidget {
  final Widget child;
  final bool dark;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  const AppCard(
      {super.key,
      required this.child,
      this.dark = false,
      this.onTap,
      this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: dark ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: dark ? Colors.black : Colors.black26),
        ),
        child: InkWell(
            onTap: onTap, child: Padding(padding: padding, child: child)),
      );
}

class ShopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const ShopAppBar({super.key, this.title = 'INKREDIBLE'});
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) {
    final unread = context.watch<ShopStore>().unread;
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            backgroundColor: Colors.black,
            child: const Icon(Icons.notifications_none),
          ),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsPage())),
        ),
        IconButton(
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout),
          onPressed: () => confirmSignOut(context),
        ),
      ],
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Ids that were unread when the page opened, so they stay highlighted
  // during this visit even though we mark everything read right away.
  late final Set<String> _fresh;

  @override
  void initState() {
    super.initState();
    final store = context.read<ShopStore>();
    _fresh = store.notifications.where((n) => !n.read).map((n) => n.id).toSet();
    WidgetsBinding.instance.addPostFrameCallback((_) => store.markRead());
  }

  String _group(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return 'Earlier';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShopStore>();
    final items = store.notifications;

    // Flatten into header strings and notification rows.
    final rows = <Object>[];
    String? last;
    for (final n in items) {
      final g = _group(n.time);
      if (g != last) {
        rows.add(g);
        last = g;
      }
      rows.add(n);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: store.clearNotifications,
              child: const Text('Clear all',
                  style: TextStyle(color: Colors.black)),
            ),
        ],
      ),
      body: items.isEmpty
          ? const _EmptyNotifications()
          : ListView.builder(
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final row = rows[i];
                if (row is String) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(row.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: Colors.black54)),
                  );
                }
                final n = row as AppNotification;
                return Column(children: [
                  _NotificationTile(
                    n: n,
                    fresh: _fresh.contains(n.id),
                    onDismissed: () => store.removeNotification(n),
                  ),
                  const Divider(height: 1),
                ]);
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification n;
  final bool fresh;
  final VoidCallback onDismissed;
  const _NotificationTile(
      {required this.n, required this.fresh, required this.onDismissed});

  IconData get _icon {
    if (n.status == OrderStatus.ready) return Icons.inventory_2_outlined;
    if (n.status == OrderStatus.rejected) return Icons.block;
    if (n.status == null) return Icons.notifications_none;
    return Icons.print_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final highlight = n.status == OrderStatus.ready;
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        color: Colors.black,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        color: fresh ? const Color(0xFFF5F5F5) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlight ? Colors.black : Colors.white,
              border: Border.all(
                  color: n.status == OrderStatus.rejected
                      ? Colors.black38
                      : Colors.black),
            ),
            child: Icon(_icon,
                size: 20, color: highlight ? Colors.white : Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(n.title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              fresh ? FontWeight.w700 : FontWeight.w500)),
                ),
                const SizedBox(width: 8),
                Text(ago(n.time),
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black54)),
              ]),
              if (n.body.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(n.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
              if (n.orderId != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Text('Order #${n.orderId}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
          ),
          if (fresh)
            const Padding(
              padding: EdgeInsets.only(left: 8, top: 6),
              child: Icon(Icons.circle, size: 8),
            ),
        ]),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.notifications_none, size: 48, color: Colors.black38),
            SizedBox(height: 12),
            Text("You're all caught up",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('Order updates will show up here.',
                style: TextStyle(color: Colors.black54)),
          ]),
        ),
      );
}

class StatusChip extends StatelessWidget {
  final OrderStatus status;
  const StatusChip(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final filled = status == OrderStatus.ready;
    final muted = status == OrderStatus.rejected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: muted ? Colors.black38 : Colors.black),
      ),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: filled
                  ? Colors.white
                  : (muted ? Colors.black45 : Colors.black))),
    );
  }
}

class StatusStepper extends StatelessWidget {
  final OrderStatus status;
  final bool inverted;
  const StatusStepper(this.status, {this.inverted = false, super.key});
  static const _labels = ['Pending', 'Accepted', 'Ready', 'Done'];

  @override
  Widget build(BuildContext context) {
    final idx = OrderStatus.flow.indexOf(status);
    final n = OrderStatus.flow.length;
    final on = inverted ? Colors.white : Colors.black;
    final off = inverted ? Colors.white38 : Colors.black26;
    return Row(children: [
      for (var i = 0; i < n; i++)
        Expanded(
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: Container(
                      height: 2,
                      color:
                          i == 0 ? Colors.transparent : (i <= idx ? on : off))),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= idx ? on : Colors.transparent,
                  border: Border.all(color: i <= idx ? on : off, width: 2),
                ),
                child: i < idx
                    ? Icon(Icons.check,
                        size: 9, color: inverted ? Colors.black : Colors.white)
                    : null,
              ),
              Expanded(
                  child: Container(
                      height: 2,
                      color: i == n - 1
                          ? Colors.transparent
                          : (i < idx ? on : off))),
            ]),
            const SizedBox(height: 6),
            Text(_labels[i],
                style: TextStyle(
                    fontSize: 10,
                    color: i <= idx ? on : off,
                    fontWeight: i == idx ? FontWeight.w700 : FontWeight.w400)),
          ]),
        ),
    ]);
  }
}

String statusHint(OrderStatus s) => switch (s) {
      OrderStatus.pending => 'Waiting for the shop to accept your order.',
      OrderStatus.accepted => 'Your document is being printed.',
      OrderStatus.ready => 'Ready for pickup at the counter.',
      OrderStatus.done => 'Completed.',
      OrderStatus.rejected => 'This order was declined.',
    };

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700))),
          if (trailing != null) trailing!,
        ]),
      );
}

class KV extends StatelessWidget {
  final String k, v;
  const KV(this.k, this.v, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 110,
              child: Text(k, style: const TextStyle(color: Colors.black54))),
          Expanded(
              child:
                  Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}

Future<void> rejectDialog(BuildContext context, ShopStore s, Order o) async {
  final ctl = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (dc) => AlertDialog(
      backgroundColor: Colors.white,
      title: Text('Reject #${o.id}'),
      content: TextField(
        controller: ctl,
        autofocus: true,
        maxLines: 2,
        decoration:
            const InputDecoration(labelText: 'Reason (shown to customer)'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dc),
            child: const Text('Cancel', style: TextStyle(color: Colors.black))),
        FilledButton(
            style: compact,
            onPressed: () => Navigator.pop(dc, ctl.text.trim()),
            child: const Text('Reject')),
      ],
    ),
  );
  if (reason != null && reason.isNotEmpty) s.reject(o, reason);
}
