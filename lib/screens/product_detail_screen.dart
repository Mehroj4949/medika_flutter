import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../core/localization.dart';
import '../models/product.dart';
import '../widgets/product_image.dart';
import '../widgets/quote_dialog.dart';
import '../widgets/service_dialog.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final AppController controller;
  const ProductDetailScreen({super.key, required this.product, required this.controller});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> _offset = ValueNotifier(0);

  Product get product => widget.product;
  AppController get controller => widget.controller;
  bool get _fav => controller.favorites.contains(product.id);
  bool get _comparing => controller.compare.contains(product.id);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _offset.value = _scroll.hasClients ? _scroll.offset : 0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.lightImpact();
    await Future<void>.sync(() {
      controller.toggleFavorite(product.id);
    });
    if (mounted) setState(() {});
  }

  Future<void> _toggleCompare() async {
    HapticFeedback.selectionClick();
    final message = await controller.toggleCompare(product);
    if (!mounted) return;
    setState(() {});
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)));
    }
  }

  void _quote() => showQuoteDialog(context, product: '${product.brand} ${product.model}', language: controller.language);

  void _service() => showServiceDialog(context, language: controller.language, equipment: '${product.brand} ${product.model}');

  @override
  Widget build(BuildContext context) {
    final text = MedikaText(controller.language);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return wide ? _buildWide(text) : _buildNarrow(text);
      },
    );
  }

  // ---------- Narrow (phone) ----------

  Widget _buildNarrow(MedikaText text) {
    final top = MediaQuery.paddingOf(context).top + kToolbarHeight;
    return Scaffold(
      bottomNavigationBar: _BottomBar(priceLabel: text.priceRequest, quoteLabel: text.quote, onQuote: _quote),
      body: CustomScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 330,
            backgroundColor: MedikaColors.softBlue,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            leading: Padding(padding: const EdgeInsets.all(6), child: _RoundButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.maybePop(context))),
            title: ValueListenableBuilder<double>(
              valueListenable: _offset,
              builder: (_, o, child) => Opacity(opacity: ((o - 200) / 80).clamp(0.0, 1.0), child: child),
              child: Text('${product.brand} ${product.model}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: MedikaColors.navy)),
            ),
            actions: [
              _compareAction(),
              _favoriteAction(),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _ImageStage(product: product, topPadding: top),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 28),
            sliver: SliverList(delegate: SliverChildListDelegate(_info(text, wide: false))),
          ),
        ],
      ),
    );
  }

  // ---------- Wide (tablet / web) ----------

  Widget _buildWide(MedikaText text) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${product.brand} ${product.model}'),
        actions: [_compareAction(), _favoriteAction(), const SizedBox(width: 12)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 11,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: SizedBox(height: 460, child: _ImageStage(product: product, topPadding: 20)),
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(flex: 10, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _info(text, wide: true))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _compareAction() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
        child: _RoundButton(
          icon: Icons.compare_arrows_rounded,
          active: _comparing,
          activeColor: MedikaColors.blue,
          rotateWhenActive: true,
          onTap: _toggleCompare,
        ),
      );

  Widget _favoriteAction() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
        child: _RoundButton(
          icon: _fav ? Icons.favorite : Icons.favorite_border,
          iconColor: _fav ? const Color(0xFFE5365A) : null,
          pop: _fav,
          onTap: _toggleFavorite,
        ),
      );

  // ---------- Shared content ----------

  List<Widget> _info(MedikaText text, {required bool wide}) {
    final inStock = product.stock == 'В наличии';
    var n = 0;
    Widget r(Widget child, {double offset = 18}) => _Reveal(index: n++, offset: offset, child: child);

    return [
      r(Row(
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: MedikaColors.softBlue, borderRadius: BorderRadius.circular(20)),
              child: Text('${product.brand} · ${product.category}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: MedikaColors.blue, fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 8),
          _StockPill(inStock: inStock, label: inStock ? text.tr('В наличии', 'Дар анбор') : text.tr('Под заказ', 'Бо фармоиш')),
        ],
      )),
      const SizedBox(height: 12),
      r(Text(product.model, style: TextStyle(fontSize: wide ? 32 : 27, height: 1.05, fontWeight: FontWeight.w900, color: MedikaColors.navy, letterSpacing: -.4))),
      const SizedBox(height: 10),
      r(Text(product.description, style: const TextStyle(fontSize: 14.5, height: 1.5, color: MedikaColors.muted))),
      const SizedBox(height: 16),
      r(Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors: [MedikaColors.navy, MedikaColors.navy2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.sell_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text.priceRequest, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white))),
          ],
        ),
      )),
      const SizedBox(height: 12),
      if (wide) ...[
        r(SizedBox(width: double.infinity, height: 48, child: FilledButton.icon(onPressed: _quote, icon: const Icon(Icons.chat_bubble_outline), label: Text(text.quote)))),
        const SizedBox(height: 8),
      ],
      r(SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(onPressed: _service, icon: const Icon(Icons.build_outlined), label: Text(text.tr('Сервис / консультация', 'Сервис / машварат'))),
      )),
      const SizedBox(height: 18),
      _TrustGrid(text: text),
      if (product.benefits.isNotEmpty) ...[
        const SizedBox(height: 24),
        _Reveal(child: _Title(text.tr('Ключевые преимущества', 'Бартариҳои асосӣ'))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < product.benefits.length; i++)
              _Reveal(
                index: i,
                stagger: 60,
                offset: 12,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: MedikaColors.line)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFDDF4E9)),
                        child: const Icon(Icons.check_rounded, size: 14, color: Color(0xFF1E9E6A)),
                      ),
                      const SizedBox(width: 7),
                      Flexible(child: Text(product.benefits[i], style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: MedikaColors.navy))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
      if (product.specs.isNotEmpty) ...[
        const SizedBox(height: 24),
        _Reveal(child: _Title(text.tr('Технические характеристики', 'Характеристикаҳои техникӣ'))),
        const SizedBox(height: 10),
        _Reveal(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: MedikaColors.line)),
              child: Column(
                children: [
                  for (final (i, e) in product.specs.entries.indexed)
                    Container(
                      color: i.isEven ? MedikaColors.softBlue.withValues(alpha: .55) : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(e.key, style: const TextStyle(color: MedikaColors.muted, fontSize: 13))),
                          const SizedBox(width: 12),
                          Expanded(child: Text(e.value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800, color: MedikaColors.navy, fontSize: 13))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    ];
  }
}

/// Image stage: soft gradient, drifting light circles and a gently floating product.
class _ImageStage extends StatefulWidget {
  final Product product;
  final double topPadding;
  const _ImageStage({required this.product, required this.topPadding});

  @override
  State<_ImageStage> createState() => _ImageStageState();
}

class _ImageStageState extends State<_ImageStage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce && _c.isAnimating) _c.stop();
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [MedikaColors.softBlue, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = Curves.easeInOut.transform(_c.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(right: -40 + 24 * t, top: 30, child: _circle(170, .10)),
              Positioned(left: -50 + 30 * t, bottom: 10, child: _circle(140, .07)),
              Padding(
                padding: EdgeInsets.fromLTRB(26, widget.topPadding, 26, 26),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: .85, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutBack,
                  builder: (_, s, child) => Opacity(opacity: ((s - .85) / .15).clamp(0.0, 1.0), child: Transform.scale(scale: s, child: child)),
                  child: Transform.translate(
                    offset: Offset(0, -10 * math.sin(t * math.pi)),
                    child: ProductImage(product: widget.product),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _circle(double size, double alpha) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: MedikaColors.blue.withValues(alpha: alpha)));
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;
  final Color? iconColor;
  final bool pop;
  final bool rotateWhenActive;
  const _RoundButton({required this.icon, required this.onTap, this.active = false, this.activeColor, this.iconColor, this.pop = false, this.rotateWhenActive = false});

  @override
  Widget build(BuildContext context) {
    final bg = active ? (activeColor ?? MedikaColors.blue) : Colors.white.withValues(alpha: .95);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: (active ? MedikaColors.blue : MedikaColors.navy).withValues(alpha: active ? .35 : .12), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Center(
          child: AnimatedRotation(
            turns: rotateWhenActive && active ? .5 : 0,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: pop ? Curves.elasticOut : Curves.easeOut,
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(icon, key: ValueKey('$icon$active'), size: 20, color: active ? Colors.white : (iconColor ?? MedikaColors.navy)),
            ),
          ),
        ),
      ),
    );
  }
}

class _StockPill extends StatelessWidget {
  final bool inStock;
  final String label;
  const _StockPill({required this.inStock, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = inStock ? const Color(0xFF1E9E6A) : const Color(0xFFD98A12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: .35))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Container(width: 4, height: 20 * v, decoration: BoxDecoration(color: MedikaColors.blue, borderRadius: BorderRadius.circular(2))),
        ),
        const SizedBox(width: 9),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: MedikaColors.navy))),
      ],
    );
  }
}

/// Persistent quote bar so the main action is always one tap away on phones.
class _BottomBar extends StatelessWidget {
  final String priceLabel;
  final String quoteLabel;
  final VoidCallback onQuote;
  const _BottomBar({required this.priceLabel, required this.quoteLabel, required this.onQuote});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: MedikaColors.line)),
        boxShadow: [BoxShadow(color: MedikaColors.navy.withValues(alpha: .06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Expanded(flex: 4, child: Text(priceLabel, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: MedikaColors.navy, height: 1.15))),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: onQuote,
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    icon: const Icon(Icons.chat_bubble_outline, size: 19),
                    label: FittedBox(fit: BoxFit.scaleDown, child: Text(quoteLabel, style: const TextStyle(fontWeight: FontWeight.w800))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustGrid extends StatelessWidget {
  final MedikaText text;
  const _TrustGrid({required this.text});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.local_shipping_outlined, text.delivery, text.tr('По Таджикистану', 'Дар Тоҷикистон')),
      (Icons.settings_outlined, text.installation, text.tr('Пусконаладка MEDIKA', 'Ба кор даровардани MEDIKA')),
      (Icons.verified_outlined, text.warranty, text.tr('Гарантийное сопровождение', 'Дастгирии кафолатӣ')),
      (Icons.support_agent_outlined, 'MEDIKA CARE', text.tr('Сервис после установки', 'Сервис баъд аз насб')),
    ];
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        for (var i = 0; i < items.length; i++)
          _Reveal(
            index: i,
            stagger: 80,
            offset: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: MedikaColors.line)),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: MedikaColors.softBlue, borderRadius: BorderRadius.circular(11)),
                    child: Icon(items[i].$1, color: MedikaColors.blue, size: 20),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: MedikaColors.navy)),
                        const SizedBox(height: 2),
                        Text(items[i].$3, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: MedikaColors.muted, height: 1.2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Fade + slide-up entrance with a small stagger.
class _Reveal extends StatefulWidget {
  final Widget child;
  final int index;
  final int stagger;
  final double offset;
  const _Reveal({required this.child, this.index = 0, this.stagger = 70, this.offset = 18});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: math.min(widget.index, 8) * widget.stagger), () {
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