// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io' show File;
import 'package:universal_html/html.dart' as html;
import 'package:pos_frontend/models/product_model.dart';

/// Generates a PDF report for the given product data.
///
/// [context] is the BuildContext for showing SnackBar messages.
/// [onlySelected] determines whether to export only selected items.
/// [filteredProducts] is the list of products to export.
/// [selectedProducts] indicates which items are selected (if [onlySelected] is true).
/// [setLastGeneratedPdfPath] updates the last generated PDF path.
Future<void> generatePDF(
  BuildContext context, {
  required bool onlySelected,
  required List<ProductModel> filteredProducts,
  required List<bool> selectedProducts,
  required Function(String?) setLastGeneratedPdfPath,
}) async {
  final pdf = pw.Document();
  final headers = [
    'Product Name',
    'Product Image',
    'Category',
    'Brand',
    'Price',
    'Quantity',
    'User Image',
    'Created By',
    'Status',
  ];

  final pdfProducts = onlySelected
      ? filteredProducts
          .asMap()
          .entries
          .where((entry) => selectedProducts[entry.key])
          .map((entry) => entry.value)
          .toList()
      : filteredProducts;

  if (pdfProducts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No products available to export')),
    );
    return;
  }

  final data = pdfProducts.map((product) => [
        product.nameProduct,
        product.imageProduct,
        product.category,
        product.vendor,
        product.price.toStringAsFixed(2),
        product.quantity.toString(),
        product.imageUser,
        product.createdBy,
        product.status,
      ]).toList();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => pw.TableHelper.fromTextArray(
        headers: headers,
        data: data,
        border: pw.TableBorder.all(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.all(4),
      ),
    ),
  );

  try {
    final bytes = await pdf.save();
    String filePath;
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      filePath = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: filePath)
        ..download = 'products_${DateTime.now().millisecondsSinceEpoch}.pdf';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(filePath);
    } else {
      final output = await getApplicationDocumentsDirectory();
      filePath = '${output.path}/products_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      await OpenFile.open(filePath);
    }
    setLastGeneratedPdfPath(filePath);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF exported to $filePath')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to generate PDF: $e')),
    );
  }
}

/// Generates an Excel report for the given product data.
///
/// [context] is the BuildContext for showing SnackBar messages.
/// [onlySelected] determines whether to export only selected items.
/// [filteredProducts] is the list of products to export.
/// [selectedProducts] indicates which items are selected (if [onlySelected] is true).
/// [setLastGeneratedExcelPath] updates the last generated Excel path.
Future<void> generateExcel(
  BuildContext context, {
  required bool onlySelected,
  required List<ProductModel> filteredProducts,
  required List<bool> selectedProducts,
  required Function(String?) setLastGeneratedExcelPath,
}) async {
  try {
    final excel = Excel.createExcel();
    final sheet = excel['Products'];

    // Add headers
    sheet.appendRow([
      TextCellValue('Product Name'),
      TextCellValue('Product Image'),
      TextCellValue('Category'),
      TextCellValue('Brand'),
      TextCellValue('Price'),
      TextCellValue('Quantity'),
      TextCellValue('User Image'),
      TextCellValue('Created By'),
      TextCellValue('Status'),
    ]);

    final excelProducts = onlySelected
        ? filteredProducts
            .asMap()
            .entries
            .where((entry) => selectedProducts[entry.key])
            .map((entry) => entry.value)
            .toList()
        : filteredProducts;

    if (excelProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products available to export')),
      );
      return;
    }

    for (final product in excelProducts) {
      sheet.appendRow([
        TextCellValue(product.nameProduct),
        TextCellValue(product.imageProduct),
        TextCellValue(product.category),
        TextCellValue(product.vendor),
        TextCellValue(product.price.toStringAsFixed(2)),
        TextCellValue(product.quantity.toString()),
        TextCellValue(product.imageUser),
        TextCellValue(product.createdBy),
        TextCellValue(product.status),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate Excel file')),
      );
      return;
    }

    String filePath;
    if (kIsWeb) {
      final blob = html.Blob(
        [bytes],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      filePath = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: filePath)
        ..download = 'products_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(filePath);
    } else {
      final output = await getApplicationDocumentsDirectory();
      filePath = '${output.path}/products_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      await OpenFile.open(filePath);
    }

    setLastGeneratedExcelPath(filePath);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Excel exported to $filePath')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error exporting Excel: $e')),
    );
  }
}