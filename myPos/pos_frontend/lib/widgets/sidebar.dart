// lib/widgets/sidebar.dart
import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final Function(String) onMenuItemSelected;

  Sidebar({super.key, required this.onMenuItemSelected});

  final List<Map<String, dynamic>> _menuSections = [
    {
      'title': 'Main',
      'items': ['Dashboard'],
    },
    {
      'title': 'Inventory',
      'items': [
        'Products',
        'Expired Products',
        'Low Stock',
        'Category',
        'Sub-Category',
        'Brands',
        'Variants',
        'Attributes',
        'Barcode',
        'QR Code',
      ],
    },
    {
      'title': 'Sales',
      'items': ['POS Sales', 'Invoice', 'Sales Return'],
    },
    {
      'title': 'Purchases',
      'items': ['Purchases', 'Purchase Order', 'Purchase Return'],
    },
    {
      'title': 'Finance & Accounts',
      'items': [
        'Expense',
        'Expense Category',
        'Income',
        'Income Category',
        'Bank Account',
        'Balance Sheet',
        'Trial Balance',
        'Cashflow',
        'Account Statement',
      ],
    },
    {
      'title': 'People',
      'items': ['Customers', 'Suppliers', 'Employees'],
    },
    {
      'title': 'Reports',
      'items': [
        'Sales Report',
        'Purchase Report',
        'Inventory Report',
        'Invoice Report',
        'Supplier Report',
        'Customer Report',
        'Product Report',
        'Expense Report',
        'Income Report',
      ],
    },
    {
      'title': 'User Management',
      'items': ['Users', 'Roles & Permissions', 'Deleted Account Requests'],
    },
    {
      'title': 'Settings',
      'items': [
        'General Settings',
        'System Settings',
        'Financial Settings',
        'Logout',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _menuSections.map((section) {
            return Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  ...section['items'].map((item) {
                    return ListTile(
                      title: Text(item),
                      onTap: () => onMenuItemSelected(item),
                      contentPadding: const EdgeInsets.only(left: 16),
                      dense: true,
                    );
                  }),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}