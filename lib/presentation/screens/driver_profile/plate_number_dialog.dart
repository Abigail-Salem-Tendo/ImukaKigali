import 'package:flutter/material.dart';
import 'package:imuka_kigali/domain/entities/vehicle_class.dart';

/// Opens a dialog where the driver types a licence plate number.
/// Returns the plate written the standard way ("RAD 428 E"), or null if
/// the driver tapped Cancel. [initialPlate] fills the field at the start,
/// and [vehicleType] decides which kind of plate is accepted.
Future<String?> showPlateNumberDialog(
  BuildContext context, {
  required String vehicleType,
  String initialPlate = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PlateNumberDialog(
      initialPlate: initialPlate,
      vehicleClass: VehicleClasses.of(vehicleType),
    ),
  );
}

/// The dialog itself. It is a StatefulWidget only because it has to keep
/// a text controller and a form key alive.
class _PlateNumberDialog extends StatefulWidget {
  /// Creates the dialog with the text that fills the field at the start
  /// and the vehicle the plate belongs to.
  const _PlateNumberDialog({
    required this.initialPlate,
    required this.vehicleClass,
  });

  final String initialPlate;
  final VehicleClass vehicleClass;

  /// Creates the object that holds the controller and the form key.
  @override
  State<_PlateNumberDialog> createState() => _PlateNumberDialogState();
}

/// Holds the text controller and the form key of the plate dialog.
class _PlateNumberDialogState extends State<_PlateNumberDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialPlate,
  );

  /// Frees the text controller when the dialog closes.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Checks the typed plate. If it is valid, it closes the dialog and
  /// returns the formatted plate. If not, the field shows its error.
  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, formatRwandaPlate(_controller.text));
    }
  }

  /// Draws the dialog: a title, the plate field, and the Cancel and Save
  /// buttons.
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
          decoration: InputDecoration(
            hintText: 'e.g. ${widget.vehicleClass.plateExample}',
            prefixIcon: const Icon(Icons.confirmation_number_outlined),
          ),
          validator: (value) => widget.vehicleClass.acceptsPlate(value ?? '')
              ? null
              : widget.vehicleClass.plateError,
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
