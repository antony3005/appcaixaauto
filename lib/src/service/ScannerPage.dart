import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  @override
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool scanned = false;

  void _handleBarcode(String code) {
    if (scanned) return;

    setState(() {
      scanned = true;
    });

    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scanner")),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          final code = barcode.rawValue;

          if (code == null || scanned) return;

          scanned = true;

          final uri = Uri.tryParse(code);

          if (uri != null && uri.host == "produto") {
            final id = uri.pathSegments.first;
            _handleBarcode(id);
          }
        },
      ),
    );
  }
}
