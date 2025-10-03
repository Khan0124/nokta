import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/order.dart';

enum ReceiptLayout { compact, full }

class PrintService {
  const PrintService();

  Future<void> printReceipt(
    Order order, {
    ReceiptLayout layout = ReceiptLayout.full,
    Printer? printer,
    bool includeQr = true,
    bool includeBarcode = false,
    int? offlineReference,
    String currencyCode = 'SAR',
  }) async {
    final bytes = await _buildReceipt(
      order,
      layout: layout,
      includeQr: includeQr,
      includeBarcode: includeBarcode,
      offlineReference: offlineReference,
      currencyCode: currencyCode,
    );

    if (printer != null) {
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (_) async => bytes,
      );
    } else {
      await Printing.layoutPdf(
        name: 'Order ${_resolveReceiptId(order, offlineReference)}',
        onLayout: (_) async => bytes,
      );
    }
  }

  Future<Uint8List> _buildReceipt(
    Order order, {
    required ReceiptLayout layout,
    required bool includeQr,
    required bool includeBarcode,
    required int? offlineReference,
    required String currencyCode,
  }) async {
    final doc = pw.Document();
    final dateFormat = DateFormat('y/MM/dd HH:mm');
    final currencyFormat = NumberFormat.currency(name: currencyCode);
    final receiptId = _resolveReceiptId(order, offlineReference);

    doc.addPage(
      pw.Page(
        pageFormat: layout == ReceiptLayout.compact
            ? const PdfPageFormat(226.0, double.infinity, marginAll: 12)
            : PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Nokta POS',
                style: pw.TextStyle(
                  fontSize: layout == ReceiptLayout.full ? 18 : 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Receipt #: $receiptId'),
              if (offlineReference != null && order.id <= 0)
                pw.Text('Offline ref: $offlineReference'),
              pw.Text(dateFormat.format(order.createdAt ?? DateTime.now())),
              pw.SizedBox(height: 12),
              _buildItemTable(order, currencyFormat, layout),
              pw.Divider(),
              _buildTotals(order, currencyFormat),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(order.notes!),
              ],
              pw.SizedBox(height: 12),
              if (includeQr)
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'order:${order.id};ref:$receiptId',
                    width: layout == ReceiptLayout.full ? 120 : 80,
                    height: layout == ReceiptLayout.full ? 120 : 80,
                  ),
                ),
              if (includeBarcode) ...[
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: receiptId,
                    width: layout == ReceiptLayout.full ? 200 : 160,
                    height: 60,
                  ),
                ),
              ],
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text(
                  'Thank you',
                  style: pw.TextStyle(fontSize: layout == ReceiptLayout.full ? 14 : 12),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildItemTable(
    Order order,
    NumberFormat currencyFormat,
    ReceiptLayout layout,
  ) {
    final headerStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: layout == ReceiptLayout.full ? 12 : 10,
    );

    return pw.Table(
      border: null,
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Text('Item', style: headerStyle),
            pw.Text('Qty', style: headerStyle),
            pw.Text('Price', style: headerStyle, textAlign: pw.TextAlign.right),
            pw.Text('Total', style: headerStyle, textAlign: pw.TextAlign.right),
          ],
        ),
        ...order.items.map(
          (item) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Text(item.notes != null && item.notes!.isNotEmpty
                    ? '${item.productId} (${item.notes})'
                    : '${item.productId}'),
              ),
              pw.Text('${item.quantity}'),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(currencyFormat.format(item.unitPrice)),
              ),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(currencyFormat.format(item.totalPrice)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTotals(Order order, NumberFormat currencyFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildTotalRow('Subtotal', currencyFormat.format(order.subtotal)),
        _buildTotalRow('Tax', currencyFormat.format(order.tax)),
        if (order.deliveryFee > 0)
          _buildTotalRow('Delivery', currencyFormat.format(order.deliveryFee)),
        pw.Divider(),
        _buildTotalRow(
          'Total',
          currencyFormat.format(order.total),
          isEmphasized: true,
        ),
      ],
    );
  }

  pw.Widget _buildTotalRow(String label, String value, {bool isEmphasized = false}) {
    final style = pw.TextStyle(
      fontWeight: isEmphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: isEmphasized ? 14 : 12,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  String _resolveReceiptId(Order order, int? offlineReference) {
    if (order.id > 0) {
      return order.id.toString();
    }
    if (offlineReference != null) {
      return 'OFF-$offlineReference';
    }
    return 'OFF-${DateTime.now().millisecondsSinceEpoch}';
  }
}
