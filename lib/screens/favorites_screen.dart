import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../core/localization.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/quote_dialog.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final AppController controller;

  /// Optional: shown as a button on the empty state (e.g. `() => changeTab(1)` to jump to the catalog).
  final VoidCallback? onBrowse;
  const FavoritesScreen({super.key, required this.controller, this.onBrowse});

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

  @override
  Widget build(BuildContext context) {
    final text = MedikaText(controller.language);
    final items = controller.favorites.map(controller.byId).whereType<Product>().toList();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      child: items.isEmpty
          ? _EmptyFavorites(
              key: const ValueKey('empty'),
              message: text.tr('Сохраняйте понравившиеся модели — они появятся здесь.', 'Моделҳои писандидаро нигоҳ доред — онҳо дар ин ҷо пайдо мешаванд.'),
              title: text.favorites,
              actionLabel: text.tr('Открыть каталог', 'Кушодани феҳрист'),
              onBrowse: onBrowse,
            )
          : LayoutBuilder(
              key: const ValueKey('list'),
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1000
                    ? 4
                    : constraints.maxWidth >= 700
                        ? 3
                        : 2;
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                        child: _Reveal(
                          child: _Header(
                            title: text.favorites,
                            count: items.length,
                            unit: text.tr('моделей сохранено', 'модел захира шуд'),
                            quoteLabel: text.tr('Запросить КП на все', 'Пешниҳод барои ҳама'),
                            onQuoteAll: () => showQuoteDialog(
                              context,
                              product: items.map((p) => '${p.brand} ${p.model}').join(', '),
                              language: controller.language,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final product = items[i];
                            return _Reveal(
                              key: ValueKey(product.id),
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
                          },
                          childCount: items.length,
                          findChildIndexCallback: (key) {
                            if (key is ValueKey) {
                              final index = items.indexWhere((p) => p.id == key.value);
                              return index < 0 ? null : index;
                            }
                            return null;
                          },
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: columns >= 3 ? .63 : .57,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final int count;
  final String unit;
  final String quoteLabel;
  final VoidCallback onQuoteAll;
  const _Header({required this.title, required this.count, required this.unit, required this.quoteLabel, required this.onQuoteAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: [MedikaColors.navy, MedikaColors.navy2], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _BeatingHeart(size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -.3)),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(end: count.toDouble()),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => Text(v.round().toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                        const SizedBox(width: 6),
                        Flexible(child: Text(unit, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFFD5E2F8)))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: FilledButton.icon(
              onPressed: onQuoteAll,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: MedikaColors.navy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
              label: Text(quoteLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Heart that beats twice, pauses, and repeats.
class _BeatingHeart extends StatefulWidget {
  final double size;
  const _BeatingHeart({required this.size});

  @override
  State<_BeatingHeart> createState() => _BeatingHeartState();
}

class _BeatingHeartState extends State<_BeatingHeart> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Two quick pulses in the first 45% of the cycle, rest is a pause.
  double _scale(double t) {
    double pulse(double x) => x < 0 || x > 1 ? 0 : math.sin(x * math.pi);
    return 1 + .16 * pulse(t / .2) + .1 * pulse((t - .22) / .2);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations && _c.isAnimating) _c.stop();
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        final ring = (t / .6).clamp(0.0, 1.0);
        return SizedBox(
          width: widget.size + 16,
          height: widget.size + 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size + 16 * ring,
                height: widget.size + 16 * ring,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF6B8A).withValues(alpha: .22 * (1 - ring))),
              ),
              Transform.scale(
                scale: _scale(t),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.size * .32),
                    gradient: const LinearGradient(colors: [Color(0xFFFF6B8A), Color(0xFFE5365A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: const Color(0xFFE5365A).withValues(alpha: .45), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Icon(Icons.favorite_rounded, color: Colors.white, size: widget.size * .5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onBrowse;
  const _EmptyFavorites({super.key, required this.title, required this.message, required this.actionLabel, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: _Reveal(
          offset: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _BeatingHeart(size: 84),
              const SizedBox(height: 18),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: MedikaColors.navy)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: MedikaColors.muted, height: 1.4)),
              ),
              if (onBrowse != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onBrowse,
                  icon: const Icon(Icons.grid_view_rounded, size: 18),
                  label: Text(actionLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fade + slide-up entrance with a small stagger.
class _Reveal extends StatefulWidget {
  final Widget child;
  final int index;
  final int stagger;
  final double offset;
  const _Reveal({super.key, required this.child, this.index = 0, this.stagger = 70, this.offset = 18});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 540));
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
        child: Transform.translate(offset: Offset(0, (1 - _a.value) * widget.offset), child: child),
      ),
    );
  }
}