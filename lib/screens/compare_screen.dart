import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/product.dart';

class CompareScreen extends StatelessWidget {
  final AppController controller;
  const CompareScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final products = controller.compare.map(controller.byId).whereType<Product>().toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Compare · MEDIKA')),
      body: products.isEmpty
          ? const Center(child: Text('Нет моделей для сравнения'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [const DataColumn(label: Text('Параметр')), ...products.map((p) => DataColumn(label: SizedBox(width: 150, child: Text('${p.brand}\n${p.model}', style: const TextStyle(fontWeight: FontWeight.w900, color: MedikaColors.navy)))))],
                    rows: _rows(products),
                  ),
                ),
              ),
            ),
    );
  }

  List<DataRow> _rows(List<Product> products) {
    final keys = <String>{'Категория', 'Статус', ...products.expand((p) => p.specs.keys)};
    return keys.map((key) => DataRow(cells: [
      DataCell(Text(key, style: const TextStyle(fontWeight: FontWeight.w800))),
      ...products.map((p) => DataCell(Text(key == 'Категория' ? p.category : key == 'Статус' ? p.stock : p.specs[key] ?? '—'))),
    ])).toList();
  }
}
