import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import '../models/item.dart';

// Only import dart:io when not on web to avoid the Platform error
import 'dart:io' if (dart.library.html) 'dart:io' as io;

/// Saves invoice data to a single cumulative CSV file
/// Appends new records to existing file or creates a new one if it doesn't exist
Future<void> saveCsv({
  required List<Item> items,
  required String customerName,
  required String serialNo,
  required String invoiceDate,
}) async {
  try {
    // Define CSV file name
    String fileName = 'all_invoices.csv';

    // Headers for the CSV
    const String headers =
        'Invoice No,Date,Customer Name,Item Description,HSN,Size,Quantity,Total Square,Rate,Amount';

    // Prepare data rows for this invoice
    List<String> dataRows = [];

    for (var item in items) {
      // Format each item as a CSV row
      String row = [
        serialNo,
        invoiceDate,
        _escapeCsvField(customerName),
        _escapeCsvField(item.description),
        _escapeCsvField(item.hsnCode.toString()),
        item.sizeString,
        item.quantity.toString(),
        item.totalSqft.toString(),
        item.rate.toString(),
        item.amount.toString(),
      ].join(',');

      dataRows.add(row);
    }

    // If no items, add an empty record with just invoice details
    if (items.isEmpty) {
      String row = [
        serialNo,
        invoiceDate,
        _escapeCsvField(customerName),
        '',
        '',
        '',
        '',
        '',
        '',
        '0.0'
      ].join(',');
      dataRows.add(row);
    }

    // Combine all content
    String fullContent = '';

    // For all platforms, use FileSaver to save the CSV
    if (kIsWeb) {
      // On web, we always create a new file with headers
      fullContent = headers + '\n' + dataRows.join('\n');
    } else {
      // On native platforms, try to append to existing file if it exists
      try {
        final directory = await getApplicationDocumentsDirectory();
        final csvFilePath = '${directory.path}/$fileName';
        final csvFile = io.File(csvFilePath);

        if (await csvFile.exists()) {
          // Read existing content
          String existingContent = await csvFile.readAsString();
          // Check if the file has headers
          if (existingContent.startsWith(headers)) {
            // Append new rows
            fullContent = existingContent + '\n' + dataRows.join('\n');
          } else {
            // File exists but doesn't have proper headers
            fullContent = headers + '\n' + existingContent + '\n' + dataRows.join('\n');
          }

          // Update the file
          await csvFile.writeAsString(fullContent);
          print('Updated existing CSV file at: $csvFilePath');
        } else {
          // Create new file with headers
          fullContent = headers + '\n' + dataRows.join('\n');
          await csvFile.writeAsString(fullContent);
          print('Created new CSV file at: $csvFilePath');
        }
      } catch (e) {
        print('Warning: Could not access native file system: $e');
        // Still create content for FileSaver backup
        fullContent = headers + '\n' + dataRows.join('\n');
      }
    }

    // Use FileSaver for all platforms as a backup/user-accessible copy
    try {
      await FileSaver.instance.saveFile(
          name: fileName,
          bytes: utf8.encode(fullContent),
          ext: 'csv',
          mimeType: MimeType.csv
      );
      print('CSV file saved using FileSaver');
    } catch (e) {
      print('Error using FileSaver: $e');
    }

  } catch (e) {
    print('Error saving CSV file: $e');
    rethrow;
  }
}

/// Calculates the total amount for all items in the invoice
double calculateInvoiceTotal(List<Item> items) {
  return items.fold(0, (sum, item) => sum + item.amount);
}

/// Escapes CSV field values to handle commas, quotes, etc.
String _escapeCsvField(String field) {
  // If the field contains commas, quotes, or newlines, enclose in quotes
  if (field.contains(',') || field.contains('"') || field.contains('\n')) {
    // Double up any quotes in the field
    field = field.replaceAll('"', '""');
    // Enclose the field in quotes
    return '"$field"';
  }
  return field;
}

/// Export the entire CSV file to a specific location (e.g., for backup or sharing)
Future<String?> exportCsvFile() async {
  try {
    String fileName = 'all_invoices_export_${DateTime.now().millisecondsSinceEpoch}.csv';

    if (kIsWeb) {
      // For web, we can't access previously saved files
      // Just inform the user
      print('Export function is limited on web platform');
      return null;
    } else {
      // For native platforms
      try {
        final directory = await getApplicationDocumentsDirectory();
        final csvFilePath = '${directory.path}/all_invoices.csv';
        final csvFile = io.File(csvFilePath);

        if (await csvFile.exists()) {
          final content = await csvFile.readAsString();
          final result = await FileSaver.instance.saveFile(
              name: fileName,
              bytes: utf8.encode(content),
              ext: 'csv',
              mimeType: MimeType.csv);
          return result;
        } else {
          throw Exception('CSV file does not exist at $csvFilePath');
        }
      } catch (e) {
        print('Error accessing native file: $e');
        return null;
      }
    }
  } catch (e) {
    print('Error exporting CSV file: $e');
    return null;
  }
}