import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class BluetoothPrinterService {
  // Mengecek apakah bluetooth aktif dan izin diberikan
  static Future<bool> checkBluetoothStatus() async {
    try {
      final bool isBluetoothGranted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
      final bool isBluetoothEnabled = await PrintBluetoothThermal.bluetoothEnabled;
      return isBluetoothGranted && isBluetoothEnabled;
    } catch (e) {
      print('Error checking bluetooth status: $e');
      return false;
    }
  }

  // Mendapatkan daftar printer bluetooth yang dipasangkan (paired)
  static Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      final List<BluetoothInfo> pairedDevices = await PrintBluetoothThermal.pairedBluetooths;
      return pairedDevices;
    } catch (e) {
      print('Error getting paired devices: $e');
      return [];
    }
  }

  // Menghubungkan ke printer menggunakan MAC Address
  static Future<bool> connectPrinter(String macAddress) async {
    try {
      final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      return result;
    } catch (e) {
      print('Error connecting to printer: $e');
      return false;
    }
  }

  // Mengecek apakah sudah terhubung ke printer
  static Future<bool> isConnected() async {
    try {
      final bool status = await PrintBluetoothThermal.connectionStatus;
      return status;
    } catch (e) {
      return false;
    }
  }

  // Memutuskan koneksi printer
  static Future<void> disconnectPrinter() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  // Mencetak struk transaksi penjualan
  static Future<bool> printReceipt({
    required String storeName,
    required String storeAddress,
    required String noNota,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    double payment = 0.0,
    double change = 0.0,
    double diskon = 0.0,
    double pajak = 0.0,
  }) async {
    try {
      final bool connected = await isConnected();
      if (!connected) {
        throw Exception('Printer tidak terhubung. Hubungkan terlebih dahulu.');
      }

      // Memuat profil kapabilitas printer (standar esc/pos)
      final profile = await CapabilityProfile.load();
      // Menggunakan lebar kertas thermal standar 58mm
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // Header Toko
      bytes += generator.text(
        storeName,
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
      );
      bytes += generator.text(storeAddress, styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      // Info Transaksi
      bytes += generator.text('No. Nota : $noNota', styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text('Tanggal  : ${DateTime.now().toString().substring(0, 19)}', styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      // Daftar Item
      for (var item in items) {
        final String nama = item['nama'] ?? '';
        final int qty = (item['jumlah'] ?? 0).toInt();
        final int harga = (item['harga'] ?? 0).toInt();
        final int subtotal = qty * harga;

        // Cetak nama barang
        bytes += generator.text(nama, styles: const PosStyles(bold: true));
        // Cetak kuantitas dan harga (contoh: 2 x 10.000       20.000)
        final String qtyHarga = '$qty x Rp $harga';
        final String sub = 'Rp $subtotal';
        final int spaces = 32 - qtyHarga.length - sub.length;
        final String spacesStr = spaces > 0 ? ' ' * spaces : ' ';
        bytes += generator.text('$qtyHarga$spacesStr$sub');
      }

      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      // Breakdown section
      if (diskon > 0) {
        final String diskonLabel = 'Diskon:';
        final String diskonStr = '-Rp ${diskon.toInt()}';
        final int dSpaces = 32 - diskonLabel.length - diskonStr.length;
        bytes += generator.text('$diskonLabel${" " * (dSpaces > 0 ? dSpaces : 1)}$diskonStr');
      }
      
      if (pajak > 0) {
        final String pajakLabel = 'Pajak PPN:';
        final String pajakStr = '+Rp ${pajak.toInt()}';
        final int pSpaces = 32 - pajakLabel.length - pajakStr.length;
        bytes += generator.text('$pajakLabel${" " * (pSpaces > 0 ? pSpaces : 1)}$pajakStr');
      }

      // Ringkasan Pembayaran
      final String totalLabel = 'Total Belanja:';
      final String totalStr = 'Rp ${totalPrice.toInt()}';
      final int tSpaces = 32 - totalLabel.length - totalStr.length;
      bytes += generator.text('$totalLabel${" " * (tSpaces > 0 ? tSpaces : 1)}$totalStr', styles: const PosStyles(bold: true));

      if (payment > 0) {
        final String bayarLabel = 'Bayar:';
        final String bayarStr = 'Rp ${payment.toInt()}';
        final int bSpaces = 32 - bayarLabel.length - bayarStr.length;
        bytes += generator.text('$bayarLabel${" " * (bSpaces > 0 ? bSpaces : 1)}$bayarStr');

        final String kembaliLabel = 'Kembali:';
        final String kembaliStr = 'Rp ${change.toInt()}';
        final int kSpaces = 32 - kembaliLabel.length - kembaliStr.length;
        bytes += generator.text('$kembaliLabel${" " * (kSpaces > 0 ? kSpaces : 1)}$kembaliStr');
      }

      bytes += generator.feed(2); // Spasi kosong di akhir
      bytes += generator.cut(); // Potong kertas (jika didukung)

      // Mengirim byte ke printer thermal bluetooth
      final bool result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      print('Print failed error: $e');
      return false;
    }
  }
}
