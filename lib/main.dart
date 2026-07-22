import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/scanner_screen.dart';
import 'models/inventory_item.dart';
import 'services/storage_service.dart';
import 'services/export_service.dart';
import 'providers/settings_provider.dart';
import 'l10n/app_translations.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: AppTranslations.get(settings.languageCode, 'appTitle'),
      debugShowCheckedModeBanner: false,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
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
  List<String> _suppliers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _storageService.getItems();
    final suppliers = await _storageService.getSuppliers();
    setState(() {
      _items = items;
      _suppliers = suppliers;
      _isLoading = false;
    });
  }

  Future<void> _saveItems() async {
    await _storageService.saveItems(_items);
  }

  Future<void> _saveSuppliers() async {
    await _storageService.saveSuppliers(_suppliers);
  }

  String t(String key) {
    return AppTranslations.get(
      Provider.of<SettingsProvider>(context, listen: false).languageCode, 
      key
    );
  }

  void _manageSuppliersDialog() {
    final supplierController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(t('manageSuppliers')),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: supplierController,
                            decoration: InputDecoration(
                              labelText: t('newSupplier'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF6C63FF), size: 36),
                          onPressed: () {
                            if (supplierController.text.trim().isNotEmpty) {
                              setState(() {
                                _suppliers.add(supplierController.text.trim());
                                _saveSuppliers();
                              });
                              setStateDialog(() {});
                              supplierController.clear();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _suppliers.isEmpty 
                      ? Text(t('noSupplier'))
                      : Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _suppliers.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(_suppliers[index]),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _suppliers.removeAt(index);
                                      _saveSuppliers();
                                    });
                                    setStateDialog(() {});
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(t('close')),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _handleScanResult(String barcode, bool isAdding) {
    setState(() {
      final existingIndex = _items.indexWhere(
        (item) => item.barcode == barcode,
      );

      if (existingIndex >= 0) {
        if (isAdding) {
          _items[existingIndex].quantity++;
        } else {
          if (_items[existingIndex].quantity > 1) {
            _items[existingIndex].quantity--;
          } else {
            _items.removeAt(existingIndex);
          }
        }
      } else {
        if (isAdding) {
          _items.add(
            InventoryItem(
              barcode: barcode,
              name: t('productName'),
              quantity: 1,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t('productNotFound')),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    });
    _saveItems();
  }

  void _showManualEntryDialog({InventoryItem? item}) {
    final formKey = GlobalKey<FormState>();
    final barcodeController = TextEditingController(text: item?.barcode);
    final nameController = TextEditingController(text: item?.name);
    final quantityController = TextEditingController(
      text: item?.quantity.toString() ?? '1',
    );
    String? selectedSupplier = item?.supplier;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(item == null ? t('addProduct') : t('editProduct')),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: barcodeController,
                decoration: InputDecoration(
                  labelText: t('barcodeNo'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.qr_code),
                ),
                readOnly:
                    item != null, // Barkod düzenleme modunda değiştirilemesin
                validator: (val) =>
                    val == null || val.isEmpty ? t('requiredField') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: t('productName'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.inventory_2),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? t('requiredField') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: t('quantity'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return t('requiredField');
                  if (int.tryParse(val) == null)
                    return t('invalidNumber');
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _suppliers.contains(selectedSupplier) ? selectedSupplier : null,
                decoration: InputDecoration(
                  labelText: t('supplier'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.local_shipping),
                ),
                items: _suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  selectedSupplier = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  if (item == null) {
                    final existingIndex = _items.indexWhere(
                      (i) => i.barcode == barcodeController.text.trim(),
                    );
                    if (existingIndex >= 0) {
                      _items[existingIndex].quantity += int.parse(
                        quantityController.text,
                      );
                      _items[existingIndex].name = nameController.text.trim();
                      _items[existingIndex].supplier = selectedSupplier;
                    } else {
                      _items.add(
                        InventoryItem(
                          barcode: barcodeController.text.trim(),
                          name: nameController.text.trim(),
                          quantity: int.parse(quantityController.text),
                          supplier: selectedSupplier,
                        ),
                      );
                    }
                  } else {
                    item.name = nameController.text.trim();
                    item.quantity = int.parse(quantityController.text);
                    item.supplier = selectedSupplier;
                  }
                });
                _saveItems();
                Navigator.of(ctx).pop();
              }
            },
            child: Text(t('save'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                t('howToAdd'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Provider.of<SettingsProvider>(context, listen: false).isDarkMode ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Color(0xFF6C63FF),
                ),
              ),
              title: Text(
                t('scanWithCamera'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _openScanner(isAdding: true);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.keyboard, color: Color(0xFF6C63FF)),
              ),
              title: Text(
                t('enterManually'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _showManualEntryDialog();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
          content: Text(isAdding ? '${t('added')}: $scannedCode' : '${t('removed')}: $scannedCode'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          t('appTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark 
            ? Colors.black.withValues(alpha: 0.8) 
            : Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: false,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Color(0xFF6C63FF)),
            tooltip: t('changeLanguage'),
            onSelected: (String code) {
              settings.setLanguage(code);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'tr',
                child: Text('🇹🇷 Türkçe'),
              ),
              const PopupMenuItem<String>(
                value: 'en',
                child: Text('🇬🇧 English'),
              ),
              const PopupMenuItem<String>(
                value: 'it',
                child: Text('🇮🇹 Italiano'),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: const Color(0xFF6C63FF),
            ),
            tooltip: t('changeTheme'),
            onPressed: () => settings.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.local_shipping, color: Color(0xFF6C63FF)),
            tooltip: t('manageSuppliers'),
            onPressed: _manageSuppliersDialog,
          ),
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(
                  Icons.download_rounded,
                  color: Color(0xFF6C63FF),
                ),
                tooltip: t('exportToExcel'),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t('excelPreparing')),
                    ),
                  );
                  try {
                    await ExportService.exportAndShare(_items, settings.languageCode);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(t('exportError')),
                      ),
                    );
                  }
                },
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                : [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        size: 100,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        t('inventoryEmpty'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t('useFabToAdd'),
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () => _showManualEntryDialog(item: item),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.qr_code_rounded,
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          '${item.barcode} ${item.supplier != null ? '• ${item.supplier}' : ''}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'x${item.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'btn_remove',
            onPressed: () => _openScanner(isAdding: false),
            backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
            elevation: 4,
            child: const Icon(
              Icons.remove_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'btn_add',
            onPressed: _showAddOptions,
            backgroundColor: const Color(0xFF6C63FF),
            elevation: 6,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              t('addProduct'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
