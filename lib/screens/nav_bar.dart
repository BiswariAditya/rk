import 'package:flutter/material.dart';
import 'package:rk_adv/screens/about_screen.dart';
import 'package:rk_adv/screens/customer_screen.dart';
import 'package:rk_adv/screens/dashboard_screen.dart';
import 'package:rk_adv/screens/purchase_screen.dart';
import 'package:sidebarx/sidebarx.dart';
import 'invoice_screen.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  final _sidebarController =
      SidebarXController(selectedIndex: 0, extended: true);

  @override
  void initState() {
    super.initState();
  }

  Widget _getSelectedScreen() {
    switch (_sidebarController.selectedIndex) {
      case 0:
        return DashboardScreen();
      case 1:
        return PurchaseScreen();
      case 2:
        return InvoicesScreen();
      case 3:
        return CustomerScreen();
      case 4:
        return AboutScreen();
      default:
        return DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarX(
            controller: _sidebarController,
            theme: SidebarXTheme(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(20),
              ),
              textStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              selectedTextStyle: const TextStyle(color: Colors.white),
              itemTextPadding: const EdgeInsets.only(left: 30),
              selectedItemTextPadding: const EdgeInsets.only(left: 30),
              itemDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.indigo),
              ),
              selectedItemDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.indigoAccent.withOpacity(0.37),
                ),
                gradient: const LinearGradient(
                  colors: [Colors.indigoAccent, Colors.indigo],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.28),
                    blurRadius: 30,
                  )
                ],
              ),
              iconTheme: IconThemeData(
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              selectedIconTheme: const IconThemeData(
                color: Colors.white,
                size: 20,
              ),
            ),
            extendedTheme: const SidebarXTheme(
              width: 250,
              decoration: BoxDecoration(
                color: Colors.indigo,
              ),
            ),
            footerDivider:
                Divider(color: Colors.white.withOpacity(0.3), height: 1),
            headerBuilder: (context, extended) {
              return SizedBox(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: extended
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'R.K. Advertisers',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Icon(Icons.business, color: Colors.white, size: 40),
                ),
              );
            },
            items: [
              SidebarXItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                onTap: () {
                  setState(() {
                    _sidebarController.selectIndex(0);
                  });
                },
              ),
              SidebarXItem(
                icon: Icons.shopping_cart,
                label: 'Purchases',
                onTap: () {
                  setState(() {
                    _sidebarController.selectIndex(1);
                  });
                },
              ),
              SidebarXItem(
                icon: Icons.receipt_long,
                label: 'Invoices',
                onTap: () {
                  setState(() {
                    _sidebarController.selectIndex(2);
                  });
                },
              ),
              SidebarXItem(
                icon: Icons.people,
                label: 'Customers',
                onTap: () {
                  setState(() {
                    _sidebarController.selectIndex(3);
                  });
                },
              ),
              SidebarXItem(
                icon: Icons.info_outline,
                label: 'About',
                onTap: () {
                  setState(() {
                    _sidebarController.selectIndex(4);
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _sidebarController,
              builder: (context, child) => _getSelectedScreen(),
            ),
          ),
        ],
      ),
    );
  }
}
