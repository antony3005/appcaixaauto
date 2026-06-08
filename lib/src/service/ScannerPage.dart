import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../page/carrinho_compra.dart';

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
    void handleDeepLink(Uri uri) {
      if (uri.host == "session" && uri.pathSegments.isNotEmpty) {
        final sessionId = uri.pathSegments.first;

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CarrinhoCompra(session: sessionId)),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Scanner")),
      body: MobileScanner(
        onDetect: (capture) {
          final code = capture.barcodes.first.rawValue;

          if (code == null || scanned) return;

          scanned = true;

          final uri = Uri.tryParse(code);

          if (uri == null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("QR Code inválido")));
            return;
          }

          Navigator.pop(context);

          handleDeepLink(uri);
        },
      ),
    );
  }
}
