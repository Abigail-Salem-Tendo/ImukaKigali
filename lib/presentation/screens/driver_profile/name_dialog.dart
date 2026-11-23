import 'package:flutter/material.dart';

/// Opens a dialog where the driver types their full name. Returns the name
/// without extra spaces, or null if the driver tapped Cancel.
/// [initialName] fills the field at the start.
Future<String?> showNameDialog(
  BuildContext context, {
  required String initialName,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(initialName: initialName),
  );
}

/// The dialog itself. It is a StatefulWidget only because it has to keep
/// a text controller and a form key alive.
class _NameDialog extends StatefulWidget {
  /// Creates the dialog with the name that fills the field at the start.
  const _NameDialog({required this.initialName});

  final String initialName;

  /// Creates the object that holds the controller and the form key.
  @override
  State<_NameDialog> createState() => _NameDialogState();
}

/// Holds the text controller and the form key of the name dialog.
class _NameDialogState extends State<_NameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );

  /// Frees the text controller when the dialog closes.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Checks the typed name. If it is valid, it closes the dialog and
  /// returns the name. If not, the field shows its error.
  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  /// Draws the dialog: a title, the name field, and the Cancel and Save
  /// buttons.
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Full Legal Name'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Jean-Claude Mugisha',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) =>
              (value ?? '').trim().length < 3 ? 'Enter your full name.' : null,
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
