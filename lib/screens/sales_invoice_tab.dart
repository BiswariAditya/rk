import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import 'invoice_detail_screen.dart';

class SalesInvoicesTab extends StatefulWidget {
  const SalesInvoicesTab({super.key});

  @override
  State<SalesInvoicesTab> createState() => _SalesInvoicesTabState();
}

class _SalesInvoicesTabState extends State<SalesInvoicesTab> {
  final FirebaseService _dbService = FirebaseService.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date'; // date, amount, customer

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(child: _buildInvoicesList()),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by invoice number or customer...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Sort by: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Date'),
                      selected: _sortBy == 'date',
                      onSelected: (selected) {
                        if (selected) setState(() => _sortBy = 'date');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Amount'),
                      selected: _sortBy == 'amount',
                      onSelected: (selected) {
                        if (selected) setState(() => _sortBy = 'amount');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Customer'),
                      selected: _sortBy == 'customer',
                      onSelected: (selected) {
                        if (selected) setState(() => _sortBy = 'customer');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getFilteredInvoices(),
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
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
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
                Text(
                  _searchQuery.isEmpty
                      ? 'No sales invoices yet'
                      : 'No invoices found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isEmpty
                      ? 'Create your first invoice to get started'
                      : 'Try a different search term',
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
            return _buildInvoiceCard(invoices[index]);
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getFilteredInvoices() async {
    List<Map<String, dynamic>> invoices;

    if (_searchQuery.isEmpty) {
      invoices = await _dbService.getAllInvoices();
    } else {
      invoices = await _dbService.searchInvoices(_searchQuery);
    }

    // Sort invoices
    invoices.sort((a, b) {
      switch (_sortBy) {
        case 'amount':
          return (b['totalAmount'] ?? 0).compareTo(a['totalAmount'] ?? 0);
        case 'customer':
          return (a['customerName'] ?? '').compareTo(b['customerName'] ?? '');
        case 'date':
        default:
        // Default: newest first
          final aDate = a['createdAt'];
          final bDate = b['createdAt'];
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
      }
    });

    return invoices;
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final invoiceNumber = invoice['invoiceNumber'] ?? 'N/A';
    final date = invoice['invoiceDate'] ?? '';
    final customerName = invoice['customerName'] ?? 'Unknown';
    final totalAmount = invoice['totalAmount'] ?? 0;
    final itemCount = (invoice['items'] as List?)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showInvoiceDetails(invoice),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoiceNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              date,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$itemCount items',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInvoiceDetails(Map<String, dynamic> invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailScreen(
          invoice: invoice,
          type: 'sales',
        ),
      ),
    );
  }
}