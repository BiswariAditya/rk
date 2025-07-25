import 'package:flutter/material.dart';
import 'package:number_to_words/number_to_words.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/invoice_provider.dart';
import '../models/item.dart';
import '../services/csv_service.dart';
import '../services/pdf_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  
   createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerFormKey = GlobalKey<FormState>();

  // Item form controllers
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _breadthController = TextEditingController();
  final TextEditingController _hsnCodeController = TextEditingController();

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  // Customer info controllers
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerAddressController =
      TextEditingController();
  final TextEditingController _stateCodeController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  // Invoice details
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _invoiceDateController = TextEditingController();

  bool _showCustomerForm = false;

  // Tax rate options
  final List<double> _taxRateOptions = [5.0, 9.0, 12.0, 18.0];
  double _selectedTaxRate = 18.0;

  int _invoiceCount = 1;

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
    _stateCodeController.dispose();
    _gstNumberController.dispose();
    _phoneNumberController.dispose();
    _invoiceNumberController.dispose();
    _invoiceDateController.dispose();
    super.dispose();
  }

  Future<void> _initializeInvoice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get last invoice count, default to 1 if not found
    _invoiceCount = (prefs.getInt('invoice_count') ?? 0) + 1;

    // Set invoice number
    _invoiceNumberController.text = "RKA-$_invoiceCount";

    // Set invoice date to today
    _invoiceDateController.text =
        DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Save the new invoice count for next use
    await prefs.setInt('invoice_count', _invoiceCount);
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('R.K. Advertisers - BillSoft'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _showDialog(
                context,
                'Confirm Reset',
                'Are you sure you want to clear all items and customer information?',
                () {
                  invoiceProvider.clearInvoice();
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
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Invoice information
              _buildInvoiceInfoSection(),

              SizedBox(height: 20),

              // Customer section (collapsible)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showCustomerForm = !_showCustomerForm;
                  });
                },
                child: Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          "Customer Information",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: Icon(_showCustomerForm
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down),
                          onPressed: () {
                            setState(() {
                              _showCustomerForm = !_showCustomerForm;
                            });
                          },
                        ),
                      ),
                      if (_showCustomerForm)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildCustomerForm(),
                        ),
                      if (!_showCustomerForm &&
                          _customerNameController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Name: ${_customerNameController.text}"),
                              if (_customerAddressController.text.isNotEmpty)
                                Text(
                                    "Address: ${_customerAddressController.text}"),
                              if (_gstNumberController.text.isNotEmpty)
                                Text("GST No: ${_gstNumberController.text}"),
                              if (_phoneNumberController.text.isNotEmpty)
                                Text("Phone: ${_phoneNumberController.text}"),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Add items section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add New Item",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Form(
                        key: _formKey,
                        child: screenSize.width > 600
                            ? _buildWideItemForm()
                            : _buildNarrowItemForm(),
                      ),

                      SizedBox(height: 10),

                      // Add tax rate selection
                      Row(
                        children: [
                          Text(
                            "Tax Rate: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 10),
                          ...List.generate(_taxRateOptions.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text("${_taxRateOptions[index]}%"),
                                selected:
                                    _selectedTaxRate == _taxRateOptions[index],
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

                      SizedBox(height: 10),

                      Center(
                        child: ElevatedButton.icon(
                          icon: Icon(
                            Icons.add_circle,
                            color: Colors.white,
                          ),
                          label: Text('Add Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          onPressed: _addItem,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Item list
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Invoice Items",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Total Items: ${invoiceProvider.items.length}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: invoiceProvider.items.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text(
                                    "No items added yet",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  // Table header
                                  Container(
                                    color: Colors.grey.shade100,
                                    padding: EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 4,
                                            child: Text("Description",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        Expanded(
                                            flex: 2,
                                            child: Text("HSN",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        Expanded(
                                            flex: 2,
                                            child: Text("Size",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        Expanded(
                                            flex: 1,
                                            child: Text("Qty",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        Expanded(
                                            flex: 2,
                                            child: Text("Rate",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        Expanded(
                                            flex: 1,
                                            child: Text("Tax",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        Expanded(
                                            flex: 2,
                                            child: Text("Amount",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        SizedBox(width: 40),
                                      ],
                                    ),
                                  ),
                                  // Table rows
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: invoiceProvider.items.length,
                                    separatorBuilder: (context, index) =>
                                        Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final item = invoiceProvider.items[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 16),
                                        child: Row(
                                          children: [
                                            Expanded(
                                                flex: 4,
                                                child: Text(item.description)),
                                            Expanded(
                                                flex: 2,
                                                child: Text(
                                                    item.hsnCode.toString())),
                                            Expanded(
                                                flex: 2,
                                                child:
                                                    Text("${item.size} sqft")),
                                            Expanded(
                                                flex: 1,
                                                child: Text(
                                                    item.quantity.toString())),
                                            Expanded(
                                                flex: 2,
                                                child: Text(
                                                    "₹${item.rate.toStringAsFixed(2)}")),
                                            Expanded(
                                                flex: 1,
                                                child:
                                                    Text("${item.taxRate}%")),
                                            Expanded(
                                                flex: 2,
                                                child: Text(
                                                    "₹${item.amount.toStringAsFixed(2)}")),
                                            SizedBox(
                                              width: 40,
                                              child: IconButton(
                                                icon: Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () => invoiceProvider
                                                    .removeItem(index),
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
              ),

              SizedBox(height: 20),

              // Summary section
              if (invoiceProvider.items.isNotEmpty)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Invoice Summary",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Amount in words:",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Rupees ${NumberToWord().convert('en-in', invoiceProvider.totalAmount.toInt())} only',
                                    style:
                                        TextStyle(fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 200,
                              child: Column(
                                children: [
                                  _buildSummaryRow("Sub Total:",
                                      "₹${invoiceProvider.subtotal.toStringAsFixed(2)}"),
                                  _buildSummaryRow("CGST:",
                                      "₹${invoiceProvider.cgst.toStringAsFixed(2)}"),
                                  _buildSummaryRow("SGST:",
                                      "₹${invoiceProvider.sgst.toStringAsFixed(2)}"),
                                  Divider(),
                                  _buildSummaryRow(
                                    "Grand Total:",
                                    "₹${invoiceProvider.totalAmount.toStringAsFixed(2)}",
                                    isBold: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(
                      Icons.picture_as_pdf,
                      color: Colors.white,
                    ),
                    label: Text('Generate Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: invoiceProvider.items.isEmpty
                        ? null
                        : () => _generateInvoice(invoiceProvider),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: Icon(
                      Icons.save_alt,
                      color: Colors.white,
                    ),
                    label: Text('Export CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: invoiceProvider.items.isEmpty
                        ? null
                        : () => saveCsv(
                            items: invoiceProvider.items,
                            customerName: _customerNameController.text,
                            serialNo: _invoiceNumberController.text,
                            invoiceDate: _invoiceDateController.text),
                  ),
                ],
              ),

              SizedBox(height: 40),
              Container(
                color: Colors.indigo,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Built with ❤️ by RK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

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
                decoration: InputDecoration(
                  labelText: 'Invoice Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _invoiceDateController,
                decoration: InputDecoration(
                  labelText: 'Invoice Date',
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
                      _invoiceDateController.text =
                          DateFormat('dd/MM/yyyy').format(pickedDate);
                    });
                  }
                },
              ),
            ),
          ],
        ),
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
            decoration: InputDecoration(
              labelText: 'Customer Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) => value!.isEmpty ? 'Enter customer name' : null,
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _customerAddressController,
            decoration: InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 2,
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stateCodeController,
                  decoration: InputDecoration(
                    labelText: 'State Code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  maxLength: 15,
                  controller: _gstNumberController,
                  decoration: InputDecoration(
                    labelText: 'GST Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt_long),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextFormField(
            maxLength: 10,
            controller: _phoneNumberController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(
              Icons.save,
              color: Colors.white,
            ),
            label: Text('Save Customer Info'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              if (_customerFormKey.currentState!.validate()) {
                setState(() {
                  _showCustomerForm = false;
                });
              }
            },
          ),
        ],
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
            decoration: InputDecoration(
              labelText: 'Item Description',
              border: OutlineInputBorder(),
              hintText: 'e.g. Flex Banner',
            ),
            validator: (value) =>
                value!.isEmpty ? 'Enter item description' : null,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _hsnCodeController,
            decoration: InputDecoration(
              labelText: 'HSN Code',
              border: OutlineInputBorder(),
              hintText: 'e.g. 4911',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _lengthController,
            decoration: InputDecoration(
              labelText: 'Length (ft)',
              border: OutlineInputBorder(),
              hintText: 'e.g. 10',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _breadthController,
            decoration: InputDecoration(
              labelText: 'Breadth (ft)',
              border: OutlineInputBorder(),
              hintText: 'e.g. 6',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _rateController,
            decoration: InputDecoration(
              labelText: 'Rate (₹)',
              border: OutlineInputBorder(),
              hintText: 'e.g. 20',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(),
              hintText: 'e.g. 2',
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
          decoration: InputDecoration(
            labelText: 'Item Description',
            border: OutlineInputBorder(),
            hintText: 'e.g. Flex Banner',
          ),
          validator: (value) =>
              value!.isEmpty ? 'Enter item description' : null,
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _hsnCodeController,
                decoration: InputDecoration(
                  labelText: 'HSN Code',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 4911',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 2',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _lengthController,
                decoration: InputDecoration(
                  labelText: 'Length (ft)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 10',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _breadthController,
                decoration: InputDecoration(
                  labelText: 'Breadth (ft)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 6',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _rateController,
          decoration: InputDecoration(
            labelText: 'Rate (₹)',
            border: OutlineInputBorder(),
            hintText: 'e.g. 20',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    TextStyle style =
        isBold ? TextStyle(fontWeight: FontWeight.bold) : TextStyle();

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

  void _addItem() {
    if (_formKey.currentState!.validate()) {
      if (_lengthController.text.isEmpty ||
          _breadthController.text.isEmpty ||
          _quantityController.text.isEmpty ||
          _rateController.text.isEmpty) {
        _showErrorSnackbar("Please fill all required fields");
        return;
      }

      try {
        final invoiceProvider =
            Provider.of<InvoiceProvider>(context, listen: false);
        invoiceProvider.addItem(
          Item(
            description: _descriptionController.text,
            length: double.tryParse(_lengthController.text) ?? 0,
            breadth: double.tryParse(_breadthController.text) ?? 0,
            hsnCode: _hsnCodeController.text.isEmpty
                ? 0
                : int.tryParse(_hsnCodeController.text) ?? 0,
            quantity: int.tryParse(_quantityController.text) ?? 0,
            rate: double.tryParse(_rateController.text) ?? 0,
            taxRate: _selectedTaxRate, // Use the selected tax rate
          ),
        );

        // Clear item form
        _descriptionController.clear();
        _lengthController.clear();
        _breadthController.clear();
        _hsnCodeController.clear();
        _quantityController.clear();
        _rateController.clear();

        // Return focus to description field
        FocusScope.of(context).requestFocus(FocusNode());
      } catch (e) {
        _showErrorSnackbar("Invalid input. Please check all values.");
      }
    }
  }

  void _generateInvoice(InvoiceProvider provider) async {
    if (provider.items.isEmpty) {
      _showErrorSnackbar("No items added yet");
      return;
    }

    if (_customerNameController.text.isEmpty) {
      _showErrorSnackbar("Please enter customer information");
      setState(() {
        _showCustomerForm = true;
      });
      return;
    }

    await generatePdfInvoice(
      provider.items,
      _customerNameController.text,
      _customerAddressController.text,
      _stateCodeController.text,
      _gstNumberController.text,
      _phoneNumberController.text,
      _invoiceNumberController.text,
      _invoiceDateController.text,
      provider,
    );
    provider.clearInvoice();
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
    _stateCodeController.clear();
    _gstNumberController.clear();
    _phoneNumberController.clear();

    // Reset invoice number
    _invoiceNumberController.text = "RKA-${++_invoiceCount}";

    // Reset invoice date to today
    _invoiceDateController.text =
        DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Reset selected tax rate to default
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
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => onConfirm(),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
