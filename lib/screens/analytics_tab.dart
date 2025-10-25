import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/firebase_service.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  final FirebaseService _dbService = FirebaseService.instance;
  String _selectedPeriod = 'month'; // month, quarter, year

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          _buildOverviewCards(),
          const SizedBox(height: 20),
          _buildRevenueCard(),
          const SizedBox(height: 20),
          _buildTopCustomersCard(),
          const SizedBox(height: 20),
          _buildMonthlyTrendCard(),
          const SizedBox(height: 20),
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text(
              'Period: ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('This Month'),
                    selected: _selectedPeriod == 'month',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedPeriod = 'month');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Quarter'),
                    selected: _selectedPeriod == 'quarter',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedPeriod = 'quarter');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Year'),
                    selected: _selectedPeriod == 'year',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedPeriod = 'year');
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

  Widget _buildOverviewCards() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getAnalyticsData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? {};
        final totalSales = data['totalSales'] ?? 0.0;
        final totalPurchases = data['totalPurchases'] ?? 0.0;
        final profit = totalSales - totalPurchases;
        final invoiceCount = data['invoiceCount'] ?? 0;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Sales',
                    '₹${totalSales.toStringAsFixed(2)}',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Purchase',
                    '₹${totalPurchases.toStringAsFixed(2)}',
                    Icons.shopping_cart,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Net Profit',
                    '₹${profit.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    profit >= 0 ? Colors.blue : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Invoices',
                    invoiceCount.toString(),
                    Icons.receipt,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _getAnalyticsData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data ?? {};
                final sales = data['totalSales'] ?? 0.0;
                final purchases = data['totalPurchases'] ?? 0.0;
                final total = sales + purchases;
                final salesPercent = total > 0 ? (sales / total * 100) : 0;

                return Column(
                  children: [
                    _buildProgressBar('Sales', sales, salesPercent, Colors.green),
                    const SizedBox(height: 12),
                    _buildProgressBar(
                      'Purchases',
                      purchases,
                      (100 - salesPercent).toDouble(),
                      Colors.orange,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
      String label,
      double amount,
      double percent,
      Color color,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '₹${amount.toStringAsFixed(2)} (${percent.toStringAsFixed(1)}%)',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTopCustomersCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Customers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getTopCustomers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final customers = snapshot.data ?? [];

                if (customers.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No customer data available'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: customers.length > 5 ? 5 : customers.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        customer['name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('${customer['count']} invoices'),
                      trailing: Text(
                        '₹${customer['total'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getMonthlyTrend(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final trends = snapshot.data ?? [];

                if (trends.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No trend data available'),
                    ),
                  );
                }

                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: trends.length,
                    itemBuilder: (context, index) {
                      final trend = trends[index];
                      final maxAmount = trends
                          .map((t) => t['amount'] as double)
                          .reduce((a, b) => a > b ? a : b);
                      final height =
                      (trend['amount'] / maxAmount * 150).clamp(20.0, 150.0);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '₹${(trend['amount'] / 1000).toStringAsFixed(1)}K',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 40,
                              height: height,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.indigo,
                                    Colors.indigo.withOpacity(0.5),
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              trend['month'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Switch to sales tab
                    DefaultTabController.of(context).animateTo(0);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _dbService.getRecentInvoices(days: 7),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final invoices = snapshot.data ?? [];

                if (invoices.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No recent activity'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: invoices.length > 5 ? 5 : invoices.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt, color: Colors.green),
                      ),
                      title: Text(
                        invoice['invoiceNumber'] ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(invoice['customerName'] ?? 'Unknown'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${invoice['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            invoice['invoiceDate'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getAnalyticsData() async {
    DateTime startDate;
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case 'quarter':
        startDate = DateTime(now.year, now.month - 3, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'month':
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    final totalSales =
    await _dbService.getTotalSales(startDate: startDate, endDate: now);
    final totalPurchases =
    await _dbService.getTotalPurchases(startDate: startDate, endDate: now);
    final invoiceCount = await _dbService.getInvoiceCount();

    return {
      'totalSales': totalSales,
      'totalPurchases': totalPurchases,
      'invoiceCount': invoiceCount,
    };
  }

  Future<List<Map<String, dynamic>>> _getTopCustomers() async {
    final invoices = await _dbService.getAllInvoices();
    final customerTotals = <String, Map<String, dynamic>>{};

    for (var invoice in invoices) {
      final name = invoice['customerName'] ?? 'Unknown';
      final amount = invoice['totalAmount'] ?? 0.0;

      if (customerTotals.containsKey(name)) {
        customerTotals[name]!['total'] += amount;
        customerTotals[name]!['count']++;
      } else {
        customerTotals[name] = {'name': name, 'total': amount, 'count': 1};
      }
    }

    final sortedCustomers = customerTotals.values.toList()
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

    return sortedCustomers;
  }

  Future<List<Map<String, dynamic>>> _getMonthlyTrend() async {
    final now = DateTime.now();
    final months = <Map<String, dynamic>>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);

      final sales = await _dbService.getTotalSales(
        startDate: month,
        endDate: nextMonth,
      );

      months.add({
        'month': DateFormat('MMM').format(month),
        'amount': sales,
      });
    }

    return months;
  }
}