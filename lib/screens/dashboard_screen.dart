import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:number_to_words/number_to_words.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/item.dart';
import '../providers/invoice_provider.dart';
import '../services/csv_service.dart';
import '../services/pdf_service.dart';
import '../services/firebase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Form keys
  final _formKey = GlobalKey<FormState>();
  final _customerFormKey = GlobalKey<FormState>();

  // Controllers
  final _descriptionController = TextEditingController();
  final _lengthController = TextEditingController();
  final _breadthController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _invoiceDateController = TextEditingController();
  final _customerSearchController = TextEditingController();

  // State variables
  bool _showCustomerForm = false;
  bool _isProcessing = false;
  final bool _isSearchingCustomer = false;
  double _selectedTaxRate = 18.0;
  int _invoiceCount = 1;
  String? _selectedCustomerId;

  final List<double> _taxRateOptions = [5.0, 9.0, 12.0, 18.0];
  final FirebaseService _dbService = FirebaseService.instance;

  @override
  void initState() {
    super.initState();
    _initializeInvoice();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _lengthController.dispose();
    _breadthController.dispose();
    _hsnCodeController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _gstNumberController.dispose();
    _phoneNumberController.dispose();
    _invoiceNumberController.dispose();
    _invoiceDateController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }

  Future<void> _initializeInvoice() async {
    final prefs = await SharedPreferences.getInstance();
    _invoiceCount = (prefs.getInt('invoice_count') ?? 0) + 1;
    _invoiceNumberController.text = "RKA-$_invoiceCount";
    _invoiceDateController.text =
        DateFormat('dd/MM/yyyy').format(DateTime.now());
    await prefs.setInt('invoice_count', _invoiceCount);
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final roundedTotal = invoiceProvider.totalAmount.roundToDouble();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Create Invoice'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _showResetDialog(invoiceProvider),
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
              _buildInvoiceInfoSection(),
              const SizedBox(height: 20),
              _buildCustomerSection(),
              const SizedBox(height: 20),
              _buildAddItemSection(screenSize),
              const SizedBox(height: 20),
              _buildItemListSection(invoiceProvider),
              const SizedBox(height: 20),
              if (invoiceProvider.items.isNotEmpty)
                _buildSummarySection(invoiceProvider, roundedTotal),
              const SizedBox(height: 20),
              _buildActionButton(invoiceProvider),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== BUILD SECTIONS ====================

  Widget _buildInvoiceInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _invoiceNumberController,
                decoration: const InputDecoration(
                  labelText: 'Invoice Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _invoiceDateController,
                decoration: const InputDecoration(
                  labelText: 'Invoice Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectDate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            title: const Text(
              "Customer Information",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.indigo),
                  onPressed: _showCustomerSearchDialog,
                  tooltip: 'Search Customer',
                ),
                IconButton(
                  icon: Icon(_showCustomerForm
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down),
                  onPressed: () {
                    setState(() {
                      _showCustomerForm = !_showCustomerForm;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_showCustomerForm)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildCustomerForm(),
            ),
          if (!_showCustomerForm && _customerNameController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildCustomerPreview(),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerForm() {
    return Form(
      key: _customerFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _customerNameController,
            decoration: const InputDecoration(
              labelText: 'Customer Name *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Enter customer name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customerAddressController,
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
                  controller: _gstNumberController,
                  decoration: const InputDecoration(
                    labelText: 'GST Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt_long),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  maxLength: 10,
                  controller: _phoneNumberController,
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
            label: const Text('Save Customer Info'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: _saveCustomerInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Name', _customerNameController.text),
        if (_customerAddressController.text.isNotEmpty)
          _buildInfoRow('Address', _customerAddressController.text),
        if (_gstNumberController.text.isNotEmpty)
          _buildInfoRow('GST No', _gstNumberController.text),
        if (_phoneNumberController.text.isNotEmpty)
          _buildInfoRow('Phone', _phoneNumberController.text),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
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
              "Add New Item",
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
            _buildTaxRateSelector(),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle, color: Colors.white),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
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

  Widget _buildTaxRateSelector() {
    return Wrap(
      spacing: 8,
      children: [
        const Text('Tax Rate: ', style: TextStyle(fontWeight: FontWeight.bold)),
        ..._taxRateOptions.map((rate) => ChoiceChip(
              label: Text('${rate.toStringAsFixed(0)}%'),
              selected: _selectedTaxRate == rate,
              onSelected: (selected) {
                if (selected) setState(() => _selectedTaxRate = rate);
              },
            )),
      ],
    );
  }

  Widget _buildItemListSection(InvoiceProvider invoiceProvider) {
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
                const Text('Invoice Items',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Total Items: ${invoiceProvider.items.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: invoiceProvider.items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('No items added yet',
                            style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic)),
                      ),
                    )
                  : _buildItemTable(invoiceProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTable(InvoiceProvider invoiceProvider) {
    return Column(
      children: [
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: const [
              Expanded(
                  flex: 4,
                  child: Text('Description',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 2,
                  child: Text('HSN',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 2,
                  child: Text('Size',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 1,
                  child: Text('Qty',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 2,
                  child: Text('Rate',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 1,
                  child: Text('Tax',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 2,
                  child: Text('Amount',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 40),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: invoiceProvider.items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = invoiceProvider.items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Expanded(flex: 4, child: Text(item.description)),
                  Expanded(flex: 2, child: Text(item.hsnCode.toString())),
                  Expanded(
                      flex: 2,
                      child: Text('${item.size.toStringAsFixed(1)} sqft')),
                  Expanded(flex: 1, child: Text(item.quantity.toString())),
                  Expanded(
                      flex: 2, child: Text('₹${item.rate.toStringAsFixed(2)}')),
                  Expanded(
                      flex: 1,
                      child: Text('${item.taxRate.toStringAsFixed(0)}%')),
                  Expanded(
                      flex: 2,
                      child: Text('₹${item.amount.toStringAsFixed(2)}')),
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => invoiceProvider.removeItem(index),
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
    );
  }

  Widget _buildSummarySection(
      InvoiceProvider invoiceProvider, double roundedTotal) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Invoice Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Amount in words:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Rupees ${NumberToWord().convert('en-in', roundedTotal.toInt())} only',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      _buildSummaryRow('Sub Total',
                          '₹${invoiceProvider.subtotal.toStringAsFixed(2)}'),
                      _buildSummaryRow('CGST',
                          '₹${invoiceProvider.cgst.toStringAsFixed(2)}'),
                      _buildSummaryRow('SGST',
                          '₹${invoiceProvider.sgst.toStringAsFixed(2)}'),
                      const Divider(),
                      _buildSummaryRow(
                          'Grand Total', '₹${roundedTotal.toStringAsFixed(0)}',
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
    final style = isBold
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

  Widget _buildActionButton(InvoiceProvider invoiceProvider) {
    return Center(
      child: ElevatedButton.icon(
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.save_alt, color: Colors.white, size: 24),
        label: Text(
          _isProcessing ? 'Processing...' : 'Generate & Save Invoice',
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(250, 50),
        ),
        onPressed: invoiceProvider.items.isEmpty || _isProcessing
            ? null
            : () => _processCompleteInvoice(invoiceProvider),
      ),
    );
  }

  // ==================== FORM BUILDERS ====================

  Widget _buildWideItemForm() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Item Description *',
              border: OutlineInputBorder(),
              hintText: 'e.g. Flex Banner',
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Enter description' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _hsnCodeController,
            decoration: const InputDecoration(
              labelText: 'HSN',
              border: OutlineInputBorder(),
              hintText: '4911',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _lengthController,
            decoration: const InputDecoration(
              labelText: 'Length (ft) *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _breadthController,
            decoration: const InputDecoration(
              labelText: 'Breadth (ft) *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _rateController,
            decoration: const InputDecoration(
              labelText: 'Rate (₹) *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Quantity *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
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
            labelText: 'Item Description *',
            border: OutlineInputBorder(),
            hintText: 'e.g. Flex Banner',
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Enter description' : null,
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
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _lengthController,
                decoration: const InputDecoration(
                  labelText: 'Length (ft) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _breadthController,
                decoration: const InputDecoration(
                  labelText: 'Breadth (ft) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _rateController,
          decoration: const InputDecoration(
            labelText: 'Rate (₹) *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
      ],
    );
  }

  // ==================== ACTIONS ====================

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _invoiceDateController.text =
            DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  void _saveCustomerInfo() {
    if (_customerFormKey.currentState!.validate()) {
      setState(() => _showCustomerForm = false);
      _dbService.saveCustomer({
        'name': _customerNameController.text,
        'address': _customerAddressController.text,
        'gstNumber': _gstNumberController.text,
        'phoneNumber': _phoneNumberController.text,
      });
      _showSnackbar('Customer information saved', isSuccess: true);
    }
  }

  void _addItem() {
    if (!_formKey.currentState!.validate()) return;

    try {
      final invoiceProvider =
          Provider.of<InvoiceProvider>(context, listen: false);
      invoiceProvider.addItem(
        Item(
          description: _descriptionController.text,
          length: double.parse(_lengthController.text),
          breadth: double.parse(_breadthController.text),
          hsnCode: int.tryParse(_hsnCodeController.text) ?? 0,
          quantity: int.parse(_quantityController.text),
          rate: double.parse(_rateController.text),
          taxRate: _selectedTaxRate,
        ),
      );

      // Clear form
      _descriptionController.clear();
      _lengthController.clear();
      _breadthController.clear();
      _hsnCodeController.clear();
      _quantityController.clear();
      _rateController.clear();

      FocusScope.of(context).requestFocus(FocusNode());
      _showSnackbar('Item added successfully', isSuccess: true);
    } catch (e) {
      _showSnackbar('Invalid input. Please check all values.');
    }
  }

  Future<void> _processCompleteInvoice(InvoiceProvider provider) async {
    // Validation
    if (provider.items.isEmpty) {
      _showSnackbar('No items added yet');
      return;
    }

    if (_customerNameController.text.isEmpty) {
      _showSnackbar('Please enter customer information');
      setState(() => _showCustomerForm = true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // STEP 1: Save Invoice to MongoDB
      final invoiceData = _prepareInvoiceData(provider);
      final String? savedId = await _dbService.saveInvoice(invoiceData);
      if (savedId == null) {
        throw 'Failed to save invoice to database';
      }

      _showSnackbar('✓ Step 1/4: Invoice saved to database', isSuccess: true);
      await Future.delayed(const Duration(milliseconds: 500));

      // STEP 2: Save/Update Customer
      await _saveOrUpdateCustomer();
      _showSnackbar('✓ Step 2/4: Customer information saved', isSuccess: true);
      await Future.delayed(const Duration(milliseconds: 500));

      // STEP 3: Export to CSV
      try {
        await saveCsv(
          items: provider.items,
          customerName: _customerNameController.text,
          serialNo: _invoiceNumberController.text,
          invoiceDate: _invoiceDateController.text,
        );
        _showSnackbar('✓ Step 3/4: Data exported to CSV', isSuccess: true);
      } catch (e) {
        _showSnackbar('Warning: CSV export failed', isSuccess: false);
      }
      await Future.delayed(const Duration(milliseconds: 500));

      // STEP 4: Generate PDF
      await generatePdfInvoice(
        provider.items,
        _customerNameController.text,
        _customerAddressController.text,
        _gstNumberController.text,
        _phoneNumberController.text,
        _invoiceNumberController.text,
        _invoiceDateController.text,
        provider,
      );

      _showSnackbar('✓ Step 4/4: PDF generated successfully!', isSuccess: true);

      // Clear all data
      provider.clearInvoice();
      _clearAllFields();

      // Show success dialog
      _showSuccessDialog();
    } catch (e) {
      _showSnackbar('Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Map<String, dynamic> _prepareInvoiceData(InvoiceProvider provider) {
    return {
      'invoiceNumber': _invoiceNumberController.text,
      'invoiceDate': _invoiceDateController.text,
      'customerName': _customerNameController.text,
      'customerAddress': _customerAddressController.text,
      'gstNumber': _gstNumberController.text,
      'phoneNumber': _phoneNumberController.text,
      'customerId': _selectedCustomerId,
      'items': provider.items
          .map((item) => {
                'description': item.description,
                'length': item.length,
                'breadth': item.breadth,
                'hsnCode': item.hsnCode,
                'quantity': item.quantity,
                'rate': item.rate,
                'taxRate': item.taxRate,
                'size': item.size,
                'amount': item.amount,
              })
          .toList(),
      'subtotal': provider.subtotal,
      'cgst': provider.cgst,
      'sgst': provider.sgst,
      'totalAmount': provider.totalAmount,
    };
  }

  Future<void> _saveOrUpdateCustomer() async {
    final customerData = {
      'name': _customerNameController.text,
      'address': _customerAddressController.text,
      'gstNumber': _gstNumberController.text,
      'phoneNumber': _phoneNumberController.text,
    };

    // Check if customer already exists
    if (_selectedCustomerId != null) {
      await _dbService.updateCustomer(_selectedCustomerId!, customerData);
    } else {
      // Search for existing customer
      final existingCustomers =
          await _dbService.searchCustomers(_customerNameController.text);

      if (existingCustomers.isEmpty) {
        // New customer, save to database
        await _dbService.saveCustomer(customerData);
      }
    }
  }

  void _showCustomerSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Search Customer',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _customerSearchController,
                decoration: InputDecoration(
                  labelText: 'Search by Name or GST Number',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _customerSearchController.clear();
                      setState(() {});
                    },
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _customerSearchController.text.isEmpty
                      ? _dbService.getAllCustomers()
                      : _dbService
                          .searchCustomers(_customerSearchController.text),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final customers = snapshot.data ?? [];

                    if (customers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('No customers found'),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add New Customer'),
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() => _showCustomerForm = true);
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo,
                              child: Text(
                                customer['name']
                                        ?.toString()
                                        .substring(0, 1)
                                        .toUpperCase() ??
                                    'C',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              customer['name'] ?? 'N/A',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (customer['gstNumber']?.isNotEmpty ?? false)
                                  Text('GST: ${customer['gstNumber']}'),
                                if (customer['phoneNumber']?.isNotEmpty ??
                                    false)
                                  Text('Phone: ${customer['phoneNumber']}'),
                              ],
                            ),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              _fillCustomerData(customer);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fillCustomerData(Map<String, dynamic> customer) {
    setState(() {
      _selectedCustomerId = customer['_id']?.toString();
      _customerNameController.text = customer['name'] ?? '';
      _customerAddressController.text = customer['address'] ?? '';
      _gstNumberController.text = customer['gstNumber'] ?? '';
      _phoneNumberController.text = customer['phoneNumber'] ?? '';
      _showCustomerForm = false;
    });
    _showSnackbar('Customer loaded successfully', isSuccess: true);
  }

  void _clearAllFields() {
    _descriptionController.clear();
    _lengthController.clear();
    _breadthController.clear();
    _hsnCodeController.clear();
    _quantityController.clear();
    _rateController.clear();
    _customerNameController.clear();
    _customerAddressController.clear();
    _gstNumberController.clear();
    _phoneNumberController.clear();
    _customerSearchController.clear();

    _selectedCustomerId = null;

    _initializeInvoice();
    setState(() => _selectedTaxRate = 18.0);
  }

  void _showResetDialog(InvoiceProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reset'),
        content: const Text(
          'Are you sure you want to clear all items and customer information?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearInvoice();
              _clearAllFields();
              Navigator.pop(context);
              _showSnackbar('All data cleared', isSuccess: true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Invoice processed successfully:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 16),
            _SuccessCheckItem(text: 'Saved to database'),
            _SuccessCheckItem(text: 'Customer information saved'),
            _SuccessCheckItem(text: 'Exported to CSV'),
            _SuccessCheckItem(text: 'PDF generated'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, {bool isSuccess = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Helper widget for success dialog
class _SuccessCheckItem extends StatelessWidget {
  final String text;

  const _SuccessCheckItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
