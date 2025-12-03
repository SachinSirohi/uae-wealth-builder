import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/transaction.dart';
import '../../services/database_service.dart';
import '../../services/invoice_scanner_service.dart';

class ReviewScannedReceiptScreen extends StatefulWidget {
  final ScannedInvoice scannedData;
  final String? imagePath;

  const ReviewScannedReceiptScreen({
    super.key,
    required this.scannedData,
    this.imagePath,
  });

  @override
  State<ReviewScannedReceiptScreen> createState() => _ReviewScannedReceiptScreenState();
}

class _ReviewScannedReceiptScreenState extends State<ReviewScannedReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  late TransactionCategory _selectedCategory;
  bool _isIncome = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.scannedData.amount.toStringAsFixed(2),
    );
    _merchantController = TextEditingController(
      text: widget.scannedData.merchantName,
    );
    _notesController = TextEditingController();
    _selectedDate = widget.scannedData.date;
    _selectedCategory = TransactionCategory.uncategorized;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: _merchantController.text,
        merchant: _merchantController.text,
        amount: _isIncome ? amount : -amount,
        date: _selectedDate,
        category: _selectedCategory,
        rawText: widget.scannedData.rawText,
        isIncome: _isIncome,
        confirmed: true, // User reviewed and confirmed
      );

      await _databaseService.addTransaction(transaction);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Receipt saved: AED ${_currencyFormat.format(amount)}',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate back to dashboard
      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving transaction: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Receipt'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          children: [
            // Receipt Preview Card
            if (widget.imagePath != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scanned Receipt',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        ),
                        child: const Center(
                          child: Icon(Icons.receipt_long, size: 64, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppConstants.spacingL),

            // Transaction Type Toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Expense'),
                        selected: !_isIncome,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _isIncome = false;
                            });
                          }
                        },
                        selectedColor: Colors.red.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Income'),
                        selected: _isIncome,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _isIncome = true;
                            });
                          }
                        },
                        selectedColor: Colors.green.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),

            // Amount Field
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount (AED)',
                prefixText: 'AED ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Amount must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spacingL),

            // Merchant Field
            TextFormField(
              controller: _merchantController,
              decoration: InputDecoration(
                labelText: 'Merchant / Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a merchant name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spacingL),

            // Category Dropdown
            DropdownButtonFormField<TransactionCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              items: TransactionCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(category.icon, size: 20, color: AppColors.primary),
                      const SizedBox(width: AppConstants.spacingS),
                      Text(category.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: AppConstants.spacingL),

            // Date Picker
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                  style: AppTextStyles.bodyText1,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),

            // Notes Field
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppConstants.spacingXL),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                    ),
                    child: Text(
                      _isSaving ? 'Saving...' : 'Save Transaction',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
