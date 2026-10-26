import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/localization.dart';
import '../data/medika_api.dart';

Future<void> showQuoteDialog(BuildContext context, {required String product, required String language}) async {
  final clinic = TextEditingController();
  final contact = TextEditingController();
  final phone = TextEditingController();
  final city = TextEditingController();
  final note = TextEditingController();
  final text = MedikaText(language);
  final api = MedikaApi();
  bool busy = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(text.quote),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (product.isNotEmpty) Align(alignment: Alignment.centerLeft, child: Text(product, style: const TextStyle(fontWeight: FontWeight.w800, color: MedikaColors.navy))),
                const SizedBox(height: 12),
                TextField(controller: clinic, decoration: InputDecoration(labelText: text.tr('Клиника *', 'Клиника *'))),
                const SizedBox(height: 10),
                TextField(controller: contact, decoration: InputDecoration(labelText: text.tr('Контактное лицо *', 'Шахси тамос *'))),
                const SizedBox(height: 10),
                TextField(controller: phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: text.tr('Телефон *', 'Телефон *'))),
                const SizedBox(height: 10),
                TextField(controller: city, decoration: InputDecoration(labelText: text.tr('Город', 'Шаҳр'))),
                const SizedBox(height: 10),
                TextField(controller: note, maxLines: 3, decoration: InputDecoration(labelText: text.tr('Комментарий', 'Шарҳ'))),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: Text(text.tr('Отмена', 'Бекор'))),
          FilledButton(
            onPressed: busy ? null : () async {
              if (clinic.text.trim().isEmpty || contact.text.trim().isEmpty || phone.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text.tr('Заполните обязательные поля', 'Майдонҳои ҳатмиро пур кунед'))));
                return;
              }
              setState(() => busy = true);
              try {
                final result = await api.createQuote(product: product, clinic: clinic.text, contact: contact.text, phone: phone.text, city: city.text, note: note.text);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${text.tr('Запрос принят', 'Дархост қабул шуд')}: ${result['requestId'] ?? ''}')));
              } catch (e) {
                setState(() => busy = false);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(text.quote),
          ),
        ],
      ),
    ),
  );
}
