import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _dbService = FirebaseService.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.customer['name'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCustomer,
            tooltip: 'Edit Customer',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteCustomer,
            tooltip: 'Delete Customer',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Details', icon: Icon(Icons.info_outline)),
            Tab(text: 'Invoices', icon: Icon(Icons.receipt)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildInvoicesTab(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    final name = widget.customer['name'] ?? 'N/A';
    final address = widget.customer['address'] ?? '';
    final gst = widget.customer['gstNumber'] ?? '';
    final phone = widget.customer['phoneNumber'] ?? '';
    final createdAt = widget.customer['createdAt'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.indigo,
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.person, 'Name', name),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on, 'Address', address),
                  ],
                  if (gst.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.receipt_long, 'GST Number', gst),
                  ],
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.phone, 'Phone', phone),
                  ],
                  if (createdAt != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Created',
                      _dbService.formatDate(createdAt),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatisticsCard(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.indigo),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getCustomerInvoices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final invoices = snapshot.data ?? [];
        final totalInvoices = invoices.length;
        final totalAmount = invoices.fold<double>(
          0,
              (sum, invoice) => sum + (invoice['totalAmount'] ?? 0),
        );

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total Invoices',
                        totalInvoices.toString(),
                        Icons.receipt,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        'Total Amount',
                        '₹${totalAmount.toStringAsFixed(2)}',
                        Icons.currency_rupee,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getCustomerInvoices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final invoices = snapshot.data ?? [];

        if (invoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No invoices yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Invoices for this customer will appear here',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            return _buildInvoiceCard(invoice);
          },
        );
      },
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final invoiceNumber = invoice['invoiceNumber'] ?? 'N/A';
    final date = invoice['invoiceDate'] ?? '';
    final totalAmount = invoice['totalAmount'] ?? 0;
    final itemCount = (invoice['items'] as List?)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to invoice detail screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('View invoice: $invoiceNumber')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt,
                  color: Colors.indigo,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoiceNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$itemCount items',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getCustomerInvoices() async {
    final allInvoices = await _dbService.getAllInvoices();
    final customerName = widget.customer['name'];

    return allInvoices
        .where((invoice) => invoice['customerName'] == customerName)
        .toList();
  }

  void _editCustomer() {
    final nameController = TextEditingController(text: widget.customer['name']);
    final addressController =
    TextEditingController(text: widget.customer['address'] ?? '');
    final gstController =
    TextEditingController(text: widget.customer['gstNumber'] ?? '');
    final phoneController =
    TextEditingController(text: widget.customer['phoneNumber'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Customer'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: gstController,
                  decoration: const InputDecoration(
                    labelText: 'GST Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt_long),
                  ),
                  maxLength: 15,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _updateCustomer(
                  nameController.text,
                  addressController.text,
                  gstController.text,
                  phoneController.text,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCustomer(
      String name,
      String address,
      String gst,
      String phone,
      ) async {
    try {
      final customerId = widget.customer['id'];
      final success = await _dbService.updateCustomer(customerId, {
        'name': name,
        'address': address,
        'gstNumber': gst,
        'phoneNumber': phone,
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          widget.customer['name'] = name;
          widget.customer['address'] = address;
          widget.customer['gstNumber'] = gst;
          widget.customer['phoneNumber'] = phone;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteCustomer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text(
          'Are you sure you want to delete this customer? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete() async {
    try {
      final customerId = widget.customer['id'];
      final success = await _dbService.deleteCustomer(customerId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
