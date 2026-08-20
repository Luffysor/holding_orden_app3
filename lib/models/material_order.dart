import 'dart:convert';

class OrderItem {
  OrderItem({
    required this.description,
    required this.quantity,
    required this.color,
    required this.thickness,
    required this.measurements,
  });

  final String description;
  final String quantity;
  final String color;
  final String thickness;
  final String measurements;

  Map<String, Object?> toMap() => {
        'description': description,
        'quantity': quantity,
        'color': color,
        'thickness': thickness,
        'measurements': measurements,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        description: map['description'] as String? ?? '',
        quantity: map['quantity'] as String? ?? '',
        color: map['color'] as String? ?? '',
        thickness: map['thickness'] as String? ?? '',
        measurements: map['measurements'] as String? ?? '',
      );
}

class MaterialOrder {
  MaterialOrder({
    this.id,
    required this.number,
    required this.date,
    required this.work,
    required this.technician,
    required this.serviceOrder,
    required this.job,
    required this.items,
    this.signature,
  });

  final int? id;
  final int number;
  final DateTime date;
  final String work;
  final String technician;
  final String serviceOrder;
  final String job;
  final List<OrderItem> items;
  final String? signature; // PNG codificado en Base64.

  Map<String, Object?> toMap() => {
        'id': id,
        'number': number,
        'date': date.toIso8601String(),
        'work': work,
        'technician': technician,
        'service_order': serviceOrder,
        'job': job,
        'items': jsonEncode(items.map((item) => item.toMap()).toList()),
        'signature': signature,
      };

  factory MaterialOrder.fromMap(Map<String, dynamic> map) => MaterialOrder(
        id: map['id'] as int?,
        number: map['number'] as int,
        date: DateTime.parse(map['date'] as String),
        work: map['work'] as String? ?? '',
        technician: map['technician'] as String? ?? '',
        serviceOrder: map['service_order'] as String? ?? '',
        job: map['job'] as String? ?? '',
        items: (jsonDecode(map['items'] as String) as List)
            .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
            .toList(),
        signature: map['signature'] as String?,
      );
}
