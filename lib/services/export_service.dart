import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/inventory_item.dart';
import '../l10n/app_translations.dart';

class ExportService {
  static Future<void> exportAndShare(List<InventoryItem> items, String langCode) async {
    var excel = Excel.createExcel();
    
    Sheet sheetObject = excel[AppTranslations.get(langCode, 'appTitle')];
    excel.setDefaultSheet(AppTranslations.get(langCode, 'appTitle'));
    
    sheetObject.appendRow([
      TextCellValue(AppTranslations.get(langCode, 'barcodeNo')),
      TextCellValue(AppTranslations.get(langCode, 'productName')),
      TextCellValue(AppTranslations.get(langCode, 'quantity')),
      TextCellValue(AppTranslations.get(langCode, 'supplier')),
    ]);
    
    for (var item in items) {
      sheetObject.appendRow([
        TextCellValue(item.barcode),
        TextCellValue(item.name),
        IntCellValue(item.quantity),
        TextCellValue(item.supplier ?? '-'),
      ]);
    }
    
    final directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/envanter_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final File file = File(filePath);
      await file.writeAsBytes(fileBytes);
      
      await Share.shareXFiles([XFile(filePath)], text: AppTranslations.get(langCode, 'appTitle'));
    }
  }
}
