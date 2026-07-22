import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/inventory_item.dart';

class ExportService {
  static Future<void> exportAndShare(List<InventoryItem> items) async {
    var excel = Excel.createExcel();
    // Yeni bir sayfa oluştur ve onu varsayılan yap
    Sheet sheetObject = excel['Envanter'];
    excel.setDefaultSheet('Envanter');
    
    // Başlıklar
    sheetObject.appendRow([
      const TextCellValue('Barkod'),
      const TextCellValue('Ürün Adı'),
      const TextCellValue('Miktar'),
    ]);
    
    // Veriler
    for (var item in items) {
      sheetObject.appendRow([
        TextCellValue(item.barcode),
        TextCellValue(item.name),
        IntCellValue(item.quantity),
      ]);
    }
    
    // Dosyayı geçici klasöre kaydet
    final directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/envanter_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final File file = File(filePath);
      await file.writeAsBytes(fileBytes);
      
      // Dosyayı paylaş
      await Share.shareXFiles([XFile(filePath)], text: 'Güncel Envanter Listesi');
    }
  }
}
