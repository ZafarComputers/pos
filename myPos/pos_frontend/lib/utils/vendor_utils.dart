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
import 'package:pos_frontend/models/vendor_model.dart';

// Generate a PDF file with vendor data
Future<void> generatePDF(
  BuildContext context, {
  required bool onlySelected,
  required List<VendorModel> filteredVendors,
  required List<bool> selectedVendors,
  required Function(String?) setLastGeneratedPdfPath,
}) async {
  final pdf = pw.Document();
  final headers = ['Name', 'Address', 'Created Date', 'Status'];
  final pdfVendors = onlySelected
      ? filteredVendors
          .asMap()
          .entries
          .where((e) => selectedVendors[e.key])
          .map((e) => e.value)
          .toList()
      : filteredVendors;

  if (pdfVendors.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          onlySelected ? "No records selected" : "No records available",
        ),
      ),
    );
    return;
  }

  final data = pdfVendors
      .map(
        (vendor) => [
          vendor.name,
          vendor.address,
          vendor.createdDate,
          vendor.status,
        ],
      )
      .toList();

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

  final bytes = await pdf.save();
  String filePath;
  if (kIsWeb) {
    final blob = html.Blob([bytes], 'application/pdf');
    filePath = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = filePath
      ..download = 'vendors_${DateTime.now().millisecondsSinceEpoch}.pdf';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(filePath);
  } else {
    final output = await getApplicationDocumentsDirectory();
    filePath =
        "${output.path}/vendors_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    await OpenFile.open(filePath);
  }
  setLastGeneratedPdfPath(filePath);
}

// Generate an Excel file with vendor data
Future<void> generateExcel(
  BuildContext context, {
  required bool onlySelected,
  required List<VendorModel> filteredVendors,
  required List<bool> selectedVendors,
  required Function(String?) setLastGeneratedExcelPath,
}) async {
  try {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Vendors'];

    // Add headers using TextCellValue
    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Address'),
      TextCellValue('Created Date'),
      TextCellValue('Status'),
    ]);

    // Add data
    final excelVendors = onlySelected
        ? filteredVendors
            .asMap()
            .entries
            .where((e) => selectedVendors[e.key])
            .map((e) => e.value)
            .toList()
        : filteredVendors;

    if (excelVendors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            onlySelected ? "No records selected" : "No records available",
          ),
        ),
      );
      return;
    }

    for (final vendor in excelVendors) {
      sheet.appendRow([
        TextCellValue(vendor.name),
        TextCellValue(vendor.address),
        TextCellValue(vendor.createdDate),
        TextCellValue(vendor.status),
      ]);
    }

    // Save the file
    final bytes = excel.encode();
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to generate Excel file. Please try again.")),
      );
      return;
    }

    String filePath;
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      filePath = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = filePath
        ..download = 'vendors_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(filePath);
    } else {
      final output = await getApplicationDocumentsDirectory();
      filePath = "${output.path}/vendors_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      await OpenFile.open(filePath);
    }

    setLastGeneratedExcelPath(filePath);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Excel exported successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to export Excel. Please try again.')),
    );
  }
}