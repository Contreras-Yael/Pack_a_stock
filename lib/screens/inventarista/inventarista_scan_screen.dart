import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../config/app_colors.dart';
import '../../models/material_model.dart';
import '../../services/inventarista_service.dart';

class InventaristaScanScreen extends StatefulWidget {
  const InventaristaScanScreen({super.key});

  @override
  State<InventaristaScanScreen> createState() => _InventaristaScanScreenState();
}

class _InventaristaScanScreenState extends State<InventaristaScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final InventaristaService _service = InventaristaService();

  bool _scanning = true;
  bool _loading = false;
  MaterialItem? _material;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_scanning || _loading) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _scanning = false;
      _loading = true;
      _material = null;
      _error = null;
    });

    await _controller.stop();
    final result = await _service.getMaterialByQr(code);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result != null) {
        _material = result;
      } else {
        _error = 'Material no encontrado para este código QR.';
      }
    });
  }

  void _reset() async {
    setState(() {
      _scanning = true;
      _material = null;
      _error = null;
    });
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppPalette.accent),
            const SizedBox(height: 16),
            Text('Buscando material...', style: TextStyle(color: colors.textSub)),
          ],
        ),
      );
    }

    if (_material != null) {
      return _MaterialInfoView(material: _material!, onScanAgain: _reset);
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppPalette.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded,
                    color: AppPalette.error, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSub, fontSize: 15),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Escanear de nuevo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Scanner view
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
              // Overlay frame
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppPalette.accent, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: colors.card,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Text(
                  'Escanea el código QR del material',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Apunta la cámara al código QR para ver la información del material',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSub, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MaterialInfoView extends StatelessWidget {
  final MaterialItem material;
  final VoidCallback onScanAgain;

  const _MaterialInfoView({required this.material, required this.onScanAgain});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / placeholder
          Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppPalette.accent.withOpacity(0.3), width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: material.imageUrl != null && material.imageUrl!.isNotEmpty
                  ? Image.network(material.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
          ),
          const SizedBox(height: 20),

          // Locked banner
          if (material.isLocked)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppPalette.error.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      color: AppPalette.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Material bloqueado — sede fuera del plan actual',
                      style: TextStyle(
                          color: AppPalette.error.withOpacity(0.9),
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Name
          Text(
            material.name,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.text),
          ),
          const SizedBox(height: 6),

          // SKU
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('SKU: ${material.sku}',
                style:
                    TextStyle(fontSize: 12, color: colors.textSub)),
          ),
          const SizedBox(height: 16),

          // Info grid
          Row(
            children: [
              _InfoTile(
                icon: Icons.check_circle_outline,
                label: 'Estado',
                value: material.status == 'available'
                    ? 'Disponible'
                    : 'No disponible',
                color: material.status == 'available'
                    ? AppPalette.success
                    : AppPalette.error,
                colors: colors,
              ),
              const SizedBox(width: 12),
              _InfoTile(
                icon: Icons.inventory,
                label: 'Disponibles',
                value: '${material.availableQuantity}',
                color: AppPalette.info,
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Location
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: AppPalette.accent, size: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ubicación',
                        style: TextStyle(
                            fontSize: 11, color: colors.textSub)),
                    const SizedBox(height: 2),
                    Text(
                      material.locationName ?? 'Sin ubicación',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: material.locationName != null
                              ? colors.text
                              : colors.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Category
          if (material.categoryName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category_outlined,
                      color: AppPalette.accentLight, size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Categoría',
                          style: TextStyle(
                              fontSize: 11, color: colors.textSub)),
                      const SizedBox(height: 2),
                      Text(
                        material.categoryName!,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.text),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Description
          Text('Descripción',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.text)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              material.description.isNotEmpty
                  ? material.description
                  : 'Sin descripción',
              style: TextStyle(
                  fontSize: 13, color: colors.textSub, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),

          // Scan again button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onScanAgain,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Escanear otro material'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppPalette.accent, AppPalette.accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.inventory_2_outlined,
            size: 64, color: Colors.white),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final AppColors colors;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(fontSize: 11, color: colors.textSub)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}
