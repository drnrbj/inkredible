import 'package:flutter/material.dart';
import 'package:inkredible/shared/widgets.dart';

/// Shows the progress of sending a customer's PDF to the shop computer.
Future<void> showSendToComputerDemo(BuildContext context, String fileName) {
  return showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _TransferSheet(fileName: fileName),
  );
}

class _TransferSheet extends StatefulWidget {
  final String fileName;
  const _TransferSheet({required this.fileName});
  @override
  State<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<_TransferSheet> {
  static const steps = [
    'Connecting to shop computer...',
    'Downloading file from cloud...',
    'Adding to print queue...',
  ];
  int step = 0;
  bool get done => step >= steps.length;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    for (var i = 0; i < steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => step = i + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send to shop computer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(widget.fileName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: i < step
                        ? const Icon(Icons.check_circle, size: 20)
                        : (i == step
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : const Icon(Icons.radio_button_unchecked,
                                size: 20, color: Colors.black26)),
                  ),
                  const SizedBox(width: 12),
                  Text(steps[i],
                      style: TextStyle(
                          color: i <= step ? Colors.black : Colors.black38)),
                ]),
              ),
            const SizedBox(height: 16),
            AppCard(
              child: Text(
                  done
                      ? 'The file is now in the print queue on the shop computer.'
                      : 'Sending your file to the shop computer…',
                  style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
            ),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: done ? () => Navigator.pop(context) : null,
                child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}