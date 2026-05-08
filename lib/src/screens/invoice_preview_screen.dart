import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/invoice.dart';
import '../provider/pdf_service.dart';

/// A reusable PDF preview screen.
///
/// **New-invoice mode** — pass [onConfirm]:
///   Shows a "Save & Print" button. [onConfirm] performs the DB save and
///   returns the persisted [Invoice] (with a real id) used for printing.
///
/// **View/print mode** — omit [onConfirm]:
///   Shows only a "Print" button. The [invoice] is printed as-is.
class InvoicePreviewScreen extends StatefulWidget {
  const InvoicePreviewScreen({
    super.key,
    required this.invoice,
    this.onConfirm,
  });

  final Invoice invoice;

  /// Optional. When provided the AppBar shows "Save & Print" and invokes
  /// this callback before printing. When null the AppBar shows just "Print".
  final Future<Invoice> Function()? onConfirm;

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  bool _busy = false;

  // ── Save then print (new-invoice mode) ─────────────────────────────────────
  Future<void> _saveAndPrint() async {
    setState(() => _busy = true);
    try {
      final savedInvoice = await widget.onConfirm!();
      if (!mounted) return;
      await PdfService.generateAndPrint(savedInvoice);
      if (!mounted) return;
      _showSuccess();
      Navigator.of(context)
        ..pop() // preview
        ..pop(); // new-invoice form
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Print only (view mode) ──────────────────────────────────────────────────
  Future<void> _printOnly() async {
    setState(() => _busy = true);
    try {
      await PdfService.generateAndPrint(widget.invoice);
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Invoice saved and sent to print!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNewInvoice = widget.onConfirm != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isNewInvoice
              ? 'Preview Invoice'
              : 'Invoice #${widget.invoice.id ?? '-'}',
        ),
        actions: [
          _busy
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : FilledButton.icon(
                  onPressed: isNewInvoice ? _saveAndPrint : _printOnly,
                  icon: Icon(
                    isNewInvoice
                        ? Icons.save_outlined
                        : Icons.print_outlined,
                    size: 18,
                  ),
                  label: Text(isNewInvoice ? 'Save & Print' : 'Print'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: PdfPreview(
        build: (_) => PdfService.buildPdf(widget.invoice),
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfPreviewPageDecoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
