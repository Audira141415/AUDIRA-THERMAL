import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/utils/currency_formatter.dart';
import 'package:audira_receipt/core/utils/number_to_words.dart';

class AmountField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<double>? onAmountChanged;
  final String? initialAmountWords;

  const AmountField({
    super.key,
    required this.controller,
    this.onAmountChanged,
    this.initialAmountWords,
  });

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  String _words = '';

  @override
  void initState() {
    super.initState();
    if (widget.controller.text.isNotEmpty) {
      _updateWords(widget.controller.text);
    } else if (widget.initialAmountWords != null) {
      _words = widget.initialAmountWords!;
    }

    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _updateWords(widget.controller.text);
  }

  void _updateWords(String text) {
    final amount = CurrencyFormatter.parse(text);
    final words = amount > 0 ? NumberToWords.convert(amount) : 'Nol Rupiah';
    setState(() {
      _words = words;
    });
    if (widget.onAmountChanged != null) {
      widget.onAmountChanged!(amount);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            IndonesianCurrencyInputFormatter(),
          ],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
          decoration: InputDecoration(
            labelText: 'Nominal Pembayaran *',
            hintText: '0',
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppColors.border),
                ),
              ),
              child: const Text(
                'Rp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nominal pembayaran wajib diisi';
            }
            final amount = CurrencyFormatter.parse(value);
            if (amount <= 0) {
              return 'Nominal harus lebih dari 0';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),

        // Live Terbilang Preview Box
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.record_voice_over_outlined,
                    size: 14,
                    color: AppColors.primaryDark,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Terbilang Otomatis:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _words.isNotEmpty ? _words : 'Nol Rupiah',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
