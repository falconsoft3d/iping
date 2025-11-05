import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ping_provider.dart';

class AddServerDialog extends StatefulWidget {
  const AddServerDialog({super.key});

  @override
  State<AddServerDialog> createState() => _AddServerDialogState();
}

class _AddServerDialogState extends State<AddServerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.add_circle_outline, color: Color(0xFF0078D4)),
          SizedBox(width: 8),
          Text('Agregar servidor'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del servidor',
                hintText: 'Ej: Google DNS',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un nombre';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Dirección IP o dominio',
                hintText: 'Ej: 8.8.8.8 o google.com',
                prefixIcon: Icon(Icons.language),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa una IP o dominio';
                }
                if (!_isValidIpOrDomain(value.trim())) {
                  return 'Por favor ingresa una IP o dominio válido';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addServer,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Agregar'),
        ),
      ],
    );
  }

  bool _isValidIpOrDomain(String value) {
    // Validación básica para IP v4
    final ipRegex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    
    // Validación básica para dominio
    final domainRegex = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    
    return ipRegex.hasMatch(value) || domainRegex.hasMatch(value);
  }

  Future<void> _addServer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PingProvider>(context, listen: false);
      await provider.addServer(
        _nameController.text.trim(),
        _ipController.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Servidor agregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar servidor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}