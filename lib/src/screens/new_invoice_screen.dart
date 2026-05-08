import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/invoice.dart';
import '../provider/client_provider.dart';
import '../provider/invoice_provider.dart';
import 'invoice_preview_screen.dart';

class NewInvoiceScreen extends ConsumerStatefulWidget {
  const NewInvoiceScreen({super.key});

  @override
  ConsumerState<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends ConsumerState<NewInvoiceScreen> {
  // ── Client selection state ─────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  Client? _selectedClient;
  bool _isNewClient = false;
  List<Client> _suggestions = [];
  Timer? _debounce;

  // ── Items state ────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final List<_ItemRow> _items = [_ItemRow()];

  double get _total => _items.fold(0, (s, r) => s + (r.price * r.qty));

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Search helpers ─────────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _selectedClient = null;
        _isNewClient = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await DatabaseHelper.instance.searchClients(query.trim());
      if (mounted) setState(() => _suggestions = results);
    });
  }

  void _selectExistingClient(Client client) {
    setState(() {
      _selectedClient = client;
      _isNewClient = false;
      _suggestions = [];
      _searchCtrl.text = client.name;
    });
  }

  void _clearClientSelection() {
    setState(() {
      _selectedClient = null;
      _isNewClient = false;
      _suggestions = [];
      _searchCtrl.clear();
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _addressCtrl.clear();
    });
  }

  void _switchToNewClient(String typedName) {
    setState(() {
      _isNewClient = true;
      _selectedClient = null;
      _suggestions = [];
      _nameCtrl.text = typedName;
    });
  }

  // ── Preview ────────────────────────────────────────────────────────────────

  Future<void> _previewInvoice() async {
    final validItems =
        _items.where((r) => r.description.trim().isNotEmpty).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add at least one item description')),
      );
      return;
    }
    if (_selectedClient == null && !_isNewClient) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create a client')),
      );
      return;
    }
    if (_isNewClient && !_formKey.currentState!.validate()) return;

    final items = validItems
        .map((r) => InvoiceItem(
              description: r.description.trim(),
              qty: r.qty,
              price: r.price,
            ))
        .toList();

    final tempClient = _selectedClient ??
        Client(
          name: _nameCtrl.text.trim(),
          phone:
              _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty
              ? null
              : _addressCtrl.text.trim(),
        );

    final tempInvoice = Invoice(
      id: null,
      client: tempClient,
      date: DateTime.now(),
      totalAmount: _total,
      items: items,
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(
          invoice: tempInvoice,
          onConfirm: () async {
            late final int invoiceId;
            if (_selectedClient != null) {
              invoiceId = await DatabaseHelper.instance
                  .createInvoiceForExistingClient(_selectedClient!.id!, items);
            } else {
              invoiceId = await DatabaseHelper.instance
                  .createFullInvoice(tempClient, items);
            }
            // Invalidate so both tabs pick up fresh data
            ref.invalidate(invoicesProvider);
            ref.invalidate(clientsProvider);

            return Invoice(
              id: invoiceId,
              client: tempClient,
              date: tempInvoice.date,
              totalAmount: _total,
              items: items,
            );
          },
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Invoice')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionLabel('Client'),
                  const SizedBox(height: 8),
                  _buildClientSection(),
                  const SizedBox(height: 24),
                  _sectionLabel('Service / Parts'),
                  const SizedBox(height: 8),
                  _buildItemsSection(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSection() {
    if (_selectedClient != null) {
      return _SelectedClientChip(
        client: _selectedClient!,
        onClear: _clearClientSelection,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search existing client by name / phone…',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearClientSelection,
                  )
                : null,
          ),
          onChanged: _onSearchChanged,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08), blurRadius: 8)
              ],
            ),
            child: Column(
              children: [
                ..._suggestions.map(
                  (c) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.withOpacity(0.1),
                      child: const Icon(Icons.person, color: Colors.indigo),
                    ),
                    title: Text(c.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: c.phone != null ? Text(c.phone!) : null,
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => _selectExistingClient(c),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.12),
                    child:
                        const Icon(Icons.person_add, color: Colors.green),
                  ),
                  title: Text(
                    'Create "${_searchCtrl.text.trim()}" as new client',
                    style: const TextStyle(color: Colors.green),
                  ),
                  onTap: () => _switchToNewClient(_searchCtrl.text.trim()),
                ),
              ],
            ),
          ),
        if (_isNewClient) ...[
          const SizedBox(height: 12),
          _NewClientForm(
            nameCtrl: _nameCtrl,
            phoneCtrl: _phoneCtrl,
            addressCtrl: _addressCtrl,
          ),
        ],
        if (!_isNewClient &&
            _suggestions.isEmpty &&
            _searchCtrl.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () => _switchToNewClient(_searchCtrl.text.trim()),
              child: Text(
                '+ Create "${_searchCtrl.text.trim()}" as a new client',
                style: const TextStyle(
                    color: Colors.indigo,
                    decoration: TextDecoration.underline),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemsSection() {
    return Column(
      children: [
        ..._items.asMap().entries.map((e) {
          final idx = e.key;
          final row = e.value;
          return _ItemRowWidget(
            key: ValueKey(row.id),
            row: row,
            canDelete: _items.length > 1,
            onDelete: () => setState(() => _items.removeAt(idx)),
            onChanged: () => setState(() {}),
          );
        }),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _items.add(_ItemRow())),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Item'),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12)),
                Text(
                  '₹${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: _previewInvoice,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Preview'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      );
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SelectedClientChip extends StatelessWidget {
  final Client client;
  final VoidCallback onClear;
  const _SelectedClientChip({required this.client, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.indigo,
            radius: 20,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                if (client.phone != null)
                  Text(client.phone!,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13)),
                if (client.address != null)
                  Text(client.address!,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClear,
            tooltip: 'Change client',
          ),
        ],
      ),
    );
  }
}

class _NewClientForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController addressCtrl;
  const _NewClientForm(
      {required this.nameCtrl,
      required this.phoneCtrl,
      required this.addressCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_add, color: Colors.green, size: 18),
              SizedBox(width: 6),
              Text('New Client',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: phoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: addressCtrl,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _ItemRow {
  static int _counter = 0;
  final int id = ++_counter;
  String description = '';
  int qty = 1;
  double price = 0;
}

class _ItemRowWidget extends StatefulWidget {
  final _ItemRow row;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  const _ItemRowWidget({
    super.key,
    required this.row,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_ItemRowWidget> createState() => _ItemRowWidgetState();
}

class _ItemRowWidgetState extends State<_ItemRowWidget> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.row.description);
    _qtyCtrl = TextEditingController(
        text: widget.row.qty > 0 ? widget.row.qty.toString() : '');
    _priceCtrl = TextEditingController(
        text: widget.row.price > 0
            ? widget.row.price.toStringAsFixed(2)
            : '');
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Description',
                      border: InputBorder.none,
                    ),
                    onChanged: (v) {
                      widget.row.description = v;
                      widget.onChanged();
                    },
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (widget.canDelete)
                  IconButton(
                    icon:
                        const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    onChanged: (v) {
                      widget.row.qty = int.tryParse(v) ?? 1;
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                const Text('×', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Unit Price (₹)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    onChanged: (v) {
                      widget.row.price = double.tryParse(v) ?? 0;
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '₹${(widget.row.qty * widget.row.price).toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
