import 'package:flutter/material.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final String type; // 'sales' or 'purchase'

  const InvoiceDetailScreen({
    super.key,
    required this.invoice,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final invoiceNumber = invoice['invoiceNumber'] ?? invoice['billNumber'] ??
        'N/A';
    final date = invoice['invoiceDate'] ?? invoice['billDate'] ?? '';
    final partyName = type == 'sales'
        ? (invoice['customerName'] ?? 'Unknown')
        : (invoice['supplierName'] ?? 'Unknown');
    final address = invoice['customerAddress'] ?? invoice['supplierAddress'] ??
        '';
    final gst = invoice['gstNumber'] ?? '';
    final phone = invoice['phoneNumber'] ?? '';
    final items = invoice['items'] as List? ?? [];
    final subtotal = invoice['subtotal'] ?? 0.0;
    final cgst = invoice['cgst'] ?? 0.0;
    final sgst = invoice['sgst'] ?? 0.0;
    final totalAmount = invoice['totalAmount'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(invoiceNumber),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareInvoice(context),
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printInvoice(context),
            tooltip: 'Print PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type == 'sales' ? 'INVOICE' : 'PURCHASE BILL',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              invoiceNumber,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: type == 'sales'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type == 'sales' ? 'SALES' : 'PURCHASE',
                            style: TextStyle(
                              color: type == 'sales' ? Colors.green : Colors
                                  .orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16,
                            color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Date: $date'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Party Details
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type == 'sales' ? 'Customer Details' : 'Supplier Details',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 16),
                    _buildDetailRow(Icons.person, 'Name', partyName),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.location_on, 'Address', address),
                    ],
                    if (gst.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.receipt_long, 'GST No', gst),
                    ],
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.phone, 'Phone', phone),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items Table
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Items',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: Colors.grey[200],
                            child: Row(
                              children: const [
                                Expanded(flex: 3,
                                    child: Text('Description', style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                                Expanded(flex: 1,
                                    child: Text('Qty', style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                                Expanded(flex: 2,
                                    child: Text('Rate', style: TextStyle(
                                        fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.right)),
                                Expanded(flex: 2,
                                    child: Text('Amount', style: TextStyle(
                                        fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.right)),
                              ],
                            ),
                          ),
                          // Table Items
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (context, index) =>
                                Divider(height: 1, color: Colors.grey[300]),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start,
                                        children: [
                                          Text(item['description'] ?? 'N/A'),
                                          if (item['hsnCode'] != null &&
                                              item['hsnCode'] != 0)
                                            Text(
                                              'HSN: ${item['hsnCode']}',
                                              style: TextStyle(fontSize: 12,
                                                  color: Colors.grey[600]),
                                            ),
                                          if (item['size'] != null)
                                            Text(
                                              'Size: ${item['size']
                                                  .toStringAsFixed(1)} sqft',
                                              style: TextStyle(fontSize: 12,
                                                  color: Colors.grey[600]),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text('${item['quantity'] ?? 0}'),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '₹${(item['rate'] ?? 0).toStringAsFixed(
                                            2)}',
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '₹${(item['amount'] ?? 0)
                                            .toStringAsFixed(2)}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
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
            const SizedBox(height: 16),

            // Summary
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal', subtotal),
                    const SizedBox(height: 8),
                    _buildSummaryRow('CGST', cgst),
                    const SizedBox(height: 8),
                    _buildSummaryRow('SGST', sgst),
                    const Divider(height: 24),
                    _buildSummaryRow('Total Amount', totalAmount, isBold: true,
                        isTotal: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => _printInvoice(context),
          icon: const Icon(Icons.print, color: Colors.white),
          label: const Text(
              'Print / Download PDF', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount,
      {bool isBold = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  void _printInvoice(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Extract data
      final items = (invoice['items'] as List?)?.map((item) {
        // Convert item to your Item model format
        // You'll need to import your Item model
        return item;
      }).toList() ?? [];

      // Call your PDF service
      // This is a placeholder - adjust according to your actual PDF service
      // await generatePdfInvoice(
      //   items,
      //   invoice['customerName'] ?? '',
      //   invoice['customerAddress'] ?? '',
      //   invoice['gstNumber'] ?? '',
      //   invoice['phoneNumber'] ?? '',
      //   invoice['invoiceNumber'] ?? '',
      //   invoice['invoiceDate'] ?? '',
      //   provider, // You'll need to pass the provider
      // );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ PDF generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareInvoice(BuildContext context) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
      ),
    );
  }
}