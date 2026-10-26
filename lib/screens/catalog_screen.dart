import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../core/localization.dart';
import '../widgets/product_card.dart';
import '../widgets/quote_dialog.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  final AppController controller;
  final String? initialCategory;
  final String? initialBrand;
  const CatalogScreen({super.key, required this.controller, this.initialCategory, this.initialBrand});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with SingleTickerProviderStateMixin {
  final search = TextEditingController();
  final searchFocus = FocusNode();
  late final AnimationController _pulse;
  String category = 'Все';
  String brand = 'Все';
  String availability = 'all';

  @override
  void initState() {
    super.initState();
    category = widget.initialCategory ?? 'Все';
    brand = widget.initialBrand ?? 'Все';
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    searchFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pulse.dispose();
    searchFocus.dispose();
    search.dispose();
    super.dispose();
  }

  bool get _hasFilters => category != 'Все' || brand != 'Все' || availability != 'all' || search.text.trim().isNotEmpty;

  void _resetAll() {
    setState(() {
      category = 'Все';
      brand = 'Все';
      availability = 'all';
      search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final text = MedikaText(controller.language);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion && _pulse.isAnimating) {
      _pulse.stop();
    } else if (!reduceMotion && !_pulse.isAnimating) {
      _pulse.repeat();
    }

    final categoryItems = controller.products.map((e) => e.category).where((e) => e.isNotEmpty).toSet().toList()..sort();
    final categories = ['Все', ...categoryItems];
    final scoped = category == 'Все' ? controller.products : controller.products.where((p) => p.category == category).toList();
    final brandItems = scoped.map((e) => e.brand).where((e) => e.isNotEmpty).toSet().toList()..sort();
    final brands = ['Все', ...brandItems];
    final q = search.text.trim().toLowerCase();
    final items = controller.products.where((p) {
      return (category == 'Все' || p.category == category) &&
          (brand == 'Все' || p.brand == brand) &&
          (availability == 'all' || (availability == 'stock' ? p.stock == 'В наличии' : p.stock != 'В наличии')) &&
          (q.isEmpty || p.searchText.contains(q));
    }).toList();
    final filterKey = '$category|$brand|$availability|$q';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Reveal(
                  index: 0,
                  child: _HeroBanner(
                    pulse: _pulse,
                    title: text.catalog,
                    count: controller.products.length,
                    suffix: text.tr('моделей оборудования', 'модели таҷҳизот'),
                    reduceMotion: reduceMotion,
                  ),
                ),
                const SizedBox(height: 14),
                _Reveal(index: 1, child: _buildSearch(text)),
                const SizedBox(height: 16),
                _Reveal(
                  index: 2,
                  child: Row(
                    children: [
                      const Icon(Icons.grid_view_rounded, size: 17, color: MedikaColors.blue),
                      const SizedBox(width: 7),
                      Text(text.categories, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MedikaColors.navy)),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                _Reveal(
                  index: 3,
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      physics: const BouncingScrollPhysics(),
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final item = categories[i];
                        return _FilterPill(
                          label: item == 'Все' ? text.all : item,
                          selected: category == item,
                          onTap: () => setState(() {
                            category = item;
                            brand = 'Все';
                          }),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Reveal(
                  index: 4,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: brands.contains(brand) ? brand : 'Все',
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(14),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.business_outlined, size: 19),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        items: brands
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e == 'Все' ? text.tr('Все бренды', 'Ҳама брендҳо') : e, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => brand = v ?? 'Все'),
                      ),
                      const SizedBox(height: 10),
                      _AvailabilitySwitch(
                        value: availability,
                        labels: {
                          'all': text.tr('Все', 'Ҳама'),
                          'stock': text.tr('В наличии', 'Дар анбор'),
                          'order': text.tr('Под заказ', 'Бо фармоиш'),
                        },
                        onChanged: (v) => setState(() => availability = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(text.tr('Оборудование', 'Таҷҳизот'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: MedikaColors.navy)),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(scale: Tween(begin: .85, end: 1.0).animate(anim), child: child),
                      ),
                      child: _hasFilters
                          ? Padding(
                              key: const ValueKey('reset'),
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: _resetAll,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.restart_alt_rounded, size: 15, color: MedikaColors.blue),
                                      const SizedBox(width: 4),
                                      Text(text.tr('Сбросить', 'Тоза кардан'),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: MedikaColors.blue)),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('none')),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: MedikaColors.softBlue, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${text.tr('Найдено', 'Ёфт шуд')}: ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: MedikaColors.navy2)),
                          _CountText(
                            value: items.length,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: MedikaColors.navy2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
              child: _EmptyState(
                pulse: _pulse,
                title: text.tr('Ничего не найдено', 'Ҳеҷ чиз ёфт нашуд'),
                subtitle: text.tr('Измените запрос или фильтры', 'Дархост ё филтрҳоро тағйир диҳед'),
                actionLabel: text.tr('Сбросить фильтры', 'Тоза кардани филтрҳо'),
                onAction: _resetAll,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.crossAxisExtent >= 1000
                    ? 4
                    : constraints.crossAxisExtent >= 700
                        ? 3
                        : 2;
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = items[index];
                    return _Reveal(
                      key: ValueKey('$filterKey#${product.hashCode}#$index'),
                      index: index % columns == 0 ? index ~/ columns : index ~/ columns + (index % columns) * 0,
                      stagger: 70,
                      offset: 28,
                      child: ProductCard(
                        product: product,
                        controller: controller,
                        onOpen: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(milliseconds: 380),
                            reverseTransitionDuration: const Duration(milliseconds: 280),
                            pageBuilder: (_, __, ___) => ProductDetailScreen(product: product, controller: controller),
                            transitionsBuilder: (_, anim, __, child) {
                              final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
                              return FadeTransition(
                                opacity: curved,
                                child: SlideTransition(
                                  position: Tween(begin: const Offset(0, .05), end: Offset.zero).animate(curved),
                                  child: child,
                                ),
                              );
                            },
                          ),
                        ),
                        onQuote: () => showQuoteDialog(context, product: '${product.brand} ${product.model}', language: controller.language),
                      ),
                    );
                  }, childCount: items.length),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: columns >= 3 ? .63 : .57,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSearch(MedikaText text) {
    final focused = searchFocus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MedikaColors.blue.withValues(alpha: focused ? .22 : 0),
            blurRadius: focused ? 20 : 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: search,
        focusNode: searchFocus,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          prefixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.search_rounded, key: ValueKey(focused), color: focused ? MedikaColors.navy2 : MedikaColors.blue),
          ),
          hintText: text.search,
          suffixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: search.text.isEmpty
                ? const SizedBox.shrink(key: ValueKey('empty'))
                : IconButton(
                    key: const ValueKey('clear'),
                    tooltip: text.tr('Очистить поиск', 'Ҷустуҷӯро пок кардан'),
                    onPressed: () => setState(search.clear),
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Hero banner with a live ECG line — the one signature moment of the screen.
class _HeroBanner extends StatelessWidget {
  final Animation<double> pulse;
  final String title;
  final int count;
  final String suffix;
  final bool reduceMotion;
  const _HeroBanner({required this.pulse, required this.title, required this.count, required this.suffix, required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [MedikaColors.navy, MedikaColors.navy2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .05)),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 64,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: pulse,
                  builder: (_, __) => CustomPaint(painter: _EcgPainter(reduceMotion ? .35 : pulse.value)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 52),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -.3)),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            _CountText(
                              value: count,
                              duration: const Duration(milliseconds: 1100),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                            const SizedBox(width: 6),
                            Flexible(child: Text(suffix, style: const TextStyle(fontSize: 13, color: Color(0xFFD5E2F8)))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _BreathingBadge(pulse: pulse),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingBadge extends StatelessWidget {
  final Animation<double> pulse;
  const _BreathingBadge({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, child) {
        final wave = (math.sin(pulse.value * 2 * math.pi * 2) + 1) / 2;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 48 + 14 * wave,
              height: 48 + 14 * wave,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .10 * (1 - wave))),
            ),
            child!,
          ],
        );
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 26),
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  final double phase;
  _EcgPainter(this.phase);

  static const _beat = <Offset>[
    Offset(0, 0), Offset(.15, 0), Offset(.20, -.15), Offset(.25, 0), Offset(.32, 0),
    Offset(.36, .15), Offset(.40, -.95), Offset(.45, .7), Offset(.50, 0), Offset(.62, 0),
    Offset(.70, -.25), Offset(.78, 0), Offset(1, 0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final period = math.max(160.0, size.width * .55);
    final midY = size.height * .55;
    final amp = size.height * .38;
    final shift = phase * period;
    final path = Path();
    var started = false;
    for (var k = -1; k * period - shift < size.width + period; k++) {
      for (final p in _beat) {
        final x = k * period + p.dx * period - shift;
        final y = midY + p.dy * amp;
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }
    }
    final rect = Offset.zero & size;
    final shader = LinearGradient(
      colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: .75), Colors.white.withValues(alpha: .75), Colors.white.withValues(alpha: 0)],
      stops: const [0, .25, .75, 1],
    ).createShader(rect);
    canvas.drawPath(
      path,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _EcgPainter old) => old.phase != phase;
}

/// Category pill: colour, shadow and scale animate on selection.
class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.04 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? MedikaColors.blue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? MedikaColors.blue : MedikaColors.line),
          boxShadow: [
            BoxShadow(
              color: MedikaColors.blue.withValues(alpha: selected ? .30 : 0),
              blurRadius: selected ? 12 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : MedikaColors.navy),
                  child: Text(label),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three-way segmented control with a sliding indicator.
class _AvailabilitySwitch extends StatelessWidget {
  final String value;
  final Map<String, String> labels;
  final ValueChanged<String> onChanged;
  const _AvailabilitySwitch({required this.value, required this.labels, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final keys = labels.keys.toList();
    final index = keys.indexOf(value);
    final align = -1.0 + index * (2 / (keys.length - 1));
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: MedikaColors.softBlue, borderRadius: BorderRadius.circular(14)),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(align, 0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 1 / keys.length,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: MedikaColors.navy.withValues(alpha: .12), blurRadius: 8, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final k in keys)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(k),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: value == k ? FontWeight.w800 : FontWeight.w600,
                          color: value == k ? MedikaColors.navy : MedikaColors.muted,
                        ),
                        child: Text(labels[k]!, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Number that counts up/down smoothly to its new value.
class _CountText extends StatelessWidget {
  final int value;
  final TextStyle style;
  final Duration duration;
  const _CountText({required this.value, required this.style, this.duration = const Duration(milliseconds: 450)});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(v.round().toString(), style: style.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
    );
  }
}

/// Fade + slide-up entrance with a small stagger.
class _Reveal extends StatefulWidget {
  final Widget child;
  final int index;
  final int stagger;
  final double offset;
  const _Reveal({super.key, required this.child, this.index = 0, this.stagger = 60, this.offset = 18});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: math.min(widget.index, 6) * widget.stagger);
    Future.delayed(delay, () {
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
        child: Transform.translate(offset: Offset(0, (1 - _a.value) * widget.offset), child: child),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Animation<double> pulse;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  const _EmptyState({required this.pulse, required this.title, required this.subtitle, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: pulse,
          builder: (_, child) => Transform.translate(offset: Offset(0, math.sin(pulse.value * 2 * math.pi * 2) * 5), child: child),
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(color: MedikaColors.softBlue, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.search_off_rounded, color: MedikaColors.blue, size: 36),
          ),
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: MedikaColors.navy)),
        const SizedBox(height: 5),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: MedikaColors.muted)),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: onAction,
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}