import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../core/localization.dart';
import '../models/product.dart';
import 'product_image.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final AppController controller;
  final VoidCallback onOpen;
  final VoidCallback onQuote;

  const ProductCard({
    super.key,
    required this.product,
    required this.controller,
    required this.onOpen,
    required this.onQuote,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hover = false;
  bool _pressed = false;

  Product get product => widget.product;
  AppController get controller => widget.controller;

  Future<void> _toggleFavorite() async {
    HapticFeedback.lightImpact();
    // Block body on purpose: works whether toggleFavorite returns void, bool or a Future.
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

  @override
  Widget build(BuildContext context) {
    // If the controller is a ChangeNotifier, the card repaints itself when favorites/compare change.
    final Object ctrl = controller;
    if (ctrl is Listenable) {
      return ListenableBuilder(listenable: ctrl, builder: (context, _) => _card(context));
    }
    return _card(context);
  }

  Widget _card(BuildContext context) {
    final text = MedikaText(controller.language);
    final favorite = controller.favorites.contains(product.id);
    final comparing = controller.compare.contains(product.id);
    final inStock = product.stock == 'В наличии';
    final lifted = _hover && !_pressed;

    // Large system fonts can't break the layout.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: LayoutBuilder(
        builder: (context, box) {
          // Short cards (small phones) drop the optional lines instead of overflowing.
          final h = box.maxHeight.isFinite ? box.maxHeight : 400.0;
          final showDescription = h >= 290;
          final showPriceRow = h >= 245;

          return MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: AnimatedScale(
              scale: _pressed ? .97 : 1,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(0.0, lifted ? -4.0 : 0.0, 0.0),
                transformAlignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: comparing ? MedikaColors.blue : (lifted ? MedikaColors.blue.withValues(alpha: .4) : MedikaColors.line),
                    width: comparing ? 1.6 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: MedikaColors.navy.withValues(alpha: lifted ? .16 : .06),
                      blurRadius: lifted ? 26.0 : 12.0,
                      offset: Offset(0.0, lifted ? 12.0 : 4.0),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.onOpen,
                    onTapDown: (_) => setState(() => _pressed = true),
                    onTapUp: (_) => setState(() => _pressed = false),
                    onTapCancel: () => setState(() => _pressed = false),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [MedikaColors.softBlue, Colors.white],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  child: AnimatedScale(
                                    scale: _hover ? 1.07 : 1.0,
                                    duration: const Duration(milliseconds: 420),
                                    curve: Curves.easeOutCubic,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: ProductImage(product: product),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 9,
                                left: 9,
                                child: _StockBadge(
                                  inStock: inStock,
                                  label: inStock ? text.tr('В наличии', 'Дар анбор') : text.tr('Под заказ', 'Бо фармоиш'),
                                ),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: _HeartButton(active: favorite, onTap: _toggleFavorite),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${product.brand} · ${product.category}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF60739D), fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.model,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, height: 1.12, fontWeight: FontWeight.w900, color: MedikaColors.navy),
                              ),
                              if (showDescription) ...[
                                const SizedBox(height: 5),
                                Text(
                                  product.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, height: 1.35, color: MedikaColors.muted),
                                ),
                              ],
                              if (showPriceRow) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        text.priceRequest,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: MedikaColors.navy),
                                      ),
                                    ),
                                    AnimatedSlide(
                                      offset: Offset(_hover ? .15 : 0.0, 0.0),
                                      duration: const Duration(milliseconds: 220),
                                      child: const Icon(Icons.arrow_forward_rounded, size: 14, color: MedikaColors.blue),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 9),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: widget.onQuote,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(text.quote, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  _CompareButton(active: comparing, tooltip: text.compare, onTap: _toggleCompare),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final bool inStock;
  final String label;
  const _StockBadge({required this.inStock, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = inStock ? const Color(0xFF1E9E6A) : const Color(0xFFD98A12);
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: color, live: inStock),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

/// Small status dot; "in stock" gets a soft repeating ripple.
class _Dot extends StatefulWidget {
  final Color color;
  final bool live;
  const _Dot({required this.color, required this.live});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void initState() {
    super.initState();
    if (widget.live) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant _Dot old) {
    super.didUpdateWidget(old);
    if (widget.live && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.live) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            if (widget.live)
              Container(
                width: 6 + 6 * _c.value,
                height: 6 + 6 * _c.value,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: .35 * (1 - _c.value))),
              ),
            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color)),
          ],
        ),
      ),
    );
  }
}

/// Favorite heart that pops when toggled.
class _HeartButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _HeartButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .92)),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: Icon(
          active ? Icons.favorite : Icons.favorite_border,
          key: ValueKey(active),
          size: 19,
          color: active ? const Color(0xFFE5365A) : MedikaColors.navy,
        ),
      ),
    );
  }
}

/// Compare toggle: fills with brand blue and flips its arrows when active.
class _CompareButton extends StatelessWidget {
  final bool active;
  final String tooltip;
  final VoidCallback onTap;
  const _CompareButton({required this.active, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? MedikaColors.blue : MedikaColors.softBlue,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: MedikaColors.blue.withValues(alpha: active ? .35 : 0.0),
              blurRadius: active ? 10.0 : 0.0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        // Own Material so the tap ripple is drawn above the coloured background.
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Center(
              child: AnimatedRotation(
                turns: active ? .5 : 0.0,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                child: Icon(Icons.compare_arrows_rounded, size: 19, color: active ? Colors.white : MedikaColors.navy2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}