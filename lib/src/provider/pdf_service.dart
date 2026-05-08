import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/invoice.dart';

class PdfService {
  /// Builds the PDF and returns the raw bytes. Use this for previews.
  static Future<Uint8List> buildPdf(Invoice invoice) async {
    final pdf = pw.Document();
    final client = invoice.client;
    final items = invoice.items;
    final m = const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final date = '${invoice.date.day.toString().padLeft(2, "0")}-${m[invoice.date.month - 1]}-${invoice.date.year}';
    final total = invoice.totalAmount;

    const String logoSvg = '''
<svg width="400" height="500" viewBox="0 0 400 500" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="coolGradient" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:#2E008B;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#2EB9E7;stop-opacity:1" />
    </linearGradient>
  </defs>
  <path d="M100,115 L145,115 L145,130 L165,130 L200,210 L235,130 L255,130 L255,115 L300,115 L300,305 L255,305 L255,290 L240,290 L200,305 L160,290 L145,290 L145,305 L100,305 Z" fill="url(#coolGradient)" />
  <path d="M155,150 L155,275 M245,150 L245,275" stroke="white" stroke-width="6" fill="none" />
  <g fill="url(#coolGradient)">
    <path d="M120,325 L145,325 L145,335 L132,335 L132,360 L145,360 L145,370 L120,370 Z" />
    <path d="M155,325 L180,325 L180,370 L155,370 Z M167,335 L167,360 L168,360 L168,335 Z" fill-rule="evenodd" />
    <path d="M190,325 L215,325 L215,370 L190,370 Z M202,335 L202,360 L203,360 L203,335 Z" fill-rule="evenodd" />
    <path d="M225,325 L237,325 L237,360 L250,360 L250,370 L225,370 Z" />
  </g>
</svg>''';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 60,
                        height: 60,
                        child: pw.SvgImage(svg: logoSvg),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('MCOOL', 
                            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                          pw.Text('REFRIGERATION', 
                            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2)),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date: $date',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.Text(
                        'Status: Paid',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.green700,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.Divider(thickness: 1.5, color: PdfColors.grey400),
              pw.SizedBox(height: 12),

              // ── Bill To ─────────────────────────────────────────────
              pw.Text('Ref. No. ___________', style: const pw.TextStyle(fontSize: 11)),
              pw.Text(client.name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              if (client.address != null)
                pw.Container(
                  width: 200,
                  child: pw.Text(client.address!, style: const pw.TextStyle(fontSize: 10)),
                ),

              pw.SizedBox(height: 20),

              pw.SizedBox(height: 20),

              // ── Items Table ─────────────────────────────────────────
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
                cellStyle: const pw.TextStyle(fontSize: 11),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
                headers: ['Description', 'Qty', 'Unit Price', 'Total'],
                data: items
                    .map(
                      (item) => [
                        item.description,
                        item.qty.toString(),
                        'Rs. ${item.price.toStringAsFixed(2)}',
                        'Rs. ${item.lineTotal.toStringAsFixed(2)}',
                      ],
                    )
                    .toList(),
              ),

              pw.SizedBox(height: 16),

              // ── Grand Total ─────────────────────────────────────────
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo50,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Text(
                    'Grand Total: Rs. ${total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                    ),
                  ),
                ),
              ),

              pw.Spacer(),

              // ── Footer ──────────────────────────────────────────────
              pw.Divider(color: PdfColors.grey300),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  /// Generates the PDF and opens the OS print dialog directly.
  static Future<void> generateAndPrint(Invoice invoice) async {
    final bytes = await buildPdf(invoice);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
    );
  }
}
