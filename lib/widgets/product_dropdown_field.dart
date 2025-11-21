import 'package:flutter/material.dart';
import 'package:inventory_user/utils/pallete.dart';

/// Reusable dropdown field widget for product form
class ProductDropdownField<T> extends StatelessWidget {
  final T? value;
  final String label;
  final String hint;
  final List<T> items;
  final String Function(T) getItemLabel;
  final T Function(T) getItemValue;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  const ProductDropdownField({
    Key? key,
    required this.value,
    required this.label,
    required this.hint,
    required this.items,
    required this.getItemLabel,
    required this.getItemValue,
    required this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(hint),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]!
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Pallete.primaryRed,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: getItemValue(item),
          child: Text(getItemLabel(item)),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
