import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../services/inventarista_service.dart';

class AddMaterialScreen extends StatefulWidget {
  const AddMaterialScreen({super.key});

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final InventaristaService _service = InventaristaService();
  final ImagePicker _picker = ImagePicker();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _locations = [];

  int? _selectedCategoryId;
  int? _selectedLocationId;
  bool _isConsumable = false;
  File? _imageFile;
  bool _loading = false;
  bool _loadingData = true;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final cats = await _service.getCategories();
    final locs = await _service.getLocations();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _locations = locs.where((l) => l['is_locked'] != true).toList();
      _loadingData = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (_) {}
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppPalette.accent),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppPalette.accent),
                title: const Text('Elegir de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_imageFile != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: AppPalette.error),
                  title: const Text('Quitar foto',
                      style: TextStyle(color: AppPalette.error)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _imageFile = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      setState(() => _errorMessage = 'Selecciona una categoría');
      return;
    }
    if (_selectedLocationId == null) {
      setState(() => _errorMessage = 'Selecciona una ubicación');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await _service.createMaterial(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      categoryId: _selectedCategoryId!,
      locationId: _selectedLocationId!,
      quantity: int.tryParse(_qtyCtrl.text) ?? 1,
      isConsumable: _isConsumable,
      image: _imageFile,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _successMessage = 'Material creado correctamente';
        _nameCtrl.clear();
        _descCtrl.clear();
        _qtyCtrl.text = '1';
        _selectedCategoryId = null;
        _selectedLocationId = null;
        _isConsumable = false;
        _imageFile = null;
      } else {
        _errorMessage = result['message'] ?? 'Error al crear el material';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_loadingData) {
      return const Center(
        child: CircularProgressIndicator(color: AppPalette.accent),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppPalette.accent.withOpacity(0.15),
                    AppPalette.accentLight.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppPalette.accent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_box_rounded,
                      color: AppPalette.accent, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Agregar Material',
                          style: TextStyle(
                              color: colors.text,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text('Completa los datos del nuevo material',
                          style: TextStyle(
                              color: colors.textSub, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Success / Error messages
            if (_successMessage != null)
              _Banner(
                message: _successMessage!,
                color: AppPalette.success,
                icon: Icons.check_circle_outline,
              ),
            if (_errorMessage != null)
              _Banner(
                message: _errorMessage!,
                color: AppPalette.error,
                icon: Icons.error_outline,
              ),

            // Image picker
            _SectionLabel('Foto del material'),
            GestureDetector(
              onTap: _showImageOptions,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppPalette.accent.withOpacity(0.3),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageFile != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_imageFile!, fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.white, size: 18),
                                onPressed: _showImageOptions,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: AppPalette.accent, size: 40),
                          const SizedBox(height: 8),
                          Text('Agregar foto',
                              style: TextStyle(
                                  color: colors.textSub, fontSize: 13)),
                          Text('Opcional',
                              style: TextStyle(
                                  color: colors.textHint, fontSize: 11)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Name
            _SectionLabel('Nombre *'),
            _Field(
              controller: _nameCtrl,
              hint: 'Ej: Laptop Dell XPS 15',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),

            // Description
            _SectionLabel('Descripción'),
            _Field(
              controller: _descCtrl,
              hint: 'Descripción del material',
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Category
            _SectionLabel('Categoría *'),
            _Dropdown(
              value: _selectedCategoryId,
              hint: 'Selecciona categoría',
              items: _categories
                  .map((c) => DropdownMenuItem(
                        value: c['id'] as int,
                        child: Text(c['name'] as String? ?? ''),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedCategoryId = v),
            ),
            const SizedBox(height: 16),

            // Location
            _SectionLabel('Ubicación *'),
            _Dropdown(
              value: _selectedLocationId,
              hint: _locations.isEmpty
                  ? 'Sin ubicaciones disponibles'
                  : 'Selecciona ubicación',
              items: _locations
                  .map((l) => DropdownMenuItem(
                        value: l['id'] as int,
                        child: Text(l['name'] as String? ?? ''),
                      ))
                  .toList(),
              onChanged: _locations.isEmpty
                  ? null
                  : (v) => setState(() => _selectedLocationId = v),
            ),
            const SizedBox(height: 16),

            // Quantity
            _SectionLabel('Cantidad *'),
            _Field(
              controller: _qtyCtrl,
              hint: '1',
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1) return 'Ingresa un número válido';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Consumable toggle
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Consumible',
                            style: TextStyle(
                                color: colors.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        Text('No se devuelve al completar el préstamo',
                            style: TextStyle(
                                color: colors.textSub, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isConsumable,
                    onChanged: (v) => setState(() => _isConsumable = v),
                    activeColor: AppPalette.accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Crear Material',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: context.colors.text,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: colors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textHint),
        filled: true,
        fillColor: colors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.error, width: 2),
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final int? value;
  final String hint;
  final List<DropdownMenuItem<int>> items;
  final ValueChanged<int?>? onChanged;

  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: colors.card,
        hint: Text(hint,
            style: TextStyle(color: colors.textHint, fontSize: 14)),
        style: TextStyle(color: colors.text, fontSize: 14),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;

  const _Banner({
    required this.message,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
