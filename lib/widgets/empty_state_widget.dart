import 'package:flutter/material.dart';
import 'package:inventory_user/utils/pallete.dart';

/// Beautiful Empty State Widget
/// 
/// Shows when there's no data or an error occurred
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const EmptyStateWidget({
    Key? key,
    required this.title,
    required this.message,
    this.icon = Icons.inventory_2_outlined,
    this.onRetry,
    this.retryButtonText = 'Retry',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon Container
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Pallete.primaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 60,
                  color: Pallete.primaryRed,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Message
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              
              // Retry Button
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryButtonText ?? 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Pallete.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// No Products Empty State
class NoProductsEmptyState extends StatelessWidget {
  final VoidCallback? onAddProduct;
  
  const NoProductsEmptyState({
    Key? key,
    this.onAddProduct,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Products Yet',
      message: 'Start building your inventory by adding your first product. Use the + button below to get started!',
      icon: Icons.inventory_2_outlined,
      onRetry: onAddProduct,
      retryButtonText: 'Add Product',
    );
  }
}

/// Error State Widget
class ErrorStateWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? errorMessage;
  
  const ErrorStateWidget({
    Key? key,
    this.onRetry,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Oops! Something went wrong',
      message: errorMessage ?? 'We couldn\'t load your inventory. Please check your connection and try again.',
      icon: Icons.error_outline,
      onRetry: onRetry,
      retryButtonText: 'Try Again',
    );
  }
}

/// Loading Failed State (for when data fetch fails)
class LoadingFailedState extends StatelessWidget {
  final VoidCallback onRetry;
  
  const LoadingFailedState({
    Key? key,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Connection Issue',
      message: 'Unable to connect to the server. Please check your internet connection and try again.',
      icon: Icons.cloud_off_outlined,
      onRetry: onRetry,
      retryButtonText: 'Retry',
    );
  }
}
