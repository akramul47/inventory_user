import 'package:inventory_user/providers/product_provider.dart';
import 'package:inventory_user/utils/api_constants.dart';


class Product {
  final int id;
  final String warehouseId;
  final int categoryId;
  final int brandId;
  final String name;
  final String uniqueCode;
  final String barcode;
  final double retailPrice;
  final double salePrice;
  final bool isSold;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? description;
  final int quantity;
  final String imageUrl;
  final String warehouseTag;
  final List<String> imageUrls;
  final List<ProductImage> images;

  Product({
    required this.id,
    required this.warehouseId,
    required this.categoryId,
    required this.brandId,
    required this.name,
    required this.uniqueCode,
    required this.barcode,
    required this.retailPrice,
    required this.salePrice,
    required this.isSold,
    required this.createdAt,
    required this.quantity,
    required this.imageUrl,
    required this.warehouseTag,
    required this.imageUrls,
    this.updatedAt,
    this.description,
    required this.images,
  });

  List<ProductImage> get productImages => images;
  
  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['product_images'] != null) {
      images = List<String>.from(json['product_images'].map(
          (imageJson) => '${ApiConstants.BASE_URL_WITHOUT_API}/${imageJson['image'] ?? ''}'));
    }

    return Product(
      id: int.parse(json['id'].toString()), // Handle null value for id
      warehouseId: json['warehouse_id'] != null
          ? json['warehouse_id'].toString()
          : '', // Handle null value for warehouse_id
      categoryId: int.parse(
          json['category_id'].toString()), // Parse categoryId to integer
      brandId: int.parse(json['brand_id'].toString()),
      name: json['product_name'] ?? '',
      uniqueCode: json['unique_code'] ?? '',
      barcode: json['scan_code'] ?? '',
      retailPrice: double.tryParse(json['product_retail_price'] ?? '') ?? 0.0,
      salePrice: double.tryParse(json['product_sale_price'] ?? '') ?? 0.0,
      isSold: json['is_sold'] == '1',
      createdAt: DateTime.parse(json['created_at'] ?? ''),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      description:
          json['description'] ?? '', // Handle null value for description
      quantity: json['quantity'] ?? 0,
      imageUrl: json['product_images'] != null &&
              json['product_images'].isNotEmpty &&
              json['product_images'][0]['image'] != null
          ? '${ApiConstants.BASE_URL_WITHOUT_API}/${json['product_images'][0]['image']}'
          : '', // Handle null value for imageUrl
      warehouseTag:
          json['warehouse'] != null && json['warehouse']['name'] != null
              ? json['warehouse']['name'].toString()
              : '', // Handle null value for warehouseTag
      imageUrls: images,
      images: (json['product_images'] as List)
          .map((imageJson) => ProductImage.fromJson(imageJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'warehouse_id': warehouseId,
      'category_id': categoryId,
      'brand_id': brandId,
      'product_name': name,
      'unique_code': uniqueCode,
      'scan_code': barcode,
      'product_retail_price': retailPrice.toString(),
      'product_sale_price': salePrice.toString(),
      'is_sold': isSold ? '1' : '0',
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'description': description,
      'quantity': quantity.toString(),
      'image_url': imageUrl,
      'warehouse_tag': warehouseTag,
      'images': imageUrls,
    };
  }
}

class Category {
  final int id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['category_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_name': name,
    };
  }
}

class Warehouse {
  final int id;
  final String name;

  Warehouse({
    required this.id,
    required this.name,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Brand {
  final int id;
  final String name;

  Brand({
    required this.id,
    required this.name,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] ?? 0,
      name: json['brand_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand_name': name,
    };
  }
}

class ProductImage {
  final int id;
  final String productId;
  final String image;

  ProductImage({
    required this.id,
    required this.productId,
    required this.image,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: int.parse(json['id'].toString()), // Parse ID to integer
      productId: json['product_id'].toString(),
      image: json['image'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'image': image,
    };
  }
}
