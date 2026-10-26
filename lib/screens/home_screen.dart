import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../core/localization.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/product_image.dart';
import '../widgets/quote_dialog.dart';
import '../widgets/service_dialog.dart';
import 'catalog_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppController controller;
  final ValueChanged<int> changeTab;
  const HomeScreen({super.key, required this.controller, required this.changeTab});

  void _openProduct(BuildContext context, Product product) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => ProductDetailScreen(product: product, controller: controller),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(position: Tween(begin: const Offset(0, .05), end: Offset.zero).animate(curved), child: child),
          );
        },
      ),
    );
  }

  void _openCatalog(BuildContext context, {String? category, String? brand}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Scaffold(
        appBar: AppBar(),
        body: CatalogScreen(controller: controller, initialCategory: category, initialBrand: brand),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = MedikaText(controller.language);
    final products = controller.products;
    if (products.isEmpty) return const Center(child: CircularProgressIndicator());

    final categories = _categories(products).take(8).toList();
    final brandCounts = _brandCounts(products);
    final brands = brandCounts.keys.take(8).toList();
    final featured = _featured(products);
    final newItems = products.where((p) => p.isNew).take(6).toList();
    final promo = featured.firstWhere((p) => p.image.isNotEmpty, orElse: () => featured.isNotEmpty ? featured.first : products.first);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Reveal(
                  child: _SearchPill(
                    hints: [text.search, ...categories],
                    onTap: () => _openCatalog(context),
                  ),
                ),
                const SizedBox(height: 12),
                _Reveal(
                  index: 1,
                  child: _HeroCarousel(
                    text: text,
                    promo: promo,
                    slides: featured.take(3).toList(),
                    onSelect: () => changeTab(2),
                    onOpen: (p) => _openProduct(context, p),
                  ),
                ),
                const SizedBox(height: 22),
                _Reveal(child: _SectionHead(title: text.categories, action: text.all, onAction: () => changeTab(1))),
                const SizedBox(height: 10),
                LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 8 : 4;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: .8),
                    itemBuilder: (_, i) {
                      final category = categories[i];
                      final representative = products.firstWhere(
                        (p) => p.category == category && p.image.isNotEmpty,
                        orElse: () => products.firstWhere((p) => p.category == category),
                      );
                      return _Reveal(
                        index: i % columns,
                        offset: 22,
                        child: _Pressable(
                          radius: 16,
                          onTap: () => _openCatalog(context, category: category),
                          builder: (hover) => Padding(
                            padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: const LinearGradient(colors: [MedikaColors.softBlue, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                    ),
                                    padding: const EdgeInsets.all(5),
                                    child: AnimatedScale(
                                      scale: hover ? 1.1 : 1,
                                      duration: const Duration(milliseconds: 320),
                                      curve: Curves.easeOutCubic,
                                      child: ProductImage(product: representative),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(category, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, height: 1.15, fontWeight: FontWeight.w900, color: MedikaColors.navy)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 10),
                _Reveal(
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => changeTab(1),
                      icon: const Icon(Icons.grid_view_rounded),
                      label: Text(text.tr('Все категории', 'Ҳамаи категорияҳо')),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _Reveal(child: _SectionHead(title: text.brands, action: text.all, onAction: () => changeTab(1))),
                const SizedBox(height: 10),
                SizedBox(
                  height: 66,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    physics: const BouncingScrollPhysics(),
                    itemCount: brands.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 9),
                    itemBuilder: (_, i) {
                      final brand = brands[i];
                      return _Reveal(
                        index: i,
                        stagger: 50,
                        offset: 0,
                        slideX: 24,
                        child: _BrandChip(
                          brand: brand,
                          count: brandCounts[brand] ?? 0,
                          unit: text.tr('моделей', 'модел'),
                          onTap: () => _openCatalog(context, brand: brand),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
                _Reveal(child: _SectionHead(title: text.popular, action: text.all, onAction: () => changeTab(1))),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.crossAxisExtent >= 1000 ? 4 : 2;
              return SliverGrid(
                delegate: SliverChildBuilderDelegate((context, i) {
                  final product = featured[i];
                  return _Reveal(
                    index: i % columns,
                    stagger: 90,
                    offset: 30,
                    child: ProductCard(
                      product: product,
                      controller: controller,
                      onOpen: () => _openProduct(context, product),
                      onQuote: () => showQuoteDialog(context, product: '${product.brand} ${product.model}', language: controller.language),
                    ),
                  );
                }, childCount: featured.length),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: columns == 4 ? .63 : .57),
              );
            },
          ),
        ),
        if (newItems.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
              child: _Reveal(child: _SectionHead(title: text.newItems, action: text.all, onAction: () => changeTab(1), badge: true)),
            ),
          ),
        if (newItems.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 400,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: newItems.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final product = newItems[i];
                  return _Reveal(
                    index: i,
                    stagger: 80,
                    offset: 0,
                    slideX: 40,
                    child: SizedBox(
                      width: 230,
                      child: ProductCard(
                        product: product,
                        controller: controller,
                        onOpen: () => _openProduct(context, product),
                        onQuote: () => showQuoteDialog(context, product: '${product.brand} ${product.model}', language: controller.language),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
            child: Column(children: [
              _Reveal(
                child: _ActionTile(
                  icon: Icons.chat_bubble_outline,
                  title: text.quote,
                  subtitle: text.tr('Получить коммерческое предложение', 'Пешниҳоди тиҷоратӣ гиред'),
                  onTap: () => showQuoteDialog(context, product: '', language: controller.language),
                ),
              ),
              const SizedBox(height: 10),
              _Reveal(
                index: 1,
                child: _ActionTile(
                  icon: Icons.support_agent,
                  title: 'MEDIKA CARE',
                  subtitle: text.tr('Сервис и техническая поддержка', 'Сервис ва дастгирии техникӣ'),
                  onTap: () => showServiceDialog(context, language: controller.language),
                ),
              ),
              const SizedBox(height: 14),
              _Reveal(index: 2, child: _TrustStrip(text: text)),
              const SizedBox(height: 28),
            ]),
          ),
        ),
      ],
    );
  }

  List<String> _categories(List<Product> products) {
    const order = ['УЗИ', 'Лаборатория', 'Анестезия/ИВЛ', 'Мониторинг', 'Кардиология', 'Инфузия', 'Эндоскопия', 'Операционная', 'Рентген', 'ЛОР', 'Стоматология', 'Неонатология', 'Физиотерапия', 'Гепатология', 'Мебель'];
    final available = products.map((p) => p.category).toSet();
    return [...order.where(available.contains), ...available.where((e) => !order.contains(e))];
  }

  /// Brands sorted by number of models (keys keep that order).
  Map<String, int> _brandCounts(List<Product> products) {
    final counts = <String, int>{};
    for (final p in products) {
      if (p.brand.isEmpty) continue;
      counts[p.brand] = (counts[p.brand] ?? 0) + 1;
    }
    final keys = counts.keys.toList()..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));
    return {for (final k in keys) k: counts[k]!};
  }

  List<Product> _featured(List<Product> products) {
    const ids = ['resona', 'n8', 'magx10', 'mag800', 'a3', 'hepatus6'];
    final selected = <Product>[];
    for (final id in ids) {
      final match = products.where((p) => p.id == id);
      if (match.isNotEmpty) selected.add(match.first);
    }
    if (selected.length < 6) selected.addAll(products.where((p) => !selected.contains(p)).take(6 - selected.length));
    return selected.take(6).toList();
  }
}

/// The signature moment: an auto-playing hero with parallax product images,
/// drifting light blobs and an animated page indicator.
class _HeroCarousel extends StatefulWidget {
  final MedikaText text;
  final Product promo;
  final List<Product> slides;
  final VoidCallback onSelect;
  final ValueChanged<Product> onOpen;
  const _HeroCarousel({required this.text, required this.promo, required this.slides, required this.onSelect, required this.onOpen});

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> with SingleTickerProviderStateMixin {
  final PageController _pc = PageController();
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  Timer? _timer;
  int _page = 0;
  bool _dragging = false;

  int get _count => 1 + widget.slides.length;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _dragging || !_pc.hasClients) return;
      if (MediaQuery.of(context).disableAnimations) return;
      final next = (_pc.page ?? 0).round() + 1;
      _pc.animateToPage(next, duration: const Duration(milliseconds: 650), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 700;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: wide ? 250 : 214,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [MedikaColors.navy, MedikaColors.navy2, MedikaColors.blue], begin: Alignment.centerLeft, end: Alignment.centerRight),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _float,
              builder: (_, __) {
                final t = _float.value;
                return Stack(children: [
                  Positioned(right: -40 + 30 * t, top: -50 + 14 * t, child: _blob(190, .07)),
                  Positioned(left: 20 + 40 * t, bottom: -70, child: _blob(150, .05)),
                  Positioned(right: 120 - 30 * t, bottom: -30 + 10 * t, child: _blob(80, .06)),
                ]);
              },
            ),
            NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollStartNotification && n.dragDetails != null) _dragging = true;
                if (n is ScrollEndNotification) _dragging = false;
                return false;
              },
              child: PageView.builder(
                controller: _pc,
                onPageChanged: (i) => setState(() => _page = i % _count),
                itemBuilder: (_, i) => _slide(i, wide),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 14,
              child: Row(
                children: [
                  for (var i = 0; i < _count; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(right: 5),
                      width: _page == i ? 22 : 6,
                      height: 6,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: _page == i ? .95 : .35), borderRadius: BorderRadius.circular(3)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, double alpha) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: alpha)));

  Widget _slide(int index, bool wide) {
    final idx = index % _count;
    final isPromo = idx == 0;
    final product = isPromo ? widget.promo : widget.slides[idx - 1];
    final text = widget.text;

    return AnimatedBuilder(
      animation: Listenable.merge([_pc, _float]),
      builder: (_, __) {
        double page = 0;
        if (_pc.hasClients && _pc.position.haveDimensions) page = _pc.page ?? 0;
        final delta = (index - page).clamp(-1.0, 1.0);
        final fade = 1 - delta.abs() * .85;
        final bob = math.sin(_float.value * math.pi) * 9;

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 30),
          child: Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: fade.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(delta * -40, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            isPromo ? 'MEDIKA SELECT' : '${product.brand} · ${product.category}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFFCFE0FF), fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          isPromo ? text.tr('Подберём оборудование для вашей клиники', 'Барои клиникаи шумо таҷҳизот интихоб мекунем') : product.model,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: wide ? 26 : 20, height: 1.08, fontWeight: FontWeight.w900, letterSpacing: -.2),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isPromo ? text.tr('Несколько вопросов — и подходящие модели.', 'Чанд савол — ва моделҳои мувофиқ.') : product.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFC9D6EB), fontSize: 11, height: 1.3),
                        ),
                        const SizedBox(height: 11),
                        SizedBox(
                          height: 34,
                          child: FilledButton(
                            onPressed: isPromo ? widget.onSelect : () => widget.onOpen(product),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: MedikaColors.navy,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(isPromo ? text.tr('Начать подбор', 'Интихобро оғоз кунед') : text.details, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 15),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Opacity(
                opacity: fade.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(delta * 70, -bob),
                  child: SizedBox(
                    width: wide ? 210 : 112,
                    height: wide ? 190 : 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: wide ? 160 : 100,
                          height: wide ? 160 : 100,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .13)),
                        ),
                        ProductImage(product: product),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Fake search field with hints that rotate through your categories.
class _SearchPill extends StatefulWidget {
  final List<String> hints;
  final VoidCallback onTap;
  const _SearchPill({required this.hints, required this.onTap});

  @override
  State<_SearchPill> createState() => _SearchPillState();
}

class _SearchPillState extends State<_SearchPill> {
  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (mounted && widget.hints.length > 1) setState(() => _i = (_i + 1) % widget.hints.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hint = widget.hints[_i % widget.hints.length];
    return _Pressable(
      radius: 16,
      lift: false,
      onTap: widget.onTap,
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: MedikaColors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween(begin: const Offset(0, .8), end: Offset.zero).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  layoutBuilder: (current, previous) => Stack(alignment: Alignment.centerLeft, children: [...previous, if (current != null) current]),
                  child: Text(hint, key: ValueKey(hint), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: MedikaColors.muted, fontSize: 14)),
                ),
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: MedikaColors.softBlue, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.tune_rounded, size: 17, color: MedikaColors.blue),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  final String brand;
  final int count;
  final String unit;
  final VoidCallback onTap;
  const _BrandChip({required this.brand, required this.count, required this.unit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: _Pressable(
        radius: 16,
        onTap: onTap,
        builder: (hover) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(colors: hover ? [MedikaColors.blue, MedikaColors.navy2] : [MedikaColors.navy2, MedikaColors.navy]),
                ),
                alignment: Alignment.center,
                child: Text(brand.characters.first.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(brand, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: MedikaColors.navy)),
                    Text('$count $unit', style: const TextStyle(fontSize: 10, color: MedikaColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;
  final bool badge;
  const _SectionHead({required this.title, required this.action, required this.onAction, this.badge = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Container(
            width: 4,
            height: 20 * v,
            decoration: BoxDecoration(color: MedikaColors.blue, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Row(
            children: [
              Flexible(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: MedikaColors.navy))),
              if (badge) ...[
                const SizedBox(width: 8),
                const _SparkBadge(),
              ],
            ],
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Row(mainAxisSize: MainAxisSize.min, children: [Text(action), const SizedBox(width: 3), const Icon(Icons.arrow_forward_rounded, size: 15)]),
        ),
      ],
    );
  }
}

/// Small twinkling star next to the "new" section title.
class _SparkBadge extends StatefulWidget {
  const _SparkBadge();

  @override
  State<_SparkBadge> createState() => _SparkBadgeState();
}

class _SparkBadgeState extends State<_SparkBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: .8, end: 1.15).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFFE8A317)),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      radius: 18,
      onTap: onTap,
      builder: (hover) => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: [MedikaColors.blue, MedikaColors.navy2], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: MedikaColors.navy, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: MedikaColors.muted)),
                ],
              ),
            ),
            AnimatedSlide(
              offset: Offset(hover ? .25 : 0, 0),
              duration: const Duration(milliseconds: 220),
              child: const Icon(Icons.arrow_forward_rounded, color: MedikaColors.blue),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  final MedikaText text;
  const _TrustStrip({required this.text});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.local_shipping_outlined, text.delivery),
      (Icons.settings_outlined, text.installation),
      (Icons.verified_outlined, text.warranty),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: MedikaColors.softBlue,
        border: Border.all(color: MedikaColors.line),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 700 + i * 160),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v.clamp(0.0, 1.3), child: child),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: MedikaColors.blue.withValues(alpha: .15), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Icon(items[i].$1, color: MedikaColors.blue, size: 22),
                    ),
                    const SizedBox(height: 7),
                    Text(items[i].$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: MedikaColors.navy)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Reusable tappable surface: press-scale, hover lift, soft shadow.
class _Pressable extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback onTap;
  final double radius;
  final bool lift;
  const _Pressable({required this.builder, required this.onTap, this.radius = 16, this.lift = true});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final lifted = widget.lift && _hover && !_down;
    final r = BorderRadius.circular(widget.radius);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _down ? .97 : 1,
        duration: const Duration(milliseconds: 130),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, lifted ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: r,
            border: Border.all(color: _hover ? MedikaColors.blue.withValues(alpha: .4) : MedikaColors.line),
            boxShadow: [BoxShadow(color: MedikaColors.navy.withValues(alpha: lifted ? .14 : .05), blurRadius: lifted ? 20 : 10, offset: Offset(0, lifted ? 8 : 3))],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: r,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _down = true),
              onTapUp: (_) => setState(() => _down = false),
              onTapCancel: () => setState(() => _down = false),
              child: widget.builder(_hover),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fade + slide entrance. Lazily-built sliver/list children animate as they scroll into range.
class _Reveal extends StatefulWidget {
  final Widget child;
  final int index;
  final int stagger;
  final double offset;
  final double slideX;
  const _Reveal({required this.child, this.index = 0, this.stagger = 70, this.offset = 18, this.slideX = 0});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: math.min(widget.index, 6) * widget.stagger), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(offset: Offset((1 - _a.value) * widget.slideX, (1 - _a.value) * widget.offset), child: child),
      ),
    );
  }
}