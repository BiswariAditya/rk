import 'package:pdf/widgets.dart' as pw;

class CustomerSection {
  static pw.Widget buildCustomerSection(String customerName,
      String customerAddress, String gstNo, String phNo, pw.Font customFont) {
    return pw.Container(
      padding: pw.EdgeInsets.all(5), // Reduced padding
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('M/s. $customerName',
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2), // Reduced spacing
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Address: ',
                  style: pw.TextStyle(
                      fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Expanded(
                child:
                    pw.Text(customerAddress, style: pw.TextStyle(fontSize: 8)),
              ),
            ],
          ),
          pw.SizedBox(height: 2), // Reduced spacing
          pw.Row(
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Text('State Code:',
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(width: 5), // Reduced spacing
              pw.Expanded(
                flex: 2,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Text('GST No:',
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 2),
                    pw.Text(gstNo, style: pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
              pw.SizedBox(width: 5), // Reduced spacing
              pw.Expanded(
                flex: 1,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Text('Ph No:',
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 2),
                    pw.Text(phNo, style: pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
