import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/item.dart';

class InvoiceTableSection {
  static pw.Widget buildExtendedInvoiceTable(List<Item> items, pw.Font customFont) {
    return pw.Container(
      // Add border to the entire table container to ensure margins are visible
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.5, color: PdfColors.black),
      ),
      child: pw.Column(
        children: [
          // Header row with distinct styling and proper margins
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              border: pw.Border(
                bottom: pw.BorderSide(width: 0.5, color: PdfColors.black),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 25,
                  padding: pw.EdgeInsets.all(3),
                  // Added padding for margins
                  decoration: _getVerticalBorder(),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'S.No.',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(3), // Added padding for margins
                    decoration: _getVerticalBorder(),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      'Description',
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                pw.Container(
                  width: 40,
                  padding: pw.EdgeInsets.all(3),
                  // Added padding for margins
                  decoration: _getVerticalBorder(),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'HSN',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Container(
                  width: 45,
                  padding: pw.EdgeInsets.all(3),
                  // Added padding for margins
                  decoration: _getVerticalBorder(),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Size',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Container(
                  width: 35,
                  padding: pw.EdgeInsets.all(3),
                  // Added padding for margins
                  decoration: _getVerticalBorder(),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Sqft',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Container(
                  width: 30,
                  padding: pw.EdgeInsets.all(3),
                  // Added padding for margins
                  decoration: _getVerticalBorder(),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Qty.',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Container(
                  width: 45,
                  padding: pw.EdgeInsets.all(3),
                  // Added padding for margins
                  decoration: _getVerticalBorder(),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Total Sqft',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Container(
                  width: 45,
                  padding: pw.EdgeInsets.all(3),
                  // Added padding for margins
                  decoration: _getVerticalBorder(),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Rate',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Container(
                  width: 60,
                  decoration: _getVerticalBorder(),
                  padding: pw.EdgeInsets.all(3),
                  // Added padding for margins
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Amount',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rest of the table with data rows
          pw.Expanded(
            child: pw.Stack(
              children: [
                // Container to show vertical lines extending to the bottom
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 0.5, color: PdfColors.black),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(width: 25, decoration: _getVerticalBorder()),
                      // S.No
                      pw.Expanded(
                          flex: 4,
                          child: pw.Container(decoration: _getVerticalBorder())),
                      // Description
                      pw.Container(width: 40, decoration: _getVerticalBorder()),
                      // HSN
                      pw.Container(width: 45, decoration: _getVerticalBorder()),
                      // Size
                      pw.Container(width: 35, decoration: _getVerticalBorder()),
                      // sqft
                      pw.Container(width: 30, decoration: _getVerticalBorder()),
                      // Qty
                      pw.Container(width: 45, decoration: _getVerticalBorder()),
                      // Total Sq.
                      pw.Container(width: 45, decoration: _getVerticalBorder()),
                      // Rate
                      pw.Container(width: 60, decoration: _getVerticalBorder()),
                    ],
                  ),
                ),

                // Data rows with vertical dividers
                pw.ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return pw.Container(
                      decoration: pw.BoxDecoration(
                        color:
                        index % 2 == 0 ? PdfColors.white : PdfColors.grey50,
                        border: pw.Border(
                          bottom:
                          pw.BorderSide(width: 0.5, color: PdfColors.black),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 25,
                            decoration: _getVerticalBorder(),
                            child: _buildTableCellContent('${index + 1}'),
                          ),
                          pw.Expanded(
                            flex: 4,
                            child: pw.Container(
                              decoration: _getVerticalBorder(),
                              child: _buildTableCellContent(
                                items[index].description,
                                alignment: pw.Alignment.centerLeft,
                              ),
                            ),
                          ),
                          pw.Container(
                            width: 40,
                            decoration: _getVerticalBorder(),
                            child: _buildTableCellContent(
                              items[index].hsnCode > 0
                                  ? items[index].hsnCode.toString()
                                  : '',
                            ),
                          ),
                          pw.Container(
                            width: 45,
                            decoration: _getVerticalBorder(),
                            child:
                            _buildTableCellContent(items[index].sizeString),
                          ),
                          pw.Container(
                            width: 35,
                            decoration: _getVerticalBorder(),
                            child: _buildTableCellContent(
                              items[index].size > 0
                                  ? items[index].size.toString()
                                  : '',
                            ),
                          ),
                          pw.Container(
                            width: 30,
                            decoration: _getVerticalBorder(),
                            child: _buildTableCellContent(
                              items[index].quantity > 0
                                  ? items[index].quantity.toString()
                                  : '',
                            ),
                          ),
                          pw.Container(
                            width: 45,
                            decoration: _getVerticalBorder(),
                            child: _buildTableCellContent(
                              items[index].totalSqft > 0
                                  ? items[index].totalSqft.toString()
                                  : '',
                            ),
                          ),
                          pw.Container(
                            width: 45,
                            decoration: _getVerticalBorder(),
                            child: _buildTableCellContent(
                              items[index].rate > 0
                                  ? '₹${items[index].rate.toStringAsFixed(2)}'
                                  : '',
                            ),
                          ),
                          pw.Container(
                            width: 60,
                            decoration: _getVerticalBorder(),
                            child: _buildTableCellContent(
                              items[index].amount > 0
                                  ? '₹${items[index].amount.toStringAsFixed(2)}'
                                  : '',
                              alignment: pw.Alignment.centerRight,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Helper for creating vertical borders for columns
  static pw.BoxDecoration _getVerticalBorder() {
    return pw.BoxDecoration(
      border: pw.Border.all(width: 0.5, color: PdfColors.black),
    );
  }

// Helper for table cell content with reduced padding and font size
  static pw.Widget _buildTableCellContent(String text,
      {bool isHeader = false, pw.Alignment alignment = pw.Alignment.center}) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7, // Smaller font size
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }
}
