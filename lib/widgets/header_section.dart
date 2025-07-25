import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class HeaderWidget {
  static pw.Widget buildHeaderSection(Uint8List logoBytes, Uint8List qrBytes,
      String serialNo, String now, pw.Font customFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Image(
          pw.MemoryImage(
            logoBytes,
            dpi: 300,
          ),
          width: 120, // Reduced logo size
          height: 60,
          fit: pw.BoxFit.fill,
          dpi: 300,
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('GST No: 09ANEPG2598L1ZI',
                        style: pw.TextStyle(fontSize: 8)), // Smaller font
                    pw.Text('Indian Overseas Bank',
                        style: pw.TextStyle(fontSize: 8)),
                    pw.Text('A/C NO: 056502000001372',
                        style: pw.TextStyle(fontSize: 8)),
                    pw.Text('IFSC Code: IOBA0000565',
                        style: pw.TextStyle(fontSize: 8)),
                    pw.Text('Ph: 9450080432, 0510-2361494',
                        style: pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.SizedBox(width: 5), // Reduced spacing
                pw.Image(
                  pw.MemoryImage(qrBytes),
                  width: 50, // Reduced QR code size
                  height: 50,
                  fit: pw.BoxFit.contain,
                ),
              ],
            ),
            pw.SizedBox(height: 3), // Reduced spacing
            pw.Container(
              padding: pw.EdgeInsets.all(2), // Reduced padding
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.5),
                borderRadius: pw.BorderRadius.circular(2),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Serial No: $serialNo',
                      style: pw.TextStyle(fontSize: 8)),
                  pw.Text('Date: $now', style: pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}