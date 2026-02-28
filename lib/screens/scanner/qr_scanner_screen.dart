import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../material/material_detail_screen.dart';
import '../../services/material_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  final MaterialService _materialService = MaterialService();
  bool _processing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _foundBarcode(BarcodeCapture capture) async {
    if (_processing || capture.barcodes.isEmpty) return;
    final String? code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _processing = true);
    await cameraController.stop();

    final material = await _materialService.getByQr(code);

    if (!mounted) return;

    if (material != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MaterialDetailScreen(material: material),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Material no encontrado para QR: $code'),
          backgroundColor: const Color(0xFFEF4444),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }

    // Resume scanning
    await cameraController.start();
    if (mounted) setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _foundBarcode,
          ),
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),
          if (_processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF7C3AED)),
                    SizedBox(height: 16),
                    Text('Buscando material...',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Text(
                'Coloca el código QR dentro del marco',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 250,
      height: 250,
    );

    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRect(scanArea)
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    final borderPaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(scanArea, borderPaint);

    final cornerPaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    canvas.drawLine(Offset(scanArea.left, scanArea.top),
        Offset(scanArea.left + cornerLength, scanArea.top), cornerPaint);
    canvas.drawLine(Offset(scanArea.left, scanArea.top),
        Offset(scanArea.left, scanArea.top + cornerLength), cornerPaint);
    canvas.drawLine(Offset(scanArea.right, scanArea.top),
        Offset(scanArea.right - cornerLength, scanArea.top), cornerPaint);
    canvas.drawLine(Offset(scanArea.right, scanArea.top),
        Offset(scanArea.right, scanArea.top + cornerLength), cornerPaint);
    canvas.drawLine(Offset(scanArea.left, scanArea.bottom),
        Offset(scanArea.left + cornerLength, scanArea.bottom), cornerPaint);
    canvas.drawLine(Offset(scanArea.left, scanArea.bottom),
        Offset(scanArea.left, scanArea.bottom - cornerLength), cornerPaint);
    canvas.drawLine(Offset(scanArea.right, scanArea.bottom),
        Offset(scanArea.right - cornerLength, scanArea.bottom), cornerPaint);
    canvas.drawLine(Offset(scanArea.right, scanArea.bottom),
        Offset(scanArea.right, scanArea.bottom - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
