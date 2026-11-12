// Owner: Member 2
// A dialog for typing a Rwanda licence plate number.

import 'package:flutter/material.dart';

import '../../../domain/entities/vehicle.dart';

/// Opens the dialog. Returns the plate written the standard way
/// ("RAD 428 E"), or null if the driver tapped Cancel.
Future<String?> showPlateNumberDialog(
    BuildContext context, {
      String initialPlate = '',
    }) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PlateNumberDialog(initialPlate: initialPlate),
  );
}

// A StatefulWidget is allowed here ONLY because it must hold a
// TextEditingController and a form key (team rule 2). It keeps no other state.
class _PlateNumberDialog extends StatefulWidget {
  const _PlateNumberDialog({required this.initialPlate});

  final String initialPlate;

  @override
  State<_PlateNumberDialog> createState() => _PlateNumberDialogState();
}

class _PlateNumberDialogState extends State<_PlateNumberDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller =
  TextEditingController(text: widget.initialPlate);

  @override
  void dispose() {
    // Controllers must be disposed, or they keep using memory.
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    // validate() runs the validator below and shows its message if wrong.
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, formatRwandaPlate(_controller.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rwanda License Plate Number'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'e.g. RAD 428 E',
            prefixIcon: Icon(Icons.confirmation_number_outlined),
          ),
          validator: (value) => isValidRwandaPlate(value ?? '')
              ? null
              : 'Enter a Rwanda plate like RAD 428 E.',
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
