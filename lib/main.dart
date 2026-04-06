import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Product Manager',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6C63FF),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  final CollectionReference _products =
      FirebaseFirestore.instance.collection('products');

  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  bool _showFilters = false;

  
  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _nameController.text = documentSnapshot['name'];
      _priceController.text = documentSnapshot['price'].toString();
    }

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action == 'create' ? 'Add New Product' : 'Update Product',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    action == 'create' ? 'Create' : 'Update',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  onPressed: () async {
                    String name = _nameController.text.trim();
                    String priceText = _priceController.text.trim();
                    if (name.isNotEmpty && priceText.isNotEmpty) {
                      double price = double.parse(priceText);
                      if (action == 'create') {
                        await _products
                            .add({"name": name, "price": price});
                      }
                      if (action == 'update') {
                        await _products
                            .doc(documentSnapshot!.id)
                            .update({"name": name, "price": price});
                      }
                      _nameController.text = '';
                      _priceController.text = '';
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  
  Future<void> _deleteProduct(String productId) async {
    await _products.doc(productId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have successfully deleted a product'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  
  Stream<QuerySnapshot> _getProductsStream() {
    return _products.snapshots();
  }

  // filter logic
  List<DocumentSnapshot> _filterDocs(List<DocumentSnapshot> docs) {
    return docs.where((doc) {
      final name = (doc['name'] as String).toLowerCase();
      final price = (doc['price'] as num).toDouble();

      // Search filter
      if (_searchQuery.isNotEmpty &&
          !name.contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // Min price filter
      if (_minPrice != null && price < _minPrice!) {
        return false;
      }

      // Max price filter
      if (_maxPrice != null && price > _maxPrice!) {
        return false;
      }

      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _minPrice = null;
      _maxPrice = null;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Manager'),
        actions: [
          IconButton(
            icon: Icon(_showFilters
                ? Icons.filter_list_off
                : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Price filter section
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💰 Price Filter',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _minPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Min',
                                prefixText: '\$ ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _minPrice = double.tryParse(value);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _maxPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Max',
                                prefixText: '\$ ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _maxPrice = double.tryParse(value);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.refresh,
                                color: Colors.redAccent),
                            tooltip: 'Reset filters',
                            onPressed: _resetFilters,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Product list
          Expanded(
            child: StreamBuilder(
              stream: _getProductsStream(),
              builder:
                  (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.hasError) {
                  return Center(
                    child: Text('Error: ${streamSnapshot.error}'),
                  );
                }

                if (streamSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (streamSnapshot.hasData) {
                  final filteredDocs =
                      _filterDocs(streamSnapshot.data!.docs);

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'No products found',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot documentSnapshot =
                          filteredDocs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shopping_bag,
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                          title: Text(
                            documentSnapshot['name'],
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '\$${documentSnapshot['price'].toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          trailing: SizedBox(
                            width: 100,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blueGrey),
                                  onPressed: () =>
                                      _createOrUpdate(documentSnapshot),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () => _deleteProduct(
                                      documentSnapshot.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
