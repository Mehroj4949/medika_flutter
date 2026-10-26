import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../core/localization.dart';
import '../widgets/quote_dialog.dart';
import '../widgets/service_dialog.dart';

class ProfileScreen extends StatelessWidget {
  final AppController controller;
  const ProfileScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final text = MedikaText(controller.language);
    return ListView(padding: const EdgeInsets.all(12), children: [
      Text('My MEDIKA', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: MedikaColors.navy)),
      const SizedBox(height: 4),
      Text(text.tr('Запросы, оборудование, гарантия и сервис', 'Дархостҳо, таҷҳизот, кафолат ва сервис'), style: const TextStyle(color: MedikaColors.muted)),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(18)), gradient: LinearGradient(colors: [MedikaColors.navy, MedikaColors.navy2])),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('MY MEDIKA', style: TextStyle(color: Color(0xFFA9C5FF), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.1)), const SizedBox(height: 7), Text(text.tr('Ваш персональный кабинет MEDIKA', 'Кабинети шахсии MEDIKA'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 7), Text(text.tr('Flutter-версия готова к подключению Google/Apple авторизации. Клиентские Quote и Service уже работают через существующий MEDIKA API.', 'Версияи Flutter барои пайвасти Google/Apple authorization омода аст. Quote ва Service аллакай бо MEDIKA API кор мекунанд.'), style: const TextStyle(color: Color(0xFFC9D6EB), height: 1.4))]),
      ),
      const SizedBox(height: 12),
      Card(child: ListTile(leading: const Icon(Icons.chat_bubble_outline, color: MedikaColors.blue), title: Text(text.quote, style: const TextStyle(fontWeight: FontWeight.w900)), onTap: () => showQuoteDialog(context, product: '', language: controller.language))),
      const SizedBox(height: 8),
      Card(child: ListTile(leading: const Icon(Icons.support_agent, color: MedikaColors.blue), title: const Text('MEDIKA CARE', style: TextStyle(fontWeight: FontWeight.w900)), onTap: () => showServiceDialog(context, language: controller.language))),
      const SizedBox(height: 8),
      Card(child: ListTile(leading: const Icon(Icons.language, color: MedikaColors.blue), title: Text(controller.language == 'ru' ? 'Русский → Тоҷикӣ' : 'Тоҷикӣ → Русский', style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(text.tr('Язык приложения', 'Забони барнома')), onTap: controller.toggleLanguage)),
      const SizedBox(height: 14),
      const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('Flutter migration note: authenticated My MEDIKA / Google-Apple sign-in and MEDIKA ADMIN should be connected with native mobile auth in the next migration pass. The existing web app remains unchanged.', style: TextStyle(color: MedikaColors.muted, height: 1.4)))),
    ]);
  }
}
