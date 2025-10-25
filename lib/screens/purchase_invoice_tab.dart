import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import 'invoice_detail_screen.dart';

class PurchaseInvoicesTab extends StatefulWidget {
  const PurchaseInvoicesTab({super.key});

  @override
  State<PurchaseInvoicesTab> createState() => _PurchaseInvoicesTabState();
}

class _PurchaseInvoicesTabState extends State<PurchaseInvoicesTab> {
  final FirebaseService _dbService = FirebaseService.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(child: _buildPurchaseList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by bill number or supplier...',
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
    );
  }

  Widget _buildPurchaseList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _searchQuery.isEmpty
          ? _dbService.getAllPurchaseBills()
          : _dbService.searchPurchaseBills(_searchQuery),
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

        final bills = snapshot.data ?? [];

        if (bills.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No purchase bills yet'
                      : 'No bills found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bills.length,
          itemBuilder: (context, index) {
            return _buildPurchaseCard(bills[index]);
          },
        );
      },
    );
  }

  Widget _buildPurchaseCard(Map<String, dynamic> bill) {
    final billNumber = bill['billNumber'] ?? 'N/A';
    final date = bill['billDate'] ?? '';
    final supplierName = bill['supplierName'] ?? 'Unknown';
    final totalAmount = bill['totalAmount'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPurchaseDetails(bill),
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
                          billNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
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
                      ],
                    ),
                  ),
                  Text(
                    '₹${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      supplierName,
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

  void _showPurchaseDetails(Map<String, dynamic> bill) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailScreen(
          invoice: bill,
          type: 'purchase',
        ),
      ),
    );
  }
}