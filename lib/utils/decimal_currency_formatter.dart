import 'package:flutter/services.dart';

/// TextInputFormatter that only allows digits (0-9), commas (,),
/// and at most one decimal point (.).
class DecimalCurrencyFormatter extends TextInputFormatter {
  const DecimalCurrencyFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    // Only allow digits, commas, and dots
    if (!RegExp(r'^[\d,.]*$').hasMatch(text)) {
      return oldValue;
    }

    // Ensure at most ONE dot for decimal
    if ('.'.allMatches(text).length > 1) {
      return oldValue;
    }

    return newValue;
  }
}
