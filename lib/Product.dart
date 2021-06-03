import 'package:dart_django_client_library/main.dart';
import './Brand.dart';

class Product extends Model {

  Product.fromProperties(Map<String, Object?> properties) {
    this.properties = new Map<String, Object?>.from(properties);
  }

  Product();

  String? get barcode {
    return properties['barcode'] as String?;
  }

  set barcode(String? x) {
    properties['barcode'] = x;
  }

  int? get brand_id {
    return properties['brand_id'] as int?;
  }

  set brand_id(int? x) {
    properties['brand_id'] = x;
  }

  

  RelatedObjectManager<Brand, Product> get brand {
    return new RelatedObjectManager<Brand, Product>(() => new Brand(), this, "brand");
  }

  @override
  Model clone() {
    return new Product.fromProperties(this.properties);
  }

  @override
  Model fromJson(dynamic object) {
    Map<String, dynamic> map = object.map;
    map.forEach((key, val) => {
      this.properties[key] = val
    });
    return this;
  }

  int? get id {
    return properties['id'] as int?;
  }
}