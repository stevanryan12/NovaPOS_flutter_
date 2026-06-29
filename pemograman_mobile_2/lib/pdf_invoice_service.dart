import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfInvoiceService {
  static Future<void> generateAndShareInvoice({
    required String storeName,
    required String storeAddress,
    required String noNota,
    required String paymentMethod, // 'CASH' or 'QRIS'
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    double payment = 0.0,
    double change = 0.0,
    double diskon = 0.0,
    double pajak = 0.0,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll57, // Tampilan struk thermal gulung 58mm
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Toko
              pw.Center(
                child: pw.Text(
                  storeName,
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  storeAddress,
                  style: const pw.TextStyle(fontSize: 6),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Divider(thickness: 0.5),

              // Detail Transaksi
              pw.Text('No. Nota : $noNota', style: const pw.TextStyle(fontSize: 6)),
              pw.Text('Tanggal  : ${DateTime.now().toString().substring(0, 16)}', style: const pw.TextStyle(fontSize: 6)),
              pw.Text('Metode   : ${paymentMethod == 'QRIS' ? 'QRIS (E-Wallet)' : 'Tunai (Cash)'}', style: const pw.TextStyle(fontSize: 6)),
              pw.Divider(thickness: 0.5),

              // List Barang
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Item', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Total', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(thickness: 0.3),

              // Detail Item
              ...items.map((item) {
                final String nama = item['nama'] ?? '';
                final int qty = (item['jumlah'] ?? 0).toInt();
                final int harga = (item['harga'] ?? 0).toInt();
                final int subtotal = qty * harga;

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(nama, style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('$qty x Rp $harga', style: const pw.TextStyle(fontSize: 5.5)),
                          pw.Text('Rp $subtotal', style: const pw.TextStyle(fontSize: 6)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),

              pw.Divider(thickness: 0.5),

              // Breakdown section
              if (diskon > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('DISKON:', style: const pw.TextStyle(fontSize: 6)),
                    pw.Text('- Rp ${diskon.toInt()}', style: const pw.TextStyle(fontSize: 6)),
                  ],
                ),
              ],
              if (pajak > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('PAJAK:', style: const pw.TextStyle(fontSize: 6)),
                    pw.Text('+ Rp ${pajak.toInt()}', style: const pw.TextStyle(fontSize: 6)),
                  ],
                ),
              ],

              // Rincian Pembayaran
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rp ${totalPrice.toInt()}', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                ],
              ),

              if (paymentMethod == 'CASH') ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('BAYAR:', style: const pw.TextStyle(fontSize: 6)),
                    pw.Text('Rp ${payment.toInt()}', style: const pw.TextStyle(fontSize: 6)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('KEMBALI:', style: const pw.TextStyle(fontSize: 6)),
                    pw.Text('Rp ${change.toInt()}', style: const pw.TextStyle(fontSize: 6)),
                  ],
                ),
              ],

              pw.Divider(thickness: 0.5),
              pw.Center(
                child: pw.Text(
                  'Terima Kasih atas Kunjungan Anda',
                  style: pw.TextStyle(fontSize: 5.5, fontStyle: pw.FontStyle.italic),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Dapatkan path folder sementara di sistem
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/nota_$noNota.pdf');
    
    // Tulis data PDF ke file
    await file.writeAsBytes(await pdf.save());

    // Share/Simpan file PDF menggunakan share_plus
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Struk Belanja $noNota',
      text: 'Nota Struk Transaksi dari Kasir POS',
    );
  }
}
