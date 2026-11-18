// Owner: Member 1
// Shared widget: AppTextField. Label above a filled input, as in the Figma
// "Inputs" section. Works inside a Form, so Form.validate() checks it.
//
//   AppTextField(
//     label: 'Email',
//     hint: 'Enter your email',
//     controller: _email,
//     keyboardType: TextInputType.emailAddress,
//     validator: Validators.email,
//   )
//
//   AppTextField(label: 'Mobile Number', prefixText: '+250', keyboardType: TextInputType.phone, validator: Validators.phone)
//   AppTextField(label: 'Secure Password', isPassword: true, validator: Validators.password)
//
// It is a StatefulWidget only to hold the show/hide-password notifier
// (allowed by Rule 2: no setState is used).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.isPassword = false,
    this.isOptional = false,
    this.prefixIcon,
    this.prefixText,
    this.suffix,
    this.helperText,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onFieldSubmitted,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
  }) : assert(
         controller == null || initialValue == null,
         'Use either controller or initialValue, not both',
       );

  /// Shown above the field.
  final String? label;

  /// Grey text inside the empty field.
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;

  /// e.g. Validators.email. Returns null when valid, or the error message.
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// Hides the text and adds a show/hide eye button.
  final bool isPassword;

  /// Adds "(Optional)" after the label.
  final bool isOptional;
  final IconData? prefixIcon;

  /// Fixed text at the start, e.g. '+250' for phone numbers.
  final String? prefixText;

  /// Widget at the end, e.g. a StatusChip('Verified') or a unit like 'RWF'.
  final Widget? suffix;

  /// Small grey text under the field.
  final String? helperText;
  final int maxLines;
  final bool enabled;

  /// With [onTap], turns the field into a picker (e.g. open a list of areas).
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final ValueNotifier<bool> _obscured = ValueNotifier(widget.isPassword);

  @override
  void dispose() {
    _obscured.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text.rich(
            TextSpan(
              text: widget.label,
              children: [
                if (widget.isOptional)
                  TextSpan(
                    text: ' (Optional)',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        ValueListenableBuilder<bool>(
          valueListenable: _obscured,
          builder: (context, obscured, _) => TextFormField(
            controller: widget.controller,
            initialValue: widget.initialValue,
            focusNode: widget.focusNode,
            validator: widget.validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            obscureText: obscured,
            enableSuggestions: !widget.isPassword,
            autocorrect: !widget.isPassword,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onFieldSubmitted,
            autofillHints: widget.autofillHints,
            inputFormatters: widget.inputFormatters,
            decoration: InputDecoration(
              hintText: widget.hint,
              helperText: widget.helperText,
              helperMaxLines: 2,
              errorMaxLines: 2,
              prefixIcon: _prefix(scheme),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      tooltip: obscured ? 'Show password' : 'Hide password',
                      icon: Icon(
                        obscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: AppSpacing.iconSm,
                      ),
                      onPressed: () => _obscured.value = !obscured,
                    )
                  : widget.suffix == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: widget.suffix,
                    ),
              suffixIconConstraints: widget.isPassword
                  ? null
                  : const BoxConstraints(),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _prefix(ColorScheme scheme) {
    final icon = widget.prefixIcon;
    final text = widget.prefixText;
    if (icon == null && text == null) return null;

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: AppSpacing.iconSm, color: scheme.onSurfaceVariant),
          if (icon != null && text != null)
            const SizedBox(width: AppSpacing.sm),
          if (text != null) ...[
            Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              height: AppSpacing.lg,
              child: VerticalDivider(
                width: AppSpacing.borderWidth,
                color: scheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
