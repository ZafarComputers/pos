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
import 'package:pos_frontend/models/brand_model.dart';

Future<void> generatePDF(
  BuildContext context, {
  required bool onlySelected,
  required List<Brand> filteredBrands,
  required List<bool> selectedBrands,
  required Function(String?) setLastGeneratedPdfPath,
}) async {
  final pdf = pw.Document();
  final headers = ['Name', 'Category', 'Created Date', 'Status'];
  final pdfBrands = onlySelected
      ? filteredBrands
          .asMap()
          .entries
          .where((e) => selectedBrands[e.key])
          .map((e) => e.value)
          .toList()
      : filteredBrands;

  if (pdfBrands.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          onlySelected ? "No records selected" : "No records available",
        ),
      ),
    );
    return;
  }

  final data = pdfBrands
      .map(
        (brand) => [
          brand.name,
          brand.category,
          brand.createdDate,
          brand.status,
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
      ..download = 'brands_${DateTime.now().millisecondsSinceEpoch}.pdf';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(filePath);
  } else {
    final output = await getApplicationDocumentsDirectory();
    filePath =
        "${output.path}/brands_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    await OpenFile.open(filePath);
  }
  setLastGeneratedPdfPath(filePath);
}

Future<void> generateExcel(
  BuildContext context, {
  required bool onlySelected,
  required List<Brand> filteredBrands,
  required List<bool> selectedBrands,
  required Function(String?) setLastGeneratedExcelPath,
}) async {
  try {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Brands'];

    // Add headers using TextCellValue
    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Category'),
      TextCellValue('Created Date'),
      TextCellValue('Status'),
    ]);

    // Add data
    final excelBrands = onlySelected
        ? filteredBrands
            .asMap()
            .entries
            .where((e) => selectedBrands[e.key])
            .map((e) => e.value)
            .toList()
        : filteredBrands;

    if (excelBrands.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            onlySelected ? "No records selected" : "No records available",
          ),
        ),
      );
      return;
    }

    for (final brand in excelBrands) {
      sheet.appendRow([
        TextCellValue(brand.name),
        TextCellValue(brand.category),
        TextCellValue(brand.createdDate),
        TextCellValue(brand.status),
      ]);
    }

    // Save the file
    final bytes = excel.encode()!;
    String filePath;
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      filePath = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = filePath
        ..download = 'brands_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(filePath);
    } else {
      final output = await getApplicationDocumentsDirectory();
      filePath = "${output.path}/brands_${DateTime.now().millisecondsSinceEpoch}.xlsx";
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

Future<void> generateAndOpenExcel(
  BuildContext context,
  String? lastGeneratedPdfPath,
  List<Brand> filteredBrands,
  List<bool> selectedBrands,
  bool onlySelected, // Added parameter
) async {
  await generateExcel(
    context,
    onlySelected: onlySelected,
    filteredBrands: filteredBrands,
    selectedBrands: selectedBrands,
    setLastGeneratedExcelPath: (path) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path != null
              ? 'Excel file generated at $path'
              : 'No Excel file generated'),
        ),
      );
    },
  );
}
