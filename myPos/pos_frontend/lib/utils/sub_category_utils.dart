// subCategory_utils.dart (fixed)
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
import 'package:pos_frontend/models/sub_category_model.dart';

Future<void> generatePDF(
  BuildContext context, {
  required bool onlySelected,
  required List<SubCategoryModel> filteredCategories,
  required List<bool> selectedCategories,
  required Function(String?) setLastGeneratedPdfPath,
}) async {
  final pdf = pw.Document();
  final headers = ['subCategory', 'Created Date', 'Status'];
  final pdfCategories = onlySelected
      ? filteredCategories
          .asMap()
          .entries
          .where((e) => selectedCategories[e.key])
          .map((e) => e.value)
          .toList()
      : filteredCategories;

  if (pdfCategories.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          onlySelected ? "No records selected" : "No records available",
        ),
      ),
    );
    return;
  }

  final data = pdfCategories
      .map(
        (subCategory) => [
          subCategory.subCategory,
          subCategory.category,
          subCategory.description,
          subCategory.createdDate,
          subCategory.status,
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
    final anchor = html.AnchorElement(href: filePath)
      ..download = 'categories_${DateTime.now().millisecondsSinceEpoch}.pdf';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(filePath);
  } else {
    final output = await getApplicationDocumentsDirectory();
    filePath =
        "${output.path}/categories_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    await OpenFile.open(filePath);
  }
  setLastGeneratedPdfPath(filePath);
}

Future<void> generateExcel(
  BuildContext context, {
  required bool onlySelected,
  required List<SubCategoryModel> filteredCategories,
  required List<bool> selectedCategories,
  required Function(String?) setLastGeneratedExcelPath,
}) async {
  try {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Categories'];

    // Add headers using TextCellValue
    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('subCategory'),
      TextCellValue('Created Date'),
      TextCellValue('Status'),
    ]);

    // Add data
    final excelCategories = onlySelected
        ? filteredCategories
            .asMap()
            .entries
            .where((e) => selectedCategories[e.key])
            .map((e) => e.value)
            .toList()
        : filteredCategories;

    if (excelCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            onlySelected ? "No records selected" : "No records available",
          ),
        ),
      );
      return;
    }

    for (final subCategory in excelCategories) {
      sheet.appendRow([
        TextCellValue(subCategory.subCategory),
        TextCellValue(subCategory.category),
        TextCellValue(subCategory.description),
        TextCellValue(subCategory.createdDate),
        TextCellValue(subCategory.status),
      ]);
    }

    // Save the file
    final bytes = excel.encode();
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to generate Excel file")),
      );
      return;
    }

    String filePath;
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      filePath = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: filePath)
        ..download = 'categories_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(filePath);
    } else {
      final output = await getApplicationDocumentsDirectory();
      filePath = "${output.path}/categories_${DateTime.now().millisecondsSinceEpoch}.xlsx";
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
