import 'package:flutter/material.dart';
import 'package:rk_adv/screens/purchase_invoice_tab.dart';
import 'package:rk_adv/screens/sales_invoice_tab.dart';

import 'analytics_tab.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Invoices & Analytics'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Sales', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Purchase', icon: Icon(Icons.shopping_cart)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SalesInvoicesTab(),
          PurchaseInvoicesTab(),
          AnalyticsTab(),
        ],
      ),
    );
  }
}
