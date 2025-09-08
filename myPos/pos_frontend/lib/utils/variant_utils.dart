// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io' show File, Platform;
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:pos_frontend/models/variant_model.dart';

/// Generates a PDF of the variants and saves it to the device or downloads it on web.
Future<void> generateVariantPDF(
  BuildContext context, {
  required bool onlySelected,
  required List<Variant> filteredVariants,
  required List<bool> selectedVariants,
  required Function(String?) setLastGeneratedPdfPath,
}) async {
  final pdf = pw.Document();
  final headers = ['Name', 'Values', 'Created Date', 'Status'];
  final pdfVariants = onlySelected
      ? filteredVariants
          .asMap()
          .entries
          .where((e) => selectedVariants[e.key])
          .map((e) => e.value)
          .toList()
      : filteredVariants;

  if (pdfVariants.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          onlySelected ? "No records selected" : "No records available",
        ),
      ),
    );
    return;
  }

  final data = pdfVariants
      .map(
        (variant) => [
          variant.name,
          variant.values,
          DateFormat('dd MMM yyyy').format(variant.createdDate),
          variant.status ? 'Active' : 'Inactive',
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
      ..download = 'variants_${DateTime.now().millisecondsSinceEpoch}.pdf';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(filePath);
  } else {
    final output = await getApplicationDocumentsDirectory();
    filePath =
        "${output.path}/variants_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    await OpenFile.open(filePath);
  }
  setLastGeneratedPdfPath(filePath);
}

/// Generates an Excel file of the variants and saves it to the device or downloads it on web.
Future<void> generateVariantExcel(
  BuildContext context, {
  required bool onlySelected,
  required List<Variant> filteredVariants,
  required List<bool> selectedVariants,
  required Function(String?) setLastGeneratedExcelPath,
}) async {
  try {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Variants'];

    // Add headers using TextCellValue
    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Values'),
      TextCellValue('Created Date'),
      TextCellValue('Status'),
    ]);

    // Add data
    final excelVariants = onlySelected
        ? filteredVariants
            .asMap()
            .entries
            .where((e) => selectedVariants[e.key])
            .map((e) => e.value)
            .toList()
        : filteredVariants;

    if (excelVariants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            onlySelected ? "No records selected" : "No records available",
          ),
        ),
      );
      return;
    }

    for (final variant in excelVariants) {
      sheet.appendRow([
        TextCellValue(variant.name),
        TextCellValue(variant.values),
        TextCellValue(DateFormat('dd MMM yyyy').format(variant.createdDate)),
        TextCellValue(variant.status ? 'Active' : 'Inactive'),
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
        ..download = 'variants_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(filePath);
    } else {
      final output = await getApplicationDocumentsDirectory();
      filePath = "${output.path}/variants_${DateTime.now().millisecondsSinceEpoch}.xlsx";
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

/// Shares a summary of selected variants via WhatsApp with instructions to attach the PDF.
Future<void> shareVariantWhatsApp(
  BuildContext context,
  String? lastGeneratedPdfPath,
  List<Variant> filteredVariants,
  List<bool> selectedVariants,
) async {
  if (lastGeneratedPdfPath == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Generate a PDF first!")),
    );
    return;
  }

  final variantSummary = filteredVariants.isEmpty
      ? "No variants to share!"
      : filteredVariants
          .asMap()
          .entries
          .where((e) => selectedVariants[e.key])
          .map((e) => "${e.value.name} (${e.value.status ? 'Active' : 'Inactive'})")
          .join(", ");

  final message = variantSummary.isEmpty
      ? "Check out my variant report!"
      : "Here's my variant summary: $variantSummary";

  if (kIsWeb || !Platform.isWindows) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("WhatsApp sharing is only supported on Windows desktop."),
      ),
    );
    return;
  }

  final file = File(lastGeneratedPdfPath);
  if (!await file.exists()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("PDF file not found! Please generate again."),
      ),
    );
    return;
  }

  final whatsappUrl = Uri.parse(
    "https://wa.me/?text=${Uri.encodeComponent(message)}",
  );
  if (await canLaunchUrl(whatsappUrl)) {
    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Share PDF on WhatsApp"),
        content: Text(
          "WhatsApp has been opened with the variant summary. To attach the PDF, use WhatsApp's attachment feature and select the file from:\n\n$lastGeneratedPdfPath",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
          TextButton(
            onPressed: () async {
              await OpenFile.open(lastGeneratedPdfPath);
              Navigator.pop(context);
            },
            child: const Text("Open PDF Folder"),
          ),
        ],
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("WhatsApp is not installed or not available."),
      ),
    );
  }
}