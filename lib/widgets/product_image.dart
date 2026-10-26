import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/product.dart';

class ProductImage extends StatelessWidget {
  final Product product;
  final BoxFit fit;
  const ProductImage({super.key, required this.product, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    if (product.image.trim().isEmpty) return _fallback();
    return CachedNetworkImage(
      imageUrl: product.image,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: (_, __) => const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => Container(
    alignment: Alignment.center,
    color: const Color(0xFFF7F9FC),
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.medical_services_outlined, color: MedikaColors.blue, size: 34),
        SizedBox(height: 5),
        Text('MEDIKA', style: TextStyle(fontWeight: FontWeight.w900, color: MedikaColors.navy)),
      ],
    ),
  );
}
