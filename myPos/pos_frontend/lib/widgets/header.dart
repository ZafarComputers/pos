// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  void _showAddNewMenu(BuildContext context, Offset position) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      constraints: const BoxConstraints(maxWidth: 500),
      items: [
        PopupMenuItem(
          enabled: false, // disable default tap
          child: SizedBox(
            width: 480,
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildGridItem(context, Icons.category, "Category", "/category"),
                _buildGridItem(context, Icons.inventory, "Product", "/product"),
                _buildGridItem(context, Icons.shopping_cart, "Purchase", "/purchase"),
                _buildGridItem(context, Icons.point_of_sale, "Sale", "/sale"),
                _buildGridItem(context, Icons.receipt_long, "Expense", "/expense"),
                _buildGridItem(context, Icons.insert_drive_file, "Quotation", "/quotation"),
                _buildGridItem(context, Icons.undo, "Return", "/return"),
                _buildGridItem(context, Icons.person, "User", "/user"),
                _buildGridItem(context, Icons.people, "Customer", "/customer"),
                _buildGridItem(context, Icons.business_center, "Biller", "/biller"),
                _buildGridItem(context, Icons.local_shipping, "Supplier", "/supplier"),
                _buildGridItem(context, Icons.transform, "Transfer", "/transfer"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildGridItem(BuildContext context, IconData icon, String title, String route) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade100,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.blueGrey),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const FlutterLogo(size: 40),

          // Left-side icons
          const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),

          // Right side section
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
                'User Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),

              // Add New button
              Builder(
                builder: (ctx) {
                  return ElevatedButton.icon(
                    onPressed: () {
                      final RenderBox button = ctx.findRenderObject() as RenderBox;
                      final Offset position = button.localToGlobal(Offset.zero) + Offset(0, button.size.height);
                      _showAddNewMenu(ctx, position);
                    },
                    icon: const Icon(Icons.add, size: 20, color: Colors.white),
                    label: const Text("Add New"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),

              // POS Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, "/pos");
                },
                icon: const Icon(Icons.point_of_sale, size: 20, color: Colors.white),
                label: const Text("POS"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Notification icons
              const Icon(Icons.notifications, color: Colors.grey),
              const SizedBox(width: 16),
              const Icon(Icons.notifications, color: Colors.grey),
              const SizedBox(width: 16),
              const Icon(Icons.notifications, color: Colors.grey),
              const SizedBox(width: 16),
              const Icon(Icons.notifications, color: Colors.grey),
              const SizedBox(width: 8),

              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
