import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data.dart';
import 'widgets.dart';
import 'customer.dart';

class _ServicePreset {
  final String title, description;
  final IconData icon;
  final PrintSpec Function() spec;
  const _ServicePreset(this.title, this.description, this.icon, this.spec);
}

final _presets = <_ServicePreset>[
  _ServicePreset('Photocopy (B&W)', 'A4 · Black & white · Single-sided',
      Icons.content_copy, () => PrintSpec()),
  _ServicePreset('Color Printing', 'A4 · Full color · Single-sided',
      Icons.palette_outlined, () => PrintSpec(color: true)),
  _ServicePreset('Thesis / Research Paper', 'A4 · Double-sided · Spiral bound',
      Icons.menu_book_outlined, () => PrintSpec(duplex: true, finish: 'Spiral')),
  _ServicePreset('Reports & Contracts', 'Legal · Double-sided · Stapled',
      Icons.description_outlined, () => PrintSpec(paper: 'Legal', duplex: true, finish: 'Staple')),
  _ServicePreset('Lamination', 'A4 · Black & white · Laminated',
      Icons.layers_outlined, () => PrintSpec(finish: 'Lamination')),
  _ServicePreset('Poster (A3 Color)', 'A3 · Full color',
      Icons.image_outlined, () => PrintSpec(paper: 'A3', color: true)),
];

class CustomerServicesTab extends StatelessWidget {
  const CustomerServicesTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<ShopStore>();
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Quick order', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text("Pick a service — we'll set the print options for you.",
          style: TextStyle(color: Colors.black54, fontSize: 13)),
      const SizedBox(height: 20),
      for (final p in _presets)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            onTap: s.acceptingOrders
                ? () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => NewOrderPage(presetSpec: p.spec(), presetLabel: p.title)))
                : null,
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                child: Icon(p.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(p.description, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ]),
              ),
              const Icon(Icons.chevron_right, color: Colors.black45),
            ]),
          ),
        ),
      if (!s.acceptingOrders)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('The shop has paused new orders. Please check back soon.',
              style: TextStyle(color: Colors.black54)),
        ),
    ]);
  }
}