import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory_item.dart';

class StorageService {
  static const String _key = 'inventory_data';

  Future<List<InventoryItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? data = prefs.getStringList(_key);
    
    if (data == null) {
      return [];
    }
    
    return data.map((e) => InventoryItem.fromJson(e)).toList();
  }

  Future<void> saveItems(List<InventoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> data = items.map((e) => e.toJson()).toList();
    await prefs.setStringList(_key, data);
  }
}
