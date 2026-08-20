import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';

import 'models/material_order.dart';
import 'services/local_database.dart';
import 'services/order_pdf.dart';

void main() => runApp(const HoldingOrdersApp());

class HoldingOrdersApp extends StatelessWidget {
  const HoldingOrdersApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Holding Group',
        theme: ThemeData(colorSchemeSeed: const Color(0xff27303a), useMaterial3: true),
        home: const OrdersHome(),
      );
}

class OrdersHome extends StatefulWidget {
  const OrdersHome({super.key});
  @override
  State<OrdersHome> createState() => _OrdersHomeState();
}

class _OrdersHomeState extends State<OrdersHome> {
  late Future<List<MaterialOrder>> _orders;
  @override
  void initState() { super.initState(); _reload(); }
  void _reload() => _orders = LocalDatabase.instance.all();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Holding Group · Órdenes')),
        body: FutureBuilder<List<MaterialOrder>>(
          future: _orders,
          builder: (_, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            if (snap.data!.isEmpty) return const Center(child: Text('Aún no hay órdenes guardadas en este teléfono.'));
            return ListView.separated(
              itemCount: snap.data!.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) { final order = snap.data![i]; return ListTile(
                title: Text('Orden N° ${order.number.toString().padLeft(6, '0')} · ${order.work}'),
                subtitle: Text('${DateFormat('dd/MM/yyyy').format(order.date)} · ${order.job}'),
                trailing: IconButton(icon: const Icon(Icons.picture_as_pdf_outlined), onPressed: () => OrderPdf.preview(order)),
              ); },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderForm())); if (mounted) setState(_reload); },
          icon: const Icon(Icons.add), label: const Text('Nueva orden'),
        ),
      );
}

class _ItemFields {
  final description = TextEditingController(); final quantity = TextEditingController();
  final color = TextEditingController(); final thickness = TextEditingController(); final measurements = TextEditingController();
  OrderItem value() => OrderItem(description: description.text, quantity: quantity.text, color: color.text, thickness: thickness.text, measurements: measurements.text);
  void dispose() { description.dispose(); quantity.dispose(); color.dispose(); thickness.dispose(); measurements.dispose(); }
}

class OrderForm extends StatefulWidget {
  const OrderForm({super.key});
  @override State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _key = GlobalKey<FormState>();
  final _work = TextEditingController(), _technician = TextEditingController(), _service = TextEditingController(), _job = TextEditingController();
  final _signature = SignatureController(penStrokeWidth: 3, penColor: Colors.indigo);
  final List<_ItemFields> _items = [_ItemFields()];
  DateTime _date = DateTime.now(); int? _number; bool _saving = false;

  @override void initState() { super.initState(); LocalDatabase.instance.nextNumber().then((n) { if (mounted) setState(() => _number = n); }); }
  @override void dispose() { _work.dispose(); _technician.dispose(); _service.dispose(); _job.dispose(); _signature.dispose(); for (final item in _items) { item.dispose(); } super.dispose(); }
  Widget _input(String label, TextEditingController controller, {bool required = false}) => TextFormField(controller: controller, decoration: InputDecoration(labelText: label), validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null : null);

  Future<void> _save() async {
    if (!(_key.currentState?.validate() ?? false) || _number == null) return;
    setState(() => _saving = true);
    final png = _signature.isNotEmpty ? await _signature.toPngBytes() : null;
    final order = MaterialOrder(number: _number!, date: _date, work: _work.text.trim(), technician: _technician.text.trim(), serviceOrder: _service.text.trim(), job: _job.text.trim(), items: _items.map((x) => x.value()).where((x) => x.description.isNotEmpty).toList(), signature: png == null ? null : base64Encode(png));
    try {
      await LocalDatabase.instance.save(order);
      if (!mounted) return;
      await OrderPdf.preview(order);
      if (mounted) Navigator.pop(context);
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo guardar la orden.'))); }
    if (mounted) setState(() => _saving = false);
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Nueva orden ${_number == null ? '' : 'N° ${_number!.toString().padLeft(6, '0')}'}')),
    body: SafeArea(child: Form(key: _key, child: ListView(padding: const EdgeInsets.all(16), children: [
      _input('Obra', _work, required: true), _input('Técnico', _technician), _input('N° orden de servicio', _service), _input('Trabajo a realizar', _job, required: true),
      ListTile(contentPadding: EdgeInsets.zero, title: const Text('Fecha'), subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)), trailing: const Icon(Icons.calendar_today), onTap: () async { final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: _date); if (d != null) setState(() => _date = d); }),
      const SizedBox(height: 16), Text('Materiales', style: Theme.of(context).textTheme.titleLarge),
      ..._items.asMap().entries.map((entry) => _itemCard(entry.key, entry.value)),
      OutlinedButton.icon(onPressed: () => setState(() => _items.add(_ItemFields())), icon: const Icon(Icons.add), label: const Text('Agregar material')),
      const SizedBox(height: 20), Text('Firma de gerencia', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 6),
      Container(height: 160, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)), child: Signature(controller: _signature, backgroundColor: Colors.white)),
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _signature.clear, icon: const Icon(Icons.refresh), label: const Text('Limpiar firma'))),
      const SizedBox(height: 12), FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_alt), label: Text(_saving ? 'Guardando…' : 'Guardar y generar PDF')),
    ]))),
  );
  Widget _itemCard(int index, _ItemFields item) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
    Row(children: [Text('Material ${index + 1}', style: Theme.of(context).textTheme.titleMedium), const Spacer(), if (_items.length > 1) IconButton(onPressed: () => setState(() { _items.removeAt(index).dispose(); }), icon: const Icon(Icons.delete_outline))]),
    _input('Descripción', item.description), Row(children: [Expanded(child: _input('Cantidad', item.quantity)), const SizedBox(width: 12), Expanded(child: _input('Color', item.color))]), Row(children: [Expanded(child: _input('Espesor', item.thickness)), const SizedBox(width: 12), Expanded(child: _input('Medidas', item.measurements))]),
  ])));
}
