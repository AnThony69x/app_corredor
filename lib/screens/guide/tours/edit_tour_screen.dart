import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../controllers/tour_controller.dart';
import '../../../models/tour.dart';
import '../../../utils/helpers.dart';

class EditTourScreen extends StatefulWidget {
  final Tour tour;

  const EditTourScreen({super.key, required this.tour});

  @override
  State<EditTourScreen> createState() => _EditTourScreenState();
}

class _EditTourScreenState extends State<EditTourScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final TourController _tourController = TourController();

  late final TextEditingController _tituloController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _precioController;
  late final TextEditingController _duracionController;
  late final TextEditingController _ubicacionController;
  late final TextEditingController _maxPersonasController;
  late final TextEditingController _puntoEncuentroController;
  late final TextEditingController _redSocialController;
  late final TextEditingController _telefonoController;

  late String _categoriaSeleccionada;
  bool _loading = false;
  bool _hasChanges = false;

  final List<String> _categorias = [
    'Aventura', 'Cultura', 'Gastronomía', 'Naturaleza', 'Historia',
    'Deportes', 'Relajación', 'Familiar', 'Nocturno', 'Fotográfico'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupChangeListeners();
  }

  void _initializeControllers() {
    _tituloController = TextEditingController(text: widget.tour.titulo);
    _descripcionController = TextEditingController(text: widget.tour.descripcion);
    _precioController = TextEditingController(text: widget.tour.precio.toString());
    _duracionController = TextEditingController(text: widget.tour.duracionHoras.toString());
    _ubicacionController = TextEditingController(text: widget.tour.ubicacion);
    _maxPersonasController = TextEditingController(text: widget.tour.maxPersonas.toString());
    _puntoEncuentroController = TextEditingController(text: widget.tour.puntoEncuentro);
    _redSocialController = TextEditingController(text: widget.tour.redSocial ?? '');
    _telefonoController = TextEditingController(text: widget.tour.telefono ?? '');
    _categoriaSeleccionada = widget.tour.categoria;
  }

  void _setupChangeListeners() {
    _tituloController.addListener(_onFieldChanged);
    _descripcionController.addListener(_onFieldChanged);
    _precioController.addListener(_onFieldChanged);
    _duracionController.addListener(_onFieldChanged);
    _ubicacionController.addListener(_onFieldChanged);
    _maxPersonasController.addListener(_onFieldChanged);
    _puntoEncuentroController.addListener(_onFieldChanged);
    _redSocialController.addListener(_onFieldChanged);
    _telefonoController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _duracionController.dispose();
    _ubicacionController.dispose();
    _maxPersonasController.dispose();
    _puntoEncuentroController.dispose();
    _redSocialController.dispose();
    _telefonoController.dispose();
    _scrollController.dispose();
    _tourController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      AppHelpers.showErrorSnackBar(context, 'Por favor completa todos los campos obligatorios');
      return;
    }

    if (_categoriaSeleccionada.isEmpty) {
      AppHelpers.showErrorSnackBar(context, 'Selecciona una categoría');
      return;
    }

    setState(() => _loading = true);

    try {
      final tourActualizado = widget.tour.copyWith(
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        precio: double.parse(_precioController.text),
        duracionHoras: int.parse(_duracionController.text),
        ubicacion: _ubicacionController.text.trim(),
        categoria: _categoriaSeleccionada,
        maxPersonas: int.parse(_maxPersonasController.text),
        puntoEncuentro: _puntoEncuentroController.text.trim(),
        redSocial: _redSocialController.text.trim(),
        telefono: _telefonoController.text.trim(),
      );

      final success = await _tourController.actualizarTour(tourActualizado);
      if (success) {
        AppHelpers.showSuccessSnackBar(context, 'Tour actualizado exitosamente');
        setState(() => _hasChanges = false);
        Navigator.pop(context, true);
      } else {
        AppHelpers.showErrorSnackBar(context, _tourController.error ?? 'Error al actualizar el tour');
      }
    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Error: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101526),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181E2E),
        title: const Text('Editar Tour'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildTextField(_tituloController, 'Título del Tour', 'Ej: Tour por el centro', Icons.title),
              const SizedBox(height: 12),
              _buildTextField(_descripcionController, 'Descripción', 'Detalles del tour', Icons.description, maxLines: 3),
              const SizedBox(height: 12),
              _buildTextField(_precioController, 'Precio (USD)', '50.00', Icons.attach_money, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(_duracionController, 'Duración (horas)', '4', Icons.access_time, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(_ubicacionController, 'Ubicación', 'Ciudad', Icons.location_on),
              const SizedBox(height: 12),
              _buildTextField(_maxPersonasController, 'Máximo Personas', '10', Icons.people, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(_puntoEncuentroController, 'Punto de Encuentro', 'Plaza central', Icons.place),
              const SizedBox(height: 12),
              _buildTextField(_redSocialController, 'Red Social del Guía', 'Ej: @guia_ecologico', Icons.alternate_email),
              const SizedBox(height: 12),
              _buildTextField(_telefonoController, 'Número de Teléfono', 'Ej: +52 123 456 7890', Icons.phone, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]'))]),
              const SizedBox(height: 12),
              _buildCategorySelector(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _guardarCambios,
                child: _loading ? const CircularProgressIndicator() : const Text('Guardar Cambios'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF23A7F3)),
        filled: true,
        fillColor: const Color(0xFF181E2E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null,
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoría del Tour *',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _categorias.map((cat) {
            final selected = _categoriaSeleccionada == cat;
            return ChoiceChip(
              label: Text(cat),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _categoriaSeleccionada = cat;
                  _onFieldChanged();
                });
              },
              selectedColor: const Color(0xFF23A7F3),
              backgroundColor: const Color(0xFF181E2E),
              labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
            );
          }).toList(),
        )
      ],
    );
  }
}