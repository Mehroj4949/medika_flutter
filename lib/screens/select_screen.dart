import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../core/localization.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/quote_dialog.dart';
import 'product_detail_screen.dart';

class SelectScreen extends StatefulWidget {
  final AppController controller;
  const SelectScreen({super.key, required this.controller});
  @override
  State<SelectScreen> createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
  String? category;
  String level = 'any';

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final text = MedikaText(controller.language);
    final categories = controller.products.map((e) => e.category).where((e) => e.isNotEmpty).toSet().toList()..sort();
    final recommendations = category == null ? <Product>[] : controller.products.where((p) => p.category == category).toList()..sort((a, b) => (b.stock == 'В наличии' ? 1 : 0).compareTo(a.stock == 'В наличии' ? 1 : 0));
    final selected = recommendations.where((p) {
      if (level == 'any') return true;
      final hay = p.searchText;
      return level == 'premium' ? RegExp(r'премиум|эксперт|premium|expert|i9|x10').hasMatch(hay) : level == 'basic' ? RegExp(r'базов|compact|практич|portable').hasMatch(hay) : true;
    }).take(3).toList();

    return ListView(padding: const EdgeInsets.all(12), children: [
      const Text('MEDIKA SELECT', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: MedikaColors.navy)),
      const SizedBox(height: 4),
      Text(text.tr('Подбор оборудования по задаче клиники', 'Интихоби таҷҳизот аз рӯи вазифаи клиника'), style: const TextStyle(color: MedikaColors.muted)),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(value: category, decoration: InputDecoration(labelText: text.tr('Направление', 'Самт')), items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => category = v)),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(value: level, decoration: InputDecoration(labelText: text.tr('Уровень системы', 'Сатҳи система')), items: [DropdownMenuItem(value: 'any', child: Text(text.tr('Не принципиально', 'Фарқ надорад'))), DropdownMenuItem(value: 'basic', child: Text(text.tr('Практичный', 'Амалӣ'))), DropdownMenuItem(value: 'premium', child: Text(text.tr('Экспертный / Премиум', 'Экспертӣ / Премиум')))], onChanged: (v) => setState(() => level = v ?? 'any')),
      const SizedBox(height: 20),
      if (category != null) Text(text.tr('Рекомендуемые модели', 'Моделҳои тавсияшуда'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: MedikaColors.navy)),
      const SizedBox(height: 10),
      if (category != null) LayoutBuilder(builder: (context, constraints) { final columns = constraints.maxWidth >= 900 ? 3 : 1; return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: selected.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: columns > 1 ? .63 : 1.05), itemBuilder: (_, i) { final p = selected[i]; return ProductCard(product: p, controller: controller, onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p, controller: controller))), onQuote: () => showQuoteDialog(context, product: '${p.brand} ${p.model}', language: controller.language)); }); }),
    ]);
  }
}
