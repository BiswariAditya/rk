import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:number_to_words/number_to_words.dart';
import 'package:rk_adv/widgets/customer_section.dart';
import 'package:rk_adv/widgets/footer_section.dart';
import 'package:rk_adv/widgets/header_section.dart';
import 'package:rk_adv/widgets/summary_section.dart';
import '../models/item.dart';
import '../providers/invoice_provider.dart';
import '../widgets/amountInWOrds_section.dart';
import '../widgets/invoice_table.dart';

Future<void> generatePdfInvoice(
    List<Item> items,
    String customerName,
    String customerAddress,
    String statCode,
    String gstNo,
    String phNo,
    String serialNo,
    String now,
    InvoiceProvider invoiceProvider) async {
  final pdf = pw.Document();

  // Load custom Unicode font with error handling
  final fontData = await rootBundle
      .load('assets/Roboto-VariableFont_wdth,wght.ttf')
      .catchError((error) {
    return Uint8List(0).buffer.asByteData();
  });
  final customFont = pw.Font.ttf(fontData);

  // Load logo and QR code from assets with error handling
  final logoBytes = await _loadAssetImage('assets/rk logo.jpg');
  final qrBytes = await _loadAssetImage('assets/rk qr.jpg');

  // Fetch dynamic taxation details from provider
  final subTotal = invoiceProvider.subtotal;
  final cgstRate = invoiceProvider.taxRate / 2;
  final sgstRate = invoiceProvider.taxRate / 2;
  final igstRate = invoiceProvider.taxRate;

  // Calculate tax amounts with proper formatting
  final cgstAmount = invoiceProvider.cgst.toStringAsFixed(2);
  final sgstAmount = invoiceProvider.sgst.toStringAsFixed(2);
  final igstAmount = invoiceProvider.igst.toStringAsFixed(2);

  // Convert total amount to words - handle numeric conversion
  final amountInWords =
      NumberToWord().convert('en-in', invoiceProvider.totalAmount.toInt());

  // Define theme for consistent styling
  final theme = pw.ThemeData.withFont(
    base: customFont,
  );

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      margin: pw.EdgeInsets.all(10),
      build: (pw.Context context) {
        return pw.Container(
          padding: pw.EdgeInsets.all(5),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                padding: pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('TAX INVOICE',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
              pw.SizedBox(height: 5),

              // Header with logo and company info
              HeaderWidget.buildHeaderSection(
                  logoBytes, qrBytes, serialNo, now, customFont),

              pw.SizedBox(height: 5),

              // Customer details
              CustomerSection.buildCustomerSection(customerName,
                  customerAddress, statCode, gstNo, phNo, customFont),

              pw.SizedBox(height: 5),

              // Invoice table - extended to fill available space with vertical lines
              pw.Expanded(
                child: InvoiceTableSection.buildExtendedInvoiceTable(
                    items, customFont),
              ),

              // Summary section (positioned just above footer)
              SummarySection.buildSummarySection(
                  subTotal,
                  cgstRate,
                  sgstRate,
                  igstRate,
                  cgstAmount,
                  sgstAmount,
                  igstAmount,
                  invoiceProvider.totalAmount,
                  customFont),

              pw.SizedBox(height: 5),

              // Amount in words section
              AmountInWordsSection.buildAmountInWords(
                  amountInWords, customFont),

              pw.SizedBox(height: 5),

              // Footer section - now positioned at bottom with increased height
              FooterSection.buildFooterSection(customFont),

              pw.SizedBox(height: 5),
              // Added more space after footer

              // Generator note
              pw.Center(
                child: pw.Text('Generated using RK-BillSoft',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    )),
              ),
            ],
          ),
        );
      },
    ),
  );
  await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => await pdf.save());
}

// Helper method to load images with error handling
Future<Uint8List> _loadAssetImage(String assetPath) async {
  try {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    // For PNG images, use direct bytes without processing
    if (assetPath.toLowerCase().endsWith('.png')) {
      return bytes;
    }
    // For JPG, consider converting to PNG for better quality
    return bytes;
  } catch (e) {
    return Uint8List(0);
  }
}