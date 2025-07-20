import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../controllers/tour_controller.dart';
import '../../../models/tour.dart';
import '../../../utils/helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateTourScreen extends StatefulWidget {
  const CreateTourScreen({super.key});

  @override
  State<CreateTourScreen> createState() => _CreateTourScreenState();
}

class _CreateTourScreenState extends State<CreateTourScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final TourController _tourController = TourController();

  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _duracionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _maxPersonasController = TextEditingController();
  final _puntoEncuentroController = TextEditingController();
  final _redSocialController = TextEditingController();
  final _telefonoController = TextEditingController();

  String _categoriaSeleccionada = '';
  bool _loading = false;

  final List<String> _categorias = [
    'Aventura', 'Cultura', 'Gastronomía', 'Naturaleza', 'Historia',
    'Deportes', 'Relajación', 'Familiar', 'Nocturno', 'Fotográfico',
  ];

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

  Future<void> _crearTour() async {
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
      final tour = Tour(
        idGuia: Supabase.instance.client.auth.currentUser!.id,
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        precio: double.parse(_precioController.text),
        duracionHoras: int.parse(_duracionController.text),
        ubicacion: _ubicacionController.text.trim(),
        categoria: _categoriaSeleccionada,
        fechaCreacion: DateTime.now(),
        maxPersonas: int.parse(_maxPersonasController.text),
        puntoEncuentro: _puntoEncuentroController.text.trim(),
        redSocial: _redSocialController.text.trim(),
        telefono: _telefonoController.text.trim(),
        incluye: [],
        noIncluye: [],
        requisitos: null,
        imagenes: [],
      );

      final success = await _tourController.crearTour(tour);

      if (success) {
        AppHelpers.showSuccessSnackBar(context, 'Tour creado exitosamente');
        Navigator.pop(context, true);
      } else {
        AppHelpers.showErrorSnackBar(
          context,
          _tourController.error ?? 'Error al crear el tour',
        );
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
        title: const Text(
          'Crear Nuevo Tour',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Información Básica', Icons.info),
              _buildBasicInfoSection(),
              const SizedBox(height: 30),
              _buildSectionHeader('Detalles del Tour', Icons.details),
              _buildDetailsSection(),
              const SizedBox(height: 30),
              _buildSectionHeader('Contacto del Guía', Icons.contact_phone),
              _buildContactSection(),
              const SizedBox(height: 40),
              _buildCreateButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF23A7F3), size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        _buildTextField(
          controller: _tituloController,
          label: 'Título del Tour',
          hint: 'Ej: City Tour por el Centro Histórico',
          icon: Icons.title,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'El título es obligatorio';
            if (value.trim().length < 5) return 'Debe tener al menos 5 caracteres';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descripcionController,
          label: 'Descripción',
          hint: 'Describe tu tour de manera atractiva...',
          icon: Icons.description,
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'La descripción es obligatoria';
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _precioController,
                label: 'Precio (USD)',
                hint: '50.00',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Obligatorio';
                  final precio = double.tryParse(value);
                  if (precio == null || precio <= 0) return 'Precio inválido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _duracionController,
                label: 'Duración (horas)',
                hint: '4',
                icon: Icons.access_time,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Obligatorio';
                  final duracion = int.tryParse(value);
                  if (duracion == null || duracion <= 0) return 'Duración inválida';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      children: [
        _buildTextField(
          controller: _ubicacionController,
          label: 'Ubicación',
          hint: 'Ej: Centro Histórico, Ciudad de México',
          icon: Icons.location_on,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildCategorySelector(),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _maxPersonasController,
          label: 'Máximo de Personas',
          hint: '10',
          icon: Icons.people,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
            final maxPersonas = int.tryParse(value);
            if (maxPersonas == null || maxPersonas <= 0) return 'Número inválido';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _puntoEncuentroController,
          label: 'Punto de Encuentro',
          hint: 'Ej: Plaza Principal',
          icon: Icons.place,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      children: [
        _buildTextField(
          controller: _redSocialController,
          label: 'Red Social del Guía',
          hint: 'Ej: @guia_ecologico (Instagram, Facebook, etc.)',
          icon: Icons.alternate_email,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _telefonoController,
          label: 'Número de Teléfono',
          hint: 'Ej: +52 123 456 7890',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]'))],
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
            if (value.trim().length < 8) return 'Número inválido';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF23A7F3)),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF181E2E),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF23A7F3), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoría del Tour *',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categorias.map((categoria) {
            final isSelected = _categoriaSeleccionada == categoria;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _categoriaSeleccionada = categoria;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF23A7F3) : const Color(0xFF181E2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF23A7F3) : Colors.white24,
                  ),
                ),
                child: Text(
                  categoria,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _crearTour,
        icon: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add),
        label: Text(
          _loading ? 'Creando Tour...' : 'Crear Tour',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF23A7F3),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}