import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';
import '../../models/sub_category.dart';

class SubCategoryDetailPage extends StatefulWidget {
  final int subCategoryId;

  const SubCategoryDetailPage({super.key, required this.subCategoryId});

  @override
  State<SubCategoryDetailPage> createState() => _SubCategoryDetailPageState();
}

class _SubCategoryDetailPageState extends State<SubCategoryDetailPage> {
  SubCategory? subCategory;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSubCategoryDetails();
  }

  Future<void> _fetchSubCategoryDetails() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final fetchedSubCategory = await InventoryService.getSubCategory(
        widget.subCategoryId,
      );

      setState(() {
        subCategory = fetchedSubCategory;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sub Category Details'),
        backgroundColor: const Color(0xFF0D1845),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFFF8F9FA)],
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D1845)),
                ),
              )
            : errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Color(0xFFDC3545),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading sub category details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF343A40),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _fetchSubCategoryDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0D1845),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : subCategory == null
            ? const Center(child: Text('No sub category data available'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D1845), Color(0xFF0A1238)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF0D1845).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.inventory,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subCategory!.title,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        subCategory!.status.toLowerCase() ==
                                            'active'
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          subCategory!.status.toLowerCase() ==
                                              'active'
                                          ? Colors.green
                                          : Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    subCategory!.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          subCategory!.status.toLowerCase() ==
                                              'active'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Details Cards
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Information
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF0D1845),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Basic Information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF343A40),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildDetailRow(
                                  'ID',
                                  subCategory!.id.toString(),
                                ),
                                _buildDetailRow('Title', subCategory!.title),
                                _buildDetailRow('Status', subCategory!.status),
                                if (subCategory!.subCategoryCode != null)
                                  _buildDetailRow(
                                    'Code',
                                    subCategory!.subCategoryCode!,
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Category Information
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.category,
                                      color: Color(0xFF0D1845),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Category Information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF343A40),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                if (subCategory!.category != null) ...[
                                  _buildDetailRow(
                                    'Category ID',
                                    subCategory!.category!.id.toString(),
                                  ),
                                  _buildDetailRow(
                                    'Category Title',
                                    subCategory!.category!.title,
                                  ),
                                  _buildDetailRow(
                                    'Category Status',
                                    subCategory!.category!.status,
                                  ),
                                ] else ...[
                                  _buildDetailRow('Category', 'Not assigned'),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Timestamps
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Color(0xFF0D1845),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Timestamps',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF343A40),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildDetailRow(
                            'Created At',
                            _formatDate(subCategory!.createdAt),
                          ),
                          _buildDetailRow(
                            'Updated At',
                            _formatDate(subCategory!.updatedAt),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF343A40),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
