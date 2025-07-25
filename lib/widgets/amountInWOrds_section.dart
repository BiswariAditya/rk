import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AmountInWordsSection {
  static pw.Widget buildAmountInWords(
      String amountInWords, pw.Font customFont) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.5),
        borderRadius: pw.BorderRadius.circular(2),
        color: PdfColors.grey50,
      ),
      padding: pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      // Consistent padding
      child: pw.Row(
        children: [
          pw.Text(
            'Amount in Words: ',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.Expanded(
            child: pw.Text(
              'Rupees $amountInWords Only',
              style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
