// All tests in the package
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_django_client_library/main.dart';
import '../lib/Product.dart';
import '../lib/Brand.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  setUp(() async {
    await HttpDriverImpl().clear();
  });

  tearDown(() async {
    await HttpDriverImpl().clear();
  });

  // COLLECTION MANAGER TESTS
  test('test get object none should fail', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    try {
      ObjectManager<Product> om = await cm.get({"id__in": [1]});
      fail("shouldn't have reached here");
    } catch (error) {
      expect(error.toString(), '.get() must receive exactly 1 object, but got 0');
    }
  });


  test('test get object one should pass', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    await cm.create({"barcode": "hello"});
    ObjectManager<Product> om = await cm.get({"barcode": "hello"});
    expect(om.updated!.barcode, 'hello');
    expect(om.updated!.id, 1);
  });

  test('test get object more than one should fail', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    await cm.create({"barcode": "hello"});
    await cm.create({"barcode": "hello"});
    try {
      await cm.get({"id__in": [1]});
    } catch (error) {
      expect(error.toString(), '.get() must receive exactly 1 object, but got 2');
    }
  });

  test('test get object with array params', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    await cm.create({"barcode": "osu"});
    await cm.create({"barcode": "goodbye"});
    ObjectManager<Product> om = await cm.get({"barcode__in": ["hello", "goodbye"]});
    expect(om.updated!.barcode, 'goodbye');
    expect(om.updated!.id, 2);
  });

  test('test get object with params', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    await cm.create({"barcode": "osu"});
    ObjectManager<Product> om = await cm.get({"barcode__exact": "osu"});
    expect(om.updated!.barcode, 'osu');
    expect(om.updated!.id, 1);
  });

  test ('test page default', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    PageResult<Product> pr = await cm.page({});
    expect(pr.limit, 50);
    expect(pr.total, 0);
    expect(pr.page, 1);
  });

  test ('test page default with products', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 51; i++) {
      await cm.create({"barcode": "product ${i+1}"});
    }

    PageResult<Product> pr = await cm.page({});
    expect(pr.limit, 50);
    expect(pr.total, 51);
    expect(pr.page, 1);
  });

  test ('test page search by null', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 10; i++) {
      if (i < 8) await cm.create({"barcode": null});
      else await cm.create({"barcode": "sup"});
    }

    PageResult<Product> pr = await cm.page({ 'query': { 'barcode': null } });
    expect(pr.limit, 50);
    expect(pr.total, 8);
    expect(pr.page, 1);
    expect(pr.objects[0].id, 1);
  });

  test ('test page page 1', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 51; i++) {
      await cm.create({"barcode": "product ${i+1}"});
    }

    PageResult<Product> pr = await cm.page({});
    expect(pr.limit, 50);
    expect(pr.total, 51);
    expect(pr.page, 1);
    expect(pr.objects.length, 50);
    expect(pr.objects[0].id, 1);
    expect(pr.objects[0].barcode, "product 1");
    expect(pr.objects[49].id, 50);
    expect(pr.objects[49].barcode, "product 50");
  });

  test ('test page page 2', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 51; i++) {
      await cm.create({"barcode": "product ${i+1}"});
    }

    PageResult<Product> pr = await cm.page({"page": {"page": 2}});
    expect(pr.limit, 50);
    expect(pr.total, 51);
    expect(pr.page, 2);
    expect(pr.objects.length, 1);
    expect(pr.objects[0].id, 51);
    expect(pr.objects[0].barcode, "product 51");
  });

  test ('test page page and limit', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 15; i++) {
      await cm.create({"barcode": "product ${i+1}"});
    }

    PageResult<Product> pr = await cm.page({"page": {"page": 2, "limit": 5}});
    expect(pr.limit, 5);
    expect(pr.page, 2);
    expect(pr.total, 15);
    expect(pr.objects.length, 5);
    expect(pr.objects[0].id, 6);
    expect(pr.objects[0].barcode, "product 6");
  });


  test ('test page limit no page', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 10; i++) {
      await cm.create({"barcode": "product ${i+1}"});
    }

    PageResult<Product> pr = await cm.page({"page": {"limit": 5}});
    expect(pr.limit, 5);
    expect(pr.page, 1);
    expect(pr.total, 10);
    expect(pr.objects.length, 5);
    expect(pr.objects[0].id, 1);
    expect(pr.objects[0].barcode, "product 1");
  });

  test ('test page query', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 10; i++) {
      await cm.create({"barcode": "product ${i+1}"});
    }

    PageResult<Product> pr = await cm.page({"query": {"barcode__in": ["product 1", "product 3", "product 5"]}});
    expect(pr.limit, 50);
    expect(pr.page, 1);
    expect(pr.total, 3);
    expect(pr.objects.length, 3);
    expect(pr.objects[1].id, 3);
    expect(pr.objects[1].barcode, "product 3");
  });


  test ('test page query with page', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 10; i++) {
      await cm.create({"barcode": "product ${i+1}"});
    }

    PageResult<Product> pr = await cm.page({"query": {"id__in": [3, 5], "barcode__in": ["product 1", "product 3", "product 5"] }, "page": {"limit": 1, "page": 2}} );
    expect(pr.limit, 1);
    expect(pr.page, 2);
    expect(pr.total, 2);
    expect(pr.objects.length, 1);
    expect(pr.objects[0].id, 5);
    expect(pr.objects[0].barcode, "product 5");
  });


test ('test page query with page', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 10; i++) {
      await cm.create({"barcode": "product ${i+1}"});
    }

    PageResult<Product> pr = await cm.page({"query": {"id__in": [3, 5], "barcode__in": ["product 1", "product 3", "product 5"] }, "page": {"limit": 1, "page": 2}} );
    expect(pr.limit, 1);
    expect(pr.page, 2);
    expect(pr.total, 2);
    expect(pr.objects.length, 1);
    expect(pr.objects[0].id, 5);
    expect(pr.objects[0].barcode, "product 5");
  });


test ('test page query order by', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 10; i++) {
      await cm.create({"barcode": "shoe ${i+1}"});
    }

    PageResult<Product> pr = await cm.page({"query": {"barcode__in": ["shoe 1", "shoe 3", "shoe 5"] }, "page": {"order_by": "-barcode"}} );
    expect(pr.limit, 50);
    expect(pr.page, 1);
    expect(pr.total, 3);
    expect(pr.objects.length, 3);
    expect(pr.objects[0].id, 5);
    expect(pr.objects[0].barcode, "shoe 5");
    expect(pr.objects[2].id, 1);
    expect(pr.objects[2].barcode, "shoe 1");
  });


test ('test page query order by ver 2', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 10; i++) {
      await cm.create({"barcode": "product ${i+1}"});
    }

    await cm.create({"barcode": "product 4"});

    PageResult<Product> pr = await cm.page({"query": {"barcode__in": ["product 1", "product 4", "product 5"] }, "page": {"order_by": "-barcode,-id"}} );
    expect(pr.limit, 50);
    expect(pr.page, 1);
    expect(pr.total, 4);
    expect(pr.objects.length, 4);
    expect(pr.objects[0].id, 5);
    expect(pr.objects[0].barcode, "product 5");
    expect(pr.objects[1].id, 11);
    expect(pr.objects[1].barcode, "product 4");
    expect(pr.objects[2].id, 4);
    expect(pr.objects[2].barcode, "product 4");
  });


  test ('test page typo', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    for (int i = 0; i < 10; i++) {
      await cm.create({"barcode": "product ${i+1}"});
    }
    try {
      PageResult<Product> pr = await cm.page({"query": {"barcode___in": ["product 1", "product 4", "product 5"] }, "page": {"order_by": "-barcode,-id"}} );
    } catch (error) {
      expect(error.toString(), 'Server did not return objects. Response: {"non_field_error": "Unsupported lookup \'_in\' for CharField or join on the field not permitted, perhaps you meant in?"}');
    }
  });



  test('test create object', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.create({"barcode": "hello"});
    expect(om.updated!.barcode, "hello");
  });


  test('test create object with null key', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.create({"barcode": null});
    expect(om.updated.barcode, null);
    expect(om.updated.id, 1);
  });


  test('test create object with null key should fail ', () async {
    CollectionManager<Brand> cm = CollectionManager(() => new Brand());
    ObjectManager<Brand> om = await cm.create({"name": null});
    expect(om.updated.name, 'This field may not be null.');
    expect(om.updated.id, null);

    om = await cm.create({"name": ''});
    expect(om.updated.name, '');
    expect(om.updated.id, 1);
  });


  test('test create object with invalid key', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.create({"barasdfcode": "hello"});
    expect(om.updated.barcode, null);
  });

  test('test create object with invalid key v2', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.create({"barcode": "hello", "goodbye": "osu"});
    expect(om.updated.barcode, null);
    expect(om.updated.id, null);
  });


  test('test get or create', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.get_or_create({"query": {"barcode": "product 1"}, "defaults": {"brand_id": null} });
    expect(om.updated!.barcode, "product 1");
    expect(om.updated!.id, 1);
  });

  test('test get or create v2', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.get_or_create({"query": {"barcode": "product 1"}});
    expect(om.updated!.barcode, "product 1");
    expect(om.updated!.id, 1);
  });

  test('test get or create v3', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    await cm.create({"barcode": "product 1"});
    await cm.create({"barcode": "product 2"});
    ObjectManager<Product> om = await cm.get_or_create({"query": {"barcode": "product 2"}, "defaults": {"brand_id": null}});
    expect(om.updated!.barcode, "product 2");
    expect(om.updated!.id, 2);
  });

  test('test update or create', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    ObjectManager<Product> om = await cm.update_or_create({"query": {"barcode": "product 2"}, "defaults": {"barcode": "product 3"}});
    expect(om.updated!.barcode, "product 2");
    expect(om.updated!.id, 1);
  });


  test('test update or create v2', () async {
    CollectionManager<Product> cm = CollectionManager(() => new Product());
    await cm.create({"barcode": "product 2"});
    ObjectManager<Product> om = await cm.update_or_create({"query": {"barcode": "product 2"}, "defaults": {"barcode": "product 3"}});
    expect(om.updated!.barcode, "product 3");
    expect(om.updated!.id, 1);
  });




  // OBJECT MANAGER TESTS
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


  // RELATED COLLECTION MANAGER TESTS

  test ('test page empty', () async {
    CollectionManager<Brand> cm = new CollectionManager(() => new Brand());
    ObjectManager<Brand> om = await cm.create({"name": "nike"});
    var products = await om.updated.products.page({
      "query": {
        "barcode": "product 1"
      }
    });
    expect(products.limit, 50);
    expect(products.page, 1);
    expect(products.total, 0);
    expect(products.objects.length, 0);
  });


  test ('test page with results', () async {
    CollectionManager<Brand> cmb = new CollectionManager(() => new Brand());
    CollectionManager<Product> cmp = new CollectionManager(() => new Product());
    ObjectManager<Brand> om = await cmb.create({"name": "nike"});
    
    List<Product> lst = [];
    for (int i = 0; i < 10; i++) {
      ObjectManager<Product> p = await cmp.create({"barcode": "product ${i+1}"});
      lst.add(p.updated);
    }

    await om.updated.products.add(lst);

    var products = await om.updated.products.page({
      "query": {
        "barcode__in": ["product 1", "product 5", "product 10"]
      }
    });
    expect(products.limit, 50);
    expect(products.page, 1);
    expect(products.total, 3);
    expect(products.objects.length, 3);
    expect(products.objects[0].barcode, "product 1");
  });

  test ('test page with results and pagination', () async {
    CollectionManager<Brand> cmb = new CollectionManager(() => new Brand());
    CollectionManager<Product> cmp = new CollectionManager(() => new Product());
    ObjectManager<Brand> om = await cmb.create({"name": "nike"});
    
    List<Product> lst = [];
    for (int i = 0; i < 10; i++) {
      ObjectManager<Product> p = await cmp.create({"barcode": "product ${i+1}"});
      lst.add(p.updated);
    }

    await om.updated.products.add(lst);

    var products = await om.updated.products.page({
      "page": {
        "limit": 5,
        "page": 2,
        "order_by": "-barcode"
      }
    });
    expect(products.limit, 5);
    expect(products.page, 2);
    expect(products.total, 10);
    expect(products.objects.length, 5);
    expect(products.objects[0].barcode, "product 4");
  });

  
  test ('test get with no result', () async {
    CollectionManager<Brand> cmb = new CollectionManager(() => new Brand());
    ObjectManager<Brand> om = await cmb.create({"name": "nike"});
    try {
      await om.updated.products.get({});
      fail("shouldn't have got here");
    } catch (error) {
      expect(error.toString(), ".get() must receive exactly 1 object, but got 0");
    }
  });

  test ('test get with one result', () async {
    CollectionManager<Brand> bcm = new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({ "name": "nike" });

    CollectionManager<Product> pcm = new CollectionManager<Product>(() => new Product());
    for (int i = 0; i < 10; i++) {
      await pcm.create({ "barcode": "shoe ${i+1}"});
    }

    // posting objects to relation
    Uri uri = Uri.http("localhost:8000", "/brand/1/products");
    var data = jsonEncode([5]);
    await http.post(uri, body: data, headers: {'content-type': 'application/json'});

    ObjectManager<Product> related_product = await bom.updated.products.get({});
    expect(related_product.updated.id, 5);
    expect(related_product.updated.barcode, "shoe 5");
  });


  test ('test get with multiple results', () async {
    CollectionManager<Brand> bcm = new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({ "name": "nike" });

    CollectionManager<Product> pcm = new CollectionManager<Product>(() => new Product());
    for (int i = 0; i < 10; i++) {
      await pcm.create({ "barcode": "shoe ${i+1}"});
    }

    // posting objects to relation
    Uri uri = Uri.http("localhost:8000", "/brand/1/products");
    var data = jsonEncode([5, 6]);
    await http.post(uri, body: data, headers: {'content-type': 'application/json'});
    try {
      ObjectManager<Product> related_product = await bom.updated.products.get({});
      fail("shouldn't have got here");
    } catch (error) {
      expect(error.toString(), ".get() must receive exactly 1 object, but got 2");
    }
  });


  test ('test add ids', () async {
    CollectionManager<Product> pcm = new CollectionManager<Product>(() => new Product());
    CollectionManager<Brand> bcm = new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({ "name": "nike" });
    for (int i = 0; i < 10; i++) await pcm.create({ "barcode": "sneaker ${i+1}"});

    await bom.updated.products.add_ids([2, 4, 6, 8]);
    var product_lst = await bom.updated.products.page({});
    expect(product_lst.total, 4);
    expect(product_lst.objects.length, 4);
    expect(product_lst.objects[3].barcode, "sneaker 8");
  });


  test ('test add ids some invalid', () async {
    CollectionManager<Brand> bcm = new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({ "name": "nike" });
    CollectionManager<Product> pcm = new CollectionManager<Product>(() => new Product());
    for (int i = 0; i < 10; i++) await pcm.create({ "barcode": "sneaker ${i+1}"});

    bom.updated.products.add_ids([10, 15]);
    PageResult<Product> pr = await bom.updated.products.page({});
    expect(pr.total, 0);
    expect(pr.objects.length, 0);
  });


  test ('test set ids', () async {
    CollectionManager<Brand> bcm = new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({ "name": "nike" });
    CollectionManager<Product> pcm = new CollectionManager<Product>(() => new Product());
    for (int i = 0; i < 10; i++) await pcm.create({ "barcode": "sneaker ${i+1}"});

    await bom.updated.products.add_ids([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    PageResult<Product> pr = await bom.updated.products.page({});
    expect(pr.total, 10);
    expect(pr.objects.length, 10);
    expect(pr.objects[9].barcode, "sneaker 10");

    await bom.updated.products.set_ids([7]);
    PageResult<Product> pr1 = await bom.updated.products.page({});
    expect(pr1.total, 1);
    expect(pr1.objects.length, 1);
    expect(pr1.objects[0].barcode, "sneaker 7");
  });

  test ('test set ids to empty', () async {
    CollectionManager<Brand> bcm = new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({ "name": "nike" });
    CollectionManager<Product> pcm = new CollectionManager<Product>(() => new Product());
    for (int i = 0; i < 10; i++) await pcm.create({ "barcode": "sneaker ${i+1}"});

    await bom.updated.products.add_ids([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    PageResult<Product> pr = await bom.updated.products.page({});
    expect(pr.total, 10);
    expect(pr.objects.length, 10);
    expect(pr.objects[9].barcode, "sneaker 10");

    await bom.updated.products.set_ids([]);
    PageResult<Product> pr1 = await bom.updated.products.page({});
    expect(pr1.total, 0);
    expect(pr1.objects.length, 0);
  });

  
  test ('test set ids to invalid', () async {
    CollectionManager<Brand> bcm = new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({ "name": "nike" });
    CollectionManager<Product> pcm = new CollectionManager<Product>(() => new Product());
    for (int i = 0; i < 10; i++) await pcm.create({ "barcode": "sneaker ${i+1}"});

    await bom.updated.products.add_ids([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    PageResult<Product> pr = await bom.updated.products.page({});
    expect(pr.total, 10);
    expect(pr.objects.length, 10);
    expect(pr.objects[9].barcode, "sneaker 10");

    await bom.updated.products.set_ids([8, 7, 10, 30]);
    PageResult<Product> pr1 = await bom.updated.products.page({});
    expect(pr1.total, 10);
    expect(pr1.objects.length, 10);
  });

  test ('test remove ids', () async {
    CollectionManager<Brand> bcm = new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({ "name": "nike" });
    CollectionManager<Product> pcm = new CollectionManager<Product>(() => new Product());
    for (int i = 0; i < 10; i++) await pcm.create({ "barcode": "sneaker ${i+1}"});

    await bom.updated.products.add_ids([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

    await bom.updated.products.remove_ids([1, 3, 5, 7, 9]);
    PageResult<Product> pr1 = await bom.updated.products.page({});
    expect(pr1.total, 5);
    expect(pr1.objects.length, 5);
    expect(pr1.objects[0].barcode, "sneaker 2");
  });


  // TODO: do something about this test lol
  // test ('test remove ids invalid', () async {
  //   CollectionManager<Brand> bcm = new CollectionManager<Brand>(() => new Brand());
  //   ObjectManager<Brand> bom = await bcm.create({ "name": "nike" });
  //   CollectionManager<Product> pcm = new CollectionManager<Product>(() => new Product());
  //   for (int i = 0; i < 10; i++) await pcm.create({ "barcode": "sneaker ${i+1}"});

  //   await bom.updated.products.add_ids([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

  //   await bom.updated.products.remove_ids([3, 11]);
  //   PageResult<Product> pr1 = await bom.updated.products.page({});
  //   expect(pr1.total, 10);
  //   expect(pr1.objects.length, 10);
  //   expect(pr1.objects[9].barcode, "sneaker 10");
  // });


  test ('test add objs', () async {
    CollectionManager<Brand> bcm = new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({ "name": "nike" });
    CollectionManager<Product> pcm = new CollectionManager<Product>(() => new Product());
    List<Product> lst1 = [];
    List<Product> lst2 = [];
    for (int i = 0; i < 10; i++) {
      ObjectManager<Product> prod = await pcm.create({ "barcode": "sneaker ${i+1}"});
      if (i < 5) {
        lst1.add(prod.updated);
      } else lst2.add(prod.updated);
    }

    await bom.updated.products.add(lst1);
    PageResult<Product> related = await bom.updated.products.page({});
    expect(5, related.total);
    expect("sneaker 5", related.objects[4].barcode);
    
    await bom.updated.products.add(lst2);
    related = await bom.updated.products.page({});
    expect(10, related.total);
    expect("sneaker 10", related.objects[9].barcode);
  });


  test ('test set objs', () async {
    CollectionManager<Brand> bcm = new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({ "name": "nike" });
    CollectionManager<Product> pcm = new CollectionManager<Product>(() => new Product());
    List<Product> lst1 = [];
    List<Product> lst2 = [];
    for (int i = 0; i < 10; i++) {
      ObjectManager<Product> prod = await pcm.create({ "barcode": "sneaker ${i+1}"});
      if (i <= 8) {
        lst1.add(prod.updated);
      } else lst2.add(prod.updated);
    }

    await bom.updated.products.set(lst1);
    PageResult<Product> related = await bom.updated.products.page({});
    expect(9, related.total);
    expect("sneaker 9", related.objects[8].barcode);

    await bom.updated.products.set(lst2);
    related = await bom.updated.products.page({});
    expect(1, related.total);
    expect("sneaker 10", related.objects[0].barcode);
  });

  test ('test remove objs', () async {
    CollectionManager<Brand> bcm = new CollectionManager<Brand>(() => new Brand());
    ObjectManager<Brand> bom = await bcm.create({ "name": "nike" });
    CollectionManager<Product> pcm = new CollectionManager<Product>(() => new Product());
    List<Product> lst1 = [];
    List<Product> lst2 = [];
    List<Product> lst3 = [];
    for (int i = 0; i < 10; i++) {
      ObjectManager<Product> prod = await pcm.create({ "barcode": "sneaker ${i+1}"});
      if (i <= 8) {
        lst1.add(prod.updated);
      } else lst2.add(prod.updated);
      lst3.add(prod.updated);
    }

    await bom.updated.products.set(lst3);
    
    await bom.updated.products.remove(lst2);
    PageResult<Product> related = await bom.updated.products.page({});
    expect(9, related.total);
    expect("sneaker 9", related.objects[8].barcode);

    await bom.updated.products.remove(lst1);
    related = await bom.updated.products.page({});
    expect(0, related.total);
  });
  

  // RELATED OBJECT MANAGER TESTS
    test('test set brand', () async {
    CollectionManager<Brand> cm = new CollectionManager(() => new Brand());
    ObjectManager<Brand> om = await cm.create({"name": "nike"});
    CollectionManager<Product> pcm = new CollectionManager(() => new Product());
    ObjectManager<Product> pom = await pcm.create({"barcode": "zoomfly v1"});
    await pom.updated.brand.set(om.updated);
    
    ObjectManager<Product> refreshed = await pcm.get({"brand_id": 1});
    expect(refreshed.updated.barcode, "zoomfly v1");
  });

  test('test get brand', () async {
    CollectionManager<Brand> cm = new CollectionManager(() => new Brand());
    ObjectManager<Brand> om = await cm.create({"name": "nike"});
    CollectionManager<Product> pcm = new CollectionManager(() => new Product());
    ObjectManager<Product> pom = await pcm.create({"barcode": "zoomfly v1"});
    
    ObjectManager<Brand> temp = await pom.updated.brand.get();
    expect(null, temp.updated.id);

    await pom.updated.brand.set(om.updated);
    temp = await pom.updated.brand.get();
    expect("nike", temp.updated.name);
  });
}
