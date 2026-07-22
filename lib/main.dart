import 'package:flutter/material.dart';
import 'screens/scanner_screen.dart';
import 'models/inventory_item.dart';
import 'services/storage_service.dart';
import 'services/export_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Envanter Tarayıcı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StorageService _storageService = StorageService();
  List<InventoryItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _storageService.getItems();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _saveItems() async {
    await _storageService.saveItems(_items);
  }

  void _handleScanResult(String barcode, bool isAdding) {
    setState(() {
      final existingIndex = _items.indexWhere((item) => item.barcode == barcode);
      
      if (existingIndex >= 0) {
        // İtem zaten var, miktarını güncelle
        if (isAdding) {
          _items[existingIndex].quantity++;
        } else {
          if (_items[existingIndex].quantity > 1) {
            _items[existingIndex].quantity--;
          } else {
            // Miktar 1 ise ve azaltıldıysa tamamen sil
            _items.removeAt(existingIndex);
          }
        }
      } else if (isAdding) {
        // İtem yok ve ekleme yapılıyor
        _items.add(InventoryItem(barcode: barcode, name: 'Yeni Ürün ($barcode)'));
      } else {
        // İtem yok ama çıkarma yapılmak isteniyor (Hata veya uyarı verilebilir)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu ürün envanterde bulunamadı!')),
        );
        return;
      }
    });
    
    _saveItems();
  }

  Future<void> _openScanner({required bool isAdding}) async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );
    
    if (scannedCode != null && context.mounted) {
      _handleScanResult(scannedCode, isAdding);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAdding ? 'Eklendi: $scannedCode' : 'Çıkarıldı: $scannedCode'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envanter Paneli'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: "Excel'e Aktar",
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Excel dosyası hazırlanıyor...')),
                );
                try {
                  await ExportService.exportAndShare(_items);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dışa aktarılırken hata oluştu.')),
                  );
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Envanter şu an boş.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.qr_code)),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Barkod: ${item.barcode}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'x${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton
            .extended(
            heroTag: 'btn_remove',
            onPressed: () => _openScanner(isAdding: false),
            backgroundColor: Colors.redAccent,
            icon: const Icon(Icons.remove, color: Colors.white),
            label: const Text('Ürün Çıkart', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'btn_add',
            onPressed: () => _openScanner(isAdding: true),
            backgroundColor: Colors.green,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Ürün Ekle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
