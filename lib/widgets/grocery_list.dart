import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'dart:convert';
import 'package:shopping_list/data/categories.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      'shopping-list-app-6e61b-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );
    final response = await http.get(url);
    if (response.body == 'null') {
      //prevent infinite loading if response is null
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category =
          categories.entries
              .firstWhere(
                (catItem) => catItem.value.title == item.value['category'],
              )
              .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
    });
  }

  void _addItem() async {
    final newItem = await Navigator.of(
      context,
    ).push<GroceryItem>(MaterialPageRoute(builder: (ctx) => const NewItem()));
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) {
    final url = Uri.https(
      'shopping-list-app-6e61b-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );
    http.delete(url);
    setState(() {
      _groceryItems.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text("No items added yet."));

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder:
            (ctx, index) => Dismissible(
              key: ValueKey(_groceryItems[index].id),
              direction: DismissDirection.horizontal,
              onDismissed: (direction) {
                var isUndo = false;
                final removedItem = _groceryItems[index];

                setState(() {
                  _groceryItems.remove(removedItem);
                });

                ScaffoldMessenger.of(ctx).clearSnackBars();
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('${removedItem.name} removed'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        setState(() {
                          isUndo = true;
                          _groceryItems.insert(index, removedItem);
                        });
                      },
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
                Future.delayed(const Duration(seconds: 4), () {
                  if (!isUndo && context.mounted) {
                    _removeItem(removedItem); // no await here
                  }
                });
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                child: const Row(
                  children: [
                    Icon(Icons.delete, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Remove', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              secondaryBackground: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.delete, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Remove', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              child: ListTile(
                title: Text(_groceryItems[index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: _groceryItems[index].category.color,
                ),
                trailing: Text(_groceryItems[index].quantity.toString()),
              ),
            ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
