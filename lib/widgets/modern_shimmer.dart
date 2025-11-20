import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Modern Shimmer Skeleton Components
/// 
/// Inspired by Binance, TradingView, Coinbase
/// - Fast, minimal, production-ready
/// - Proper dark mode support
/// - Smooth animations

class ModernShimmer {
  // Light mode colors (like Binance/Coinbase)
  static const Color lightBase = Color(0xFFE0E0E0);
  static const Color lightHighlight = Color(0xFFF5F5F5);
  
  // Dark mode colors (like Binance dark theme)
  static const Color darkBase = Color(0xFF1E1E1E);
  static const Color darkHighlight = Color(0xFF2A2A2A);
  
  /// Get shimmer colors based on theme brightness
  static ShimmerColors getColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ShimmerColors(
      base: isDark ? darkBase : lightBase,
      highlight: isDark ? darkHighlight : lightHighlight,
    );
  }
}

class ShimmerColors {
  final Color base;
  final Color highlight;
  
  const ShimmerColors({required this.base, required this.highlight});
}

/// Product Card Shimmer Skeleton
class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = ModernShimmer.getColors(context);
    
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Image skeleton
                Shimmer.fromColors(
                  baseColor: colors.base,
                  highlightColor: colors.highlight,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.base,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Content skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Shimmer.fromColors(
                        baseColor: colors.base,
                        highlightColor: colors.highlight,
                        child: Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colors.base,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Shimmer.fromColors(
                        baseColor: colors.base,
                        highlightColor: colors.highlight,
                        child: Container(
                          height: 12,
                          width: 120,
                          decoration: BoxDecoration(
                            color: colors.base,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Price
                      Shimmer.fromColors(
                        baseColor: colors.base,
                        highlightColor: colors.highlight,
                        child: Container(
                          height: 16,
                          width: 80,
                          decoration: BoxDecoration(
                            color: colors.base,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Trailing icon
                Shimmer.fromColors(
                  baseColor: colors.base,
                  highlightColor: colors.highlight,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.base,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Warehouse List Shimmer Skeleton
class WarehouseListShimmer extends StatelessWidget {
  const WarehouseListShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = ModernShimmer.getColors(context);
    
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                // Icon skeleton
                Shimmer.fromColors(
                  baseColor: colors.base,
                  highlightColor: colors.highlight,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.base,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Text skeleton
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: colors.base,
                    highlightColor: colors.highlight,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: colors.base,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Count badge skeleton
                Shimmer.fromColors(
                  baseColor: colors.base,
                  highlightColor: colors.highlight,
                  child: Container(
                    width: 40,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.base,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Compact List Shimmer (for smaller sections)
class CompactListShimmer extends StatelessWidget {
  final int itemCount;
  
  const CompactListShimmer({
    Key? key,
    this.itemCount = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = ModernShimmer.getColors(context);
    
    return ListView.separated(
      padding: const EdgeInsets.all(12.0),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: colors.base,
          highlightColor: colors.highlight,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: colors.base,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}
