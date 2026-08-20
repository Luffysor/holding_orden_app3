import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/material_order.dart';

class OrderPdf {
  static Future<Uint8List> build(MaterialOrder order) async {
    final pdf = pw.Document();
    final date = DateFormat('dd-MM-yy').format(order.date);
    final rows = List.generate(30, (i) {
      final item = i < order.items.length ? order.items[i] : null;
      return [
        '${i + 1}', item?.description ?? '', item?.quantity ?? '',
        item?.color ?? '', item?.thickness ?? '', item?.measurements ?? '',
      ];
    });
    final signature = order.signature == null ? null : pw.MemoryImage(base64Decode(order.signature!));
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(26, 22, 26, 18),
      build: (_) => pw.Column(children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('HOLDING', style: pw.TextStyle(fontSize: 23, fontWeight: pw.FontWeight.bold)),
            pw.Text('GROUP', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ]),
          pw.Text('ORDEN DE MATERIAL', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
          pw.Text('N° ${order.number.toString().padLeft(6, '0')}', style: pw.TextStyle(fontSize: 16, color: PdfColors.red)),
        ]),
        pw.SizedBox(height: 10),
        _fieldRow('OBRA:', order.work, 'FECHA:', date),
        _fieldRow('TECNICO:', order.technician, 'N° ORDEN DE SERVICIO:', order.serviceOrder),
        _fieldRow('TRABAJO A REALIZAR:', order.job, '', ''),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: const ['N°', 'DESCRIPCION', 'CANTIDAD', 'COLOR', 'ESPESOR', 'MEDIDAS'],
          data: rows,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellHeight: 15,
          border: pw.TableBorder.all(width: .6),
          columnWidths: const {0: pw.FixedColumnWidth(22), 1: pw.FlexColumnWidth(3), 2: pw.FlexColumnWidth(1.15), 3: pw.FlexColumnWidth(1.15), 4: pw.FlexColumnWidth(1.05), 5: pw.FlexColumnWidth(1.85)},
        ),
        pw.Spacer(),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('SUPERVISOR DE OBRAS', style: const pw.TextStyle(fontSize: 8)),
          pw.Column(children: [
            if (signature != null) pw.Image(signature, width: 115, height: 45),
            pw.Text('V°B° GERENCIA', style: const pw.TextStyle(fontSize: 8)),
          ]),
        ]),
      ]),
    ));
    return pdf.save();
  }

  static pw.Widget _fieldRow(String labelA, String valueA, String labelB, String valueB) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.Row(children: [
      pw.Text(labelA, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      pw.Expanded(child: pw.Container(height: 13, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())), child: pw.Text(valueA, style: const pw.TextStyle(fontSize: 9)))),
      if (labelB.isNotEmpty) ...[
        pw.SizedBox(width: 14), pw.Text(labelB, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(width: 95, child: pw.Container(height: 13, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())), child: pw.Text(valueB, style: const pw.TextStyle(fontSize: 9)))),
      ],
    ]),
  );

  static Future<void> preview(MaterialOrder order) async => Printing.layoutPdf(onLayout: (_) => build(order));
}
