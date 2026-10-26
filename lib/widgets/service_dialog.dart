import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../data/medika_api.dart';

Future<void> showServiceDialog(BuildContext context, {required String language, String equipment = ''}) async {
  final equipmentCtrl = TextEditingController(text: equipment);
  final clinic = TextEditingController();
  final contact = TextEditingController();
  final phone = TextEditingController();
  final issue = TextEditingController();
  final text = MedikaText(language);
  final api = MedikaApi();
  bool busy = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('MEDIKA CARE'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: equipmentCtrl, decoration: InputDecoration(labelText: text.tr('Оборудование *', 'Таҷҳизот *'))),
                const SizedBox(height: 10),
                TextField(controller: clinic, decoration: InputDecoration(labelText: text.tr('Клиника *', 'Клиника *'))),
                const SizedBox(height: 10),
                TextField(controller: contact, decoration: InputDecoration(labelText: text.tr('Контакт *', 'Тамос *'))),
                const SizedBox(height: 10),
                TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Телефон *')),
                const SizedBox(height: 10),
                TextField(controller: issue, maxLines: 4, decoration: InputDecoration(labelText: text.tr('Опишите проблему *', 'Мушкилотро нависед *'))),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: Text(text.tr('Отмена', 'Бекор'))),
          FilledButton(
            onPressed: busy ? null : () async {
              if ([equipmentCtrl, clinic, contact, phone, issue].any((c) => c.text.trim().isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text.tr('Заполните обязательные поля', 'Майдонҳои ҳатмиро пур кунед'))));
                return;
              }
              setState(() => busy = true);
              try {
                final result = await api.createService(equipment: equipmentCtrl.text, clinic: clinic.text, contact: contact.text, phone: phone.text, issue: issue.text);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${text.tr('Заявка принята', 'Дархост қабул шуд')}: ${result['ticketId'] ?? ''}')));
              } catch (e) {
                setState(() => busy = false);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(text.tr('Отправить', 'Фиристодан')),
          ),
        ],
      ),
    ),
  );
}
