// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_django_client_library/main.dart';
import '../lib/Product.dart';
import '../lib/Brand.dart';
import 'package:http/http.dart' as http;

void main() {
  setUp(() async {
    await HttpDriverImpl().clear();
  });

  tearDown(() async {
    await HttpDriverImpl().clear();
  });

  test('test refresh', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.create({"barcode": "product 1"});
    var uri = Uri.http("localhost:8000", "product/1");
    // var headers = {'content-type': 'application/json; charset=UTF-8'};
    var data = {"barcode": "product 2"};
    await http.patch(uri, body: data);
    expect(om.updated.barcode, "product 1");
    await om.refresh();
    expect(om.updated.barcode, "product 2");
  });

  test('test refresh without updates', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.create({"barcode": "product 1"});
    await om.refresh();
    expect(om.updated.barcode, "product 1");
  });
  
  test ('test save', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.create({"barcode": "product 1"});
    om.updated.barcode = "osu!";
    ObjectManager<Product> om1 = await cm.get({"barcode": "product 1"});
    expect(om1.updated.barcode, "product 1");
    await om.save();
    try {
      om1 = await cm.get({"barcode": "product 1"});
    } catch (error) {
      expect(error.toString(), ".get() must receive exactly 1 object, but got 0");
    }
    om1 = await cm.get({"barcode": "osu!"});
    expect(om1.updated.id, 1);
  });

  test ('test update', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.create({"barcode": "product 1"});
    await om.update({"barcode": "osu!"});
    expect(om.updated.barcode, "osu!");
    ObjectManager<Product> om1 = await cm.get({"barcode": "osu!"});
    expect(om1.updated.id, 1);
  });

  test ('test update to empty', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.create({"barcode": "product 1"});
    await om.update({"barcode": ""});
    expect(om.updated.barcode, '');
    ObjectManager<Product> om1 = await cm.get({"id": 1});
    expect(om1.updated.barcode, '');
  });

  test ('test update to null', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.create({"barcode": "product 1"});
    await om.update({"barcode": null});
    expect(om.updated.barcode, null);
    ObjectManager<Product> om1 = await cm.get({"id": 1});
    expect(om1.updated.barcode, null);
  });

  
  test ('test update bad key', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.create({"barcode": "product 1"});
    await om.update({"barcodeafaf": "osu!"});
    expect(om.updated.barcode, "product 1");
    ObjectManager<Product> om1 = await cm.get({"barcode": "product 1"});
    expect(om1.updated.id, 1);
  });

  test('test delete', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.create({ "barcode": "product 1" });
    await om.delete();
    try {
      await cm.get({"barcode": "product 1"});
      fail('should not have got here');
    } catch (error) {
      expect(error.toString(), ".get() must receive exactly 1 object, but got 0");
    }
  });

  test ('test modify using properties to blank and null', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.create({ "barcode": "product 1" });
    om.updated.barcode = '';
    await om.save();
    ObjectManager<Product> find = await cm.get({"id": 1});
    expect(find.updated.barcode, '');
    om.updated.barcode = null;
    await om.save();
    find = await cm.get({"id": 1});
    expect(find.updated.barcode, null);
  });


  test ('test modify properties', () async {
    CollectionManager<Brand> cm = CollectionManager(() => new Brand());
    ObjectManager<Brand> om = await cm.create({ "name": "nike" });
    om.updated.name = "adidas";
    await om.save();
    ObjectManager<Brand> om1 = await cm.get({"id": 1});
    expect(om1.updated.name, "adidas");
  });


  test ('test modify foreign key', () async {
    CollectionManager<Product> pcm = CollectionManager(() => new Product());
    ObjectManager<Product> pom = await pcm.create({ "barcode": "product 1" });

    CollectionManager<Brand> bcm = CollectionManager(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({ "name": "nike" });

    pom.updated.brand_id = 1;
    await pom.save();

    ObjectManager<Product> pom2 = await pcm.get({"brand_id": 1});
    expect(pom2.updated.barcode, "product 1");
  });

  test ('test constructor pass in object', () async {
    CollectionManager<Product> pcm = CollectionManager(() => new Product());
    for (int i = 0; i < 3; i++) {
      await pcm.create({"barcode": "pen ${i+1}"});
    }

    PageResult<Product> ppr = await pcm.page({'query': {'id__in': [1, 2, 3]}});
    ObjectManager<Product> objm = ObjectManager<Product>(ppr.objects[0]);
    expect(objm.updated.barcode, "pen 1");
    expect(objm.updated.id, 1);
    expect(objm.updated.brand_id, null);
  });
}
