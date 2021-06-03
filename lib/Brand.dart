import 'package:dart_django_client_library/main.dart';
import './Product.dart';

class Brand extends Model {
  Brand.fromProperties(Map<String, Object?> properties) {
    this.properties = new Map<String, Object?>.from(properties);
  }

  Brand();

  int? get id {
    return this.properties['id'] as int?;
  }

  RelatedCollectionManager<Product, Brand> get products {
    return new RelatedCollectionManager(() => new Product(), this, "products");
  }

  set name(String? name) {
    this.properties['name'] = name;
  }

  String? get name {
    return this.properties['name'] as String?;
  }

  @override
  Model clone() {
    return new Brand.fromProperties(this.properties);
  }

  @override
  Model fromJson(dynamic object) {
    Map<String, dynamic> map = object.map;
    map.forEach((key, val) => {
      this.properties[key] = val
    });
    return this;
  }
  
}