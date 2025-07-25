import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SummarySection{
  static pw.Widget buildSummarySection(
      num subTotal,
      num cgstRate,
      num sgstRate,
      num igstRate,
      String cgstAmount,
      String sgstAmount,
      String igstAmount,
      num totalAmount,
      pw.Font customFont) {
    return pw.Row(
      children: [
        pw.Expanded(flex: 7, child: pw.Container()),
        pw.Container(
          width: 180, // Reduced width
          child: pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              _buildSummaryRow('Less/Advance/Discount', ''),
              _buildSummaryRow('Freight/Loading/cartage', ''),
              _buildSummaryRow(
                  'Taxable Amount', 'Rs. ${subTotal.toStringAsFixed(2)}',
                  isTotal: true),
              _buildSummaryRow('CGST @ $cgstRate%', 'Rs. $cgstAmount'),
              _buildSummaryRow('SGST @ $sgstRate%', 'Rs. $sgstAmount'),
              _buildSummaryRow('IGST @ $igstRate%', 'Rs. $igstAmount'),
              _buildSummaryRow(
                  'Total Amount', 'Rs. ${totalAmount.toStringAsFixed(2)}',
                  isTotal: true),
            ],
          ),
        ),
      ],
    );
  }

  static pw.TableRow _buildSummaryRow(String label, String amount,
      {bool isTotal = false}) {
    return pw.TableRow(
      decoration: isTotal ? pw.BoxDecoration(color: PdfColors.grey200) : null,
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.all(3), // Reduced padding
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8, // Smaller font size
              fontWeight: isTotal ? pw.FontWeight.bold : null,
            ),
          ),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(3), // Reduced padding
          child: pw.Text(
            amount,
            style: pw.TextStyle(
              fontSize: 8, // Smaller font size
              fontWeight: isTotal ? pw.FontWeight.bold : null,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }
}