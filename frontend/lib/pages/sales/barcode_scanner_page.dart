import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/product.dart';
import '../../services/inventory_service.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;
  String _scannedBarcode = '';
  Product? _foundProduct;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Start scanning automatically
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        setState(() {
          _isScanning = false;
          _scannedBarcode = barcode.rawValue!;
        });

        // Search for product with this barcode
        _searchProductByBarcode(_scannedBarcode);
      }
    }
  }

  Future<void> _searchProductByBarcode(String barcode) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all products and search for the barcode
      final products = await InventoryService.getProducts(limit: 1000);

      final foundProduct = products.data.firstWhere(
        (product) => product.barcode.toLowerCase() == barcode.toLowerCase(),
        orElse: () => Product(
          id: 0,
          title: '',
          designCode: '',
          imagePath: '',
          imagePaths: [],
          subCategoryId: '',
          salePrice: '0.00',
          openingStockQuantity: '0',
          vendorId: '',
          vendor: ProductVendor.empty(),
          barcode: '',
          status: '',
          createdAt: '',
          updatedAt: '',
        ),
      );

      if (foundProduct.id != 0) {
        setState(() {
          _foundProduct = foundProduct;
        });
      } else {
        // Product not found, show error
        _showProductNotFoundDialog();
      }
    } catch (e) {
      print('Error searching for product: $e');
      _showErrorDialog('Error searching for product. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showProductNotFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Not Found'),
        content: Text('No product found with barcode: $_scannedBarcode'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            child: const Text('Scan Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to POS
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _scannedBarcode = '';
      _foundProduct = null;
      _isLoading = false;
    });
  }

  void _addProductToCart() {
    if (_foundProduct != null) {
      // Return the product to the POS page
      Navigator.of(context).pop(_foundProduct);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product Barcode'),
        backgroundColor: const Color(0xFF0D1845),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner View
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(controller: controller, onDetect: _onDetect),
                // Overlay with scanning frame
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isScanning ? Colors.green : Colors.red,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          _isScanning
                              ? Icons.qr_code_scanner
                              : Icons.check_circle,
                          color: _isScanning ? Colors.green : Colors.red,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                ),
                // Status text
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isScanning
                            ? 'Position barcode within the frame'
                            : 'Barcode detected: $_scannedBarcode',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product Info / Loading / Actions
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Searching for product...'),
                        ],
                      ),
                    )
                  : _foundProduct != null
                  ? _buildProductInfo()
                  : _buildInstructions(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          _scannedBarcode.isEmpty
              ? 'Scan a product barcode to add it to cart'
              : 'Searching for product with barcode: $_scannedBarcode',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _resetScanner,
          icon: const Icon(Icons.refresh),
          label: const Text('Scan Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D1845),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    if (_foundProduct == null) return const SizedBox.shrink();

    final price = double.tryParse(_foundProduct!.salePrice) ?? 0.0;
    final stock = int.tryParse(_foundProduct!.openingStockQuantity) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Found',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1845),
          ),
        ),
        const SizedBox(height: 16),

        // Product Image
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1845).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _foundProduct!.imagePath?.isNotEmpty ?? false
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _foundProduct!.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.inventory_2, size: 40),
                    ),
                  )
                : const Icon(
                    Icons.inventory_2,
                    size: 40,
                    color: Color(0xFF0D1845),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Product Details
        Text(
          _foundProduct!.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Text(
              'Rs${price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Stock: $stock',
              style: TextStyle(
                fontSize: 14,
                color: stock > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          'Barcode: $_scannedBarcode',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),

        const Spacer(),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetScanner,
                child: const Text('Scan Again'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: stock > 0 ? _addProductToCart : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to Cart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1845),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
