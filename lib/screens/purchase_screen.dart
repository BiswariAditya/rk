import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:number_to_words/number_to_words.dart';
import '../models/purchseItem.dart';
import '../providers/purchase_provider.dart';
import '../services/firebase_service.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierFormKey = GlobalKey<FormState>();

  // Item form controllers
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hsnCodeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  // Supplier info controllers
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _supplierAddressController =
      TextEditingController();
  final TextEditingController _supplierGstController = TextEditingController();
  final TextEditingController _supplierPhoneController =
      TextEditingController();

  // Bill details
  final TextEditingController _billNumberController = TextEditingController();
  final TextEditingController _billDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _showSupplierForm = false;
  bool _isSaving = false;

  // Tax rate options
  final List<double> _taxRateOptions = [5.0, 9.0, 12.0, 18.0];
  double _selectedTaxRate = 18.0;

  final FirebaseService _dbService = FirebaseService.instance;

  @override
  void initState() {
    super.initState();
    _initializeBill();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _hsnCodeController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _supplierNameController.dispose();
    _supplierAddressController.dispose();
    _supplierGstController.dispose();
    _supplierPhoneController.dispose();
    _billNumberController.dispose();
    _billDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeBill() {
    _billNumberController.text = "PB-${DateTime.now().millisecondsSinceEpoch}";
    _billDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final purchaseProvider = Provider.of<PurchaseProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final roundedTotal = purchaseProvider.totalAmount.roundToDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Bills'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showPurchaseHistory,
            tooltip: 'Purchase History',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _showDialog(
                context,
                'Confirm Reset',
                'Are you sure you want to clear all items and supplier information?',
                () {
                  purchaseProvider.clearPurchase();
                  _clearAllFields();
                  Navigator.pop(context);
                },
              );
            },
            tooltip: 'Reset All',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBillInfoSection(),
              const SizedBox(height: 20),
              _buildSupplierSection(),
              const SizedBox(height: 20),
              _buildAddItemSection(screenSize),
              const SizedBox(height: 20),
              _buildItemListSection(purchaseProvider),
              const SizedBox(height: 20),
              if (purchaseProvider.items.isNotEmpty)
                _buildSummarySection(purchaseProvider, roundedTotal),
              const SizedBox(height: 20),
              _buildActionButtons(purchaseProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _billNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Bill Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _billDateController,
                    decoration: const InputDecoration(
                      labelText: 'Bill Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );

                      if (pickedDate != null) {
                        setState(() {
                          _billDateController.text =
                              DateFormat('dd/MM/yyyy').format(pickedDate);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierSection() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSupplierForm = !_showSupplierForm;
        });
      },
      child: Card(
        elevation: 2,
        child: Column(
          children: [
            ListTile(
              title: const Text(
                "Supplier Information",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: IconButton(
                icon: Icon(_showSupplierForm
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down),
                onPressed: () {
                  setState(() {
                    _showSupplierForm = !_showSupplierForm;
                  });
                },
              ),
            ),
            if (_showSupplierForm)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSupplierForm(),
              ),
            if (!_showSupplierForm && _supplierNameController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Name: ${_supplierNameController.text}"),
                    if (_supplierAddressController.text.isNotEmpty)
                      Text("Address: ${_supplierAddressController.text}"),
                    if (_supplierGstController.text.isNotEmpty)
                      Text("GST No: ${_supplierGstController.text}"),
                    if (_supplierPhoneController.text.isNotEmpty)
                      Text("Phone: ${_supplierPhoneController.text}"),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierForm() {
    return Form(
      key: _supplierFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _supplierNameController,
            decoration: const InputDecoration(
              labelText: 'Supplier Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
            validator: (value) => value!.isEmpty ? 'Enter supplier name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _supplierAddressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  maxLength: 15,
                  controller: _supplierGstController,
                  decoration: const InputDecoration(
                    labelText: 'GST Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt_long),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  maxLength: 10,
                  controller: _supplierPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Save Supplier Info'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              if (_supplierFormKey.currentState!.validate()) {
                setState(() {
                  _showSupplierForm = false;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemSection(Size screenSize) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add Purchase Item",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Form(
              key: _formKey,
              child: screenSize.width > 600
                  ? _buildWideItemForm()
                  : _buildNarrowItemForm(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Tax Rate: ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                ...List.generate(_taxRateOptions.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text("${_taxRateOptions[index]}%"),
                      selected: _selectedTaxRate == _taxRateOptions[index],
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedTaxRate = _taxRateOptions[index];
                          });
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle, color: Colors.white),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: _addItem,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideItemForm() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Item Description',
              border: OutlineInputBorder(),
              hintText: 'e.g. Vinyl Material',
            ),
            validator: (value) =>
                value!.isEmpty ? 'Enter item description' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _hsnCodeController,
            decoration: const InputDecoration(
              labelText: 'HSN Code',
              border: OutlineInputBorder(),
              hintText: 'e.g. 3920',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _rateController,
            decoration: const InputDecoration(
              labelText: 'Rate (₹)',
              border: OutlineInputBorder(),
              hintText: 'e.g. 15',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(),
              hintText: 'e.g. 1',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowItemForm() {
    return Column(
      children: [
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Item Description',
            border: OutlineInputBorder(),
            hintText: 'e.g. Vinyl Material',
          ),
          validator: (value) =>
              value!.isEmpty ? 'Enter item description' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _hsnCodeController,
                decoration: const InputDecoration(
                  labelText: 'HSN Code',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 3920',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 1',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _rateController,
          decoration: const InputDecoration(
            labelText: 'Rate (₹)',
            border: OutlineInputBorder(),
            hintText: 'e.g. 15',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildItemListSection(PurchaseProvider purchaseProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Purchase Items",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Total Items: ${purchaseProvider.items.length}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: purchaseProvider.items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text("No items added yet",
                            style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic)),
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          color: Colors.grey.shade100,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          child: Row(
                            children: const [
                              Expanded(
                                  flex: 4,
                                  child: Text("Description",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              Expanded(
                                  flex: 2,
                                  child: Text("HSN",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              Expanded(
                                  flex: 2,
                                  child: Text("Size",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              Expanded(
                                  flex: 1,
                                  child: Text("Qty",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              Expanded(
                                  flex: 2,
                                  child: Text("Rate",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              Expanded(
                                  flex: 1,
                                  child: Text("Tax",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              Expanded(
                                  flex: 2,
                                  child: Text("Amount",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              SizedBox(width: 40),
                            ],
                          ),
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: purchaseProvider.items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = purchaseProvider.items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 4, child: Text(item.description)),
                                  Expanded(
                                      flex: 2,
                                      child: Text(item.hsnCode.toString())),
                                  Expanded(
                                      flex: 1,
                                      child: Text(item.quantity.toString())),
                                  Expanded(
                                      flex: 2,
                                      child: Text(
                                          "₹${item.rate.toStringAsFixed(2)}")),
                                  Expanded(
                                      flex: 1, child: Text("${item.taxRate}%")),
                                  Expanded(
                                      flex: 2,
                                      child: Text(
                                          "₹${item.amount.toStringAsFixed(2)}")),
                                  SizedBox(
                                    width: 40,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          purchaseProvider.removeItem(index),
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(
      PurchaseProvider purchaseProvider, double roundedTotal) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bill Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Amount in words:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Rupees ${NumberToWord().convert('en-in', purchaseProvider.totalAmount.round())} only',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      _buildSummaryRow("Sub Total:",
                          "₹${purchaseProvider.subtotal.toStringAsFixed(2)}"),
                      _buildSummaryRow("CGST:",
                          "₹${purchaseProvider.cgst.toStringAsFixed(2)}"),
                      _buildSummaryRow("SGST:",
                          "₹${purchaseProvider.sgst.toStringAsFixed(2)}"),
                      const Divider(),
                      _buildSummaryRow(
                          "Grand Total:", "₹${roundedTotal.toStringAsFixed(0)}",
                          isBold: true),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    TextStyle style = isBold
        ? const TextStyle(fontWeight: FontWeight.bold)
        : const TextStyle();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PurchaseProvider purchaseProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.save, color: Colors.white),
          label: Text(_isSaving ? 'Saving...' : 'Save Purchase Bill'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: purchaseProvider.items.isEmpty || _isSaving
              ? null
              : () => _savePurchaseBill(purchaseProvider),
        ),
      ],
    );
  }

  void _addItem() {
    if (_formKey.currentState!.validate()) {
      if (_quantityController.text.isEmpty ||
          _rateController.text.isEmpty) {
        _showErrorSnackbar("Please fill all required fields");
        return;
      }

      try {
        final purchaseProvider =
            Provider.of<PurchaseProvider>(context, listen: false);
        purchaseProvider.addItem(
          PurchaseItem(
            description: _descriptionController.text,
            hsnCode: _hsnCodeController.text.isEmpty
                ? 0
                : int.tryParse(_hsnCodeController.text) ?? 0,
            quantity: int.tryParse(_quantityController.text) ?? 0,
            rate: double.tryParse(_rateController.text) ?? 0,
            taxRate: _selectedTaxRate,
          ),
        );

        // Clear item form
        _descriptionController.clear();
        _hsnCodeController.clear();
        _quantityController.clear();
        _rateController.clear();

        FocusScope.of(context).requestFocus(FocusNode());
      } catch (e) {
        _showErrorSnackbar("Invalid input. Please check all values.");
      }
    }
  }

  Future<void> _savePurchaseBill(PurchaseProvider provider) async {
    if (provider.items.isEmpty) {
      _showErrorSnackbar("No items added yet");
      return;
    }

    if (_supplierNameController.text.isEmpty) {
      _showErrorSnackbar("Please enter supplier information");
      setState(() {
        _showSupplierForm = true;
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final bill = PurchaseBill(
        billNumber: _billNumberController.text,
        billDate: _billDateController.text,
        supplierName: _supplierNameController.text,
        supplierAddress: _supplierAddressController.text,
        supplierGstNumber: _supplierGstController.text,
        supplierPhone: _supplierPhoneController.text,
        items: provider.items,
        totalAmount: provider.totalAmount,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      final String? savedId = await _dbService.savePurchaseBill(bill.toMap());

      if (savedId != null) {
        _showSuccessSnackbar("Purchase bill saved successfully!");
        provider.clearPurchase();
        _clearAllFields();
      } else {
        _showErrorSnackbar("Failed to save purchase bill. Please try again.");
      }
    } catch (e) {
      _showErrorSnackbar("Error: $e");
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showPurchaseHistory() async {
    final bills = await _dbService.getAllPurchaseBills();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: bills.isEmpty
              ? const Center(child: Text('No purchase bills found'))
              : ListView.builder(
                  itemCount: bills.length,
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(bill['billNumber'] ?? 'N/A'),
                        subtitle: Text(
                            '${bill['supplierName']} - ₹${bill['totalAmount']?.toStringAsFixed(2)}'),
                        trailing: Text(bill['billDate'] ?? ''),
                        onTap: () {
                          // Navigate to view bill details
                          Navigator.pop(context);
                          _showBillDetails(bill);
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBillDetails(Map<String, dynamic> bill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bill ${bill['billNumber']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Date: ${bill['billDate']}'),
              Text('Supplier: ${bill['supplierName']}'),
              if (bill['supplierAddress']?.isNotEmpty ?? false)
                Text('Address: ${bill['supplierAddress']}'),
              const Divider(),
              Text('Subtotal: ₹${bill['subtotal']?.toStringAsFixed(2)}'),
              Text('CGST: ₹${bill['cgst']?.toStringAsFixed(2)}'),
              Text('SGST: ₹${bill['sgst']?.toStringAsFixed(2)}'),
              Text('Total: ₹${bill['totalAmount']?.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (bill['notes']?.isNotEmpty ?? false) ...[
                const Divider(),
                Text('Notes: ${bill['notes']}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _clearAllFields() {
    _descriptionController.clear();
    _hsnCodeController.clear();
    _quantityController.clear();
    _rateController.clear();
    _supplierNameController.clear();
    _supplierAddressController.clear();
    _supplierGstController.clear();
    _supplierPhoneController.clear();
    _notesController.clear();

    _initializeBill();

    setState(() {
      _selectedTaxRate = 18.0;
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDialog(
      BuildContext context, String title, String content, Function onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => onConfirm(),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
