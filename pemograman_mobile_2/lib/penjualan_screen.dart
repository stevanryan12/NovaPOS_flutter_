import 'package:flutter/material.dart';
import 'package:pemograman_mobile_2/app_theme.dart';
import 'package:pemograman_mobile_2/penjualan_controller.dart';
import 'package:pemograman_mobile_2/barang_controller.dart';
import 'package:pemograman_mobile_2/bluetooth_printer_service.dart';
import 'package:pemograman_mobile_2/pdf_invoice_service.dart';
import 'package:pemograman_mobile_2/pelanggan_controller.dart';

class PenjualanScreen extends StatefulWidget {
  @override
  _PenjualanScreenState createState() => _PenjualanScreenState();
}

class _PenjualanScreenState extends State<PenjualanScreen> {
  final PenjualanController barangController = PenjualanController();
  final BarangController catalogController = BarangController();
  final PelangganController pelangganController = PelangganController();
  
  final Map<String, Map<String, dynamic>> scannedItems = {};
  int totalItems = 0;
  double subtotalPrice = 0.0;
  double discount = 0.0;
  double taxPercent = 0.0;
  double taxAmount = 0.0;
  double totalPrice = 0.0;
  bool redeemPoints = false;
  double pointsDiscount = 0.0;
  double promoDiscount = 0.0;

  final TextEditingController searchController = TextEditingController();
  
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<String> categories = ['Semua'];
  String selectedCategory = 'Semua';
  bool isCatalogLoading = true;
  String searchQuery = '';

  List<Map<String, dynamic>> allPelanggan = [];
  Map<String, dynamic>? selectedPelanggan;

  @override
  void initState() {
    super.initState();
    fetchCatalogData();
    fetchPelangganData();
  }

  Future<void> fetchPelangganData() async {
    try {
      final data = await pelangganController.fetchPelanggan();
      setState(() {
        allPelanggan = data;
      });
    } catch (e) {
      print('Error fetching pelanggan: $e');
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchCatalogData() async {
    try {
      final products = await catalogController.fetchBarang();
      final cats = await catalogController.fetchCategories();
      setState(() {
        allProducts = products;
        filteredProducts = products;
        categories = ['Semua', ...cats.toSet().toList()];
        isCatalogLoading = false;
      });
    } catch (e) {
      setState(() {
        isCatalogLoading = false;
      });
      print('Error loading catalog: $e');
    }
  }

  void filterCatalog() {
    setState(() {
      filteredProducts = allProducts.where((p) {
        final matchesCategory = selectedCategory == 'Semua' || p['kategori'] == selectedCategory;
        final name = (p['nama'] ?? '').toString().toLowerCase();
        final barcode = (p['no_barcode'] ?? '').toString().toLowerCase();
        final matchesSearch = name.contains(searchQuery.toLowerCase()) || barcode.contains(searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void addItem(String barcode) async {
    try {
      final product = allProducts.firstWhere(
        (p) => p['no_barcode'].toString() == barcode,
        orElse: () => {},
      );

      if (product.isNotEmpty) {
        setState(() {
          if (scannedItems.containsKey(barcode)) {
            scannedItems[barcode]!['jumlah']++;
          } else {
            scannedItems[barcode] = {
              "nama": product['nama'],
              "harga": product['harga'],
              "no_barcode": product['no_barcode'],
              "jumlah": 1,
            };
          }
          calculateTotals();
        });
      } else {
        final productDb = await barangController.fetchProductByBarcode(barcode);
        if (productDb != null) {
          setState(() {
            if (scannedItems.containsKey(barcode)) {
              scannedItems[barcode]!['jumlah']++;
            } else {
              scannedItems[barcode] = {
                "nama": productDb['nama'],
                "harga": productDb['harga'],
                "no_barcode": productDb['no_barcode'],
                "jumlah": 1,
              };
            }
            calculateTotals();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Barang dengan barcode $barcode tidak ditemukan!'),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void removeItem(String barcode) {
    if (scannedItems.containsKey(barcode)) {
      setState(() {
        if (scannedItems[barcode]!['jumlah'] > 1) {
          scannedItems[barcode]!['jumlah']--;
        } else {
          scannedItems.remove(barcode);
        }
        if (scannedItems.isEmpty) {
          selectedPelanggan = null;
        }
        calculateTotals();
      });
    }
  }

  void calculateTotals() {
    totalItems = 0;
    subtotalPrice = 0.0;
    double tempGrosirDiscount = 0.0;

    scannedItems.forEach((barcode, item) {
      int jumlah = item['jumlah'] ?? 0;
      int harga = item['harga'] ?? 0;
      totalItems += jumlah;
      double itemSubtotal = (jumlah * harga).toDouble();
      
      // Promo Grosir: diskon 10% jika jumlah barang >= 5
      if (jumlah >= 5) {
        tempGrosirDiscount += itemSubtotal * 0.10;
      }
      
      subtotalPrice += itemSubtotal;
    });

    // Promo Belanja: diskon 5% jika belanja bersih >= Rp 100.000
    double currentSubtotal = subtotalPrice - tempGrosirDiscount;
    double tempMinBelanjaDiscount = 0.0;
    if (currentSubtotal >= 100000) {
      tempMinBelanjaDiscount = currentSubtotal * 0.05;
    }

    promoDiscount = tempGrosirDiscount + tempMinBelanjaDiscount;

    // Diskon Member: otomatis 10% jika ada pelanggan terpilih
    if (selectedPelanggan != null) {
      double currentNet = subtotalPrice - discount - promoDiscount;
      if (currentNet < 0) currentNet = 0;
      pointsDiscount = currentNet * 0.10; // Diskon 10% member
    } else {
      pointsDiscount = 0.0;
    }

    double afterDiscount = subtotalPrice - discount - promoDiscount - pointsDiscount;
    if (afterDiscount < 0) afterDiscount = 0;
    
    taxAmount = afterDiscount * (taxPercent / 100);
    totalPrice = afterDiscount + taxAmount;
  }

  void showDiscountTaxDialog() {
    final TextEditingController discountController = TextEditingController(text: discount > 0 ? discount.toInt().toString() : '');
    final TextEditingController taxController = TextEditingController(text: taxPercent > 0 ? taxPercent.toInt().toString() : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Atur Diskon & Pajak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: AppTheme.formInputDecoration(label: 'Diskon (Rp)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: taxController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: AppTheme.formInputDecoration(label: 'Pajak / PPN (%)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: AppTheme.primaryButton,
              onPressed: () {
                setState(() {
                  discount = double.tryParse(discountController.text) ?? 0.0;
                  taxPercent = double.tryParse(taxController.text) ?? 0.0;
                  calculateTotals();
                });
                Navigator.pop(context);
                Navigator.pop(context); // Close bottom sheet
                showCartBottomSheet(); // Re-open to refresh
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      }
    );
  }

  String getProductImageUrl(String productName, String categoryName) {
    final name = productName.toLowerCase();
    final cat = categoryName.toLowerCase();
    
    // 1. Specific Indonesian Brand Product Mappings
    if (name.contains('pucuk') || name.contains('teh pucuk')) {
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQR6qvDK4qdrtRXl75ksyZTfQErcdmdgb2r6FuSUb8cUw&s=10';
    }
    if (name.contains('aoka')) {
      return 'https://s3.belanjapasti.com/media/image/aoka-roti-panggang-coklat-pck-65g-593343.png';
    }
    if (name.contains('bear brand')) {
      return 'https://image.astronauts.cloud/product-images/2024/2/bearbrandnew_ad870f43-609c-4bdc-a4d4-8e01fb663db1_900x900.png';
    }
    if (name.contains('taro seaweed') || (name.contains('taro') && name.contains('chiki'))) {
      return 'https://image.astronauts.cloud/product-images/2024/4/TaroSeaweed62gr1_3c3d0505-08a4-4405-a525-5bbfd5bf20b9_809x900.jpeg';
    }
    if (name.contains('kapal api mix') || (name.contains('kapal api') && name.contains('mix'))) {
      return 'https://image.astronauts.cloud/product-images/2024/8/kpaalapispecialmix_74f43640-69b4-4423-9a80-d3e6236a7771_900x900.jpg';
    }
    if (name.contains('lifebuoy')) {
      return 'https://image.astronauts.cloud/product-images/2024/10/816874LifebuoyTSTotal10SabunBatangisi4110gram1_5635e581-133d-4202-b280-b97514da67f1_900x900.png';
    }
    if (name.contains('clear men') || (name.contains('clear') && name.contains('shamp'))) {
      return 'https://image.astronauts.cloud/product-images/2024/10/8999999529710ClearShampooCoolSportMentolMen160ml1_d119a008-19b0-4122-86c4-64e19c6c57fd_900x900.png';
    }
    if (name.contains('pepsodent')) {
      return 'https://image.astronauts.cloud/product-images/2024/10/8999999706180PepsodentPencegahGigiBerlubangPastaGigi190gram1_297980cb-21fd-4014-97cb-796adadb1c30_900x900.png';
    }
    if (name.contains('sikat gigi formula') || (name.contains('formula') && name.contains('sikat'))) {
      return 'https://image.astronauts.cloud/product-images/2024/4/FormulaSikatGigiTrendyPack3pcs1_4a911a68-782c-4a24-982b-b19e7ff5ed83_900x900.jpg';
    }
    if (name.contains('rinso')) {
      return 'https://image.astronauts.cloud/product-images/2025/10/8999999401238_d88e73e9-22e0-4daf-807f-c6cec653bceb_900x900.jpg';
    }
    if (name.contains('sunlight') || name.contains('cuci piring') || name.contains('dish soap') || name.contains('dishwash')) {
      return 'https://image.astronauts.cloud/product-images/2025/4/8999999008475new_4989a990-ae78-487c-bc95-4dd3d68a844c_900x900.jpg';
    }
    if (name.contains('hit spray') || name.contains('obat nyamuk hit') || (name.contains('hit') && name.contains('nyamuk'))) {
      return 'https://image.astronauts.cloud/product-images/2024/4/HitAerosolOrange600mlPembasmiSerangga1_30a56f8a-08ca-42cc-b078-0aa4c0e3e4f9_900x900.png';
    }

    if (name.contains('coca-cola') || name.contains('coca cola') || name.contains('coke')) {
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT5aO0ZisJR84Afd5rkYqa4t0gqnlFol4aXLsDZmwzHYg&s=10';
    }
    if (name.contains('pocari')) {
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQeJPNE-fYVm0WS7Nu1kK_D3gAyjAoXdhHiEycZl2BR1w&s=10';
    }
    if (name.contains('giv')) {
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRLdBqcm9adsQz9taeDMjOCnGnArWejNpV0ucECaLQEmA&s=10';
    }
    if (name.contains('lux')) {
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQNhy6WxNh5BRIC-IHwoKx0QVlYa60UbC5s_VP-73-POg&s=10';
    }
    if (name.contains('dettol')) {
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQtlnJLqrpjkdkJAa2qdIg3vyvUragXUzDonhpKdpUerg&s=10';
    }
    if (name.contains('qtela')) {
      return 'https://yoline.co.id/media/products/ProductQtelasingkongrasabbq185gr.jpeg';
    }
    if (name.contains('chitato')) {
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSauSt7ivoJ_WHD0vvEztr-pnuW_j2UR0XxVz46xC8JLw&s=10';
    }
    if (name.contains('kusuka')) {
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSvw9Q4hsmxzwJ1GcwjDrcLxAIDcf1P99zaXk5lHq6FQA&s=10';
    }
    if (name.contains('silverqueen') || name.contains('silver queen')) {
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ8EZCGxgPdhliV4VMIYooO5DeC1oGLiWiIXFjOpGUKHA&s=10';
    }
    if (name.contains('cadbury')) {
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTQtxLCbFtDG_gECQ5osuwoeX5ZER91Kbtthr8uC4qWNQ&s=10';
    }
    if (name.contains('beng-beng') || name.contains('beng beng')) {
      return 'https://filebroker-cdn.lazada.co.id/kf/Sc65c7e78404b43d3aca770ae4610591bw.jpg';
    }
    if (name.contains('kitkat') || name.contains('kit kat')) {
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQxx1wuxAVVjYFDnlC5v4byOk6cZZRbksm7rpXRPachVA&s=10';
    }
    if (name.contains('chocolatos')) {
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTM-DNHd3BC0-nuOOY2TA1gR_WcYYSgkDfktdFDCEg1Nw&s=10';
    }

    // 2. Indomie & Mie instan (goreng vs kuah/soto/ayam bawang)
    if (name.contains('mie') || name.contains('noodle') || name.contains('ramen') || name.contains('indomie') || name.contains('sedaap') || name.contains('sarimi')) {
      if (name.contains('soto')) {
        return 'https://image.astronauts.cloud/product-images/2024/4/IndomieSotoMieMieinstan1_f7f60cab-94e1-4874-afac-59e4a95717cc_700x700.png';
      } else if (name.contains('ayam bawang') || name.contains('bawang')) {
        return 'https://image.astronauts.cloud/product-images/2024/3/indomiekuahayambawang_b40b0b7f-2057-40ba-a9cb-085dd90692a3_700x700.png';
      } else if (name.contains('goreng')) {
        return 'https://image.astronauts.cloud/product-images/2024/4/IndomieGorengSpesialMieinstan1_19ed38d5-421f-4813-bd66-25cf83f1909c_900x900.png';
      } else if (name.contains('kuah') || name.contains('rebus') || name.contains('kari') || name.contains('kaldu') || name.contains('sup') || name.contains('soup') || name.contains('baso')) {
        return 'https://image.astronauts.cloud/product-images/2024/3/indomiekuahayambawang_b40b0b7f-2057-40ba-a9cb-085dd90692a3_700x700.png';
      } else {
        return 'https://image.astronauts.cloud/product-images/2024/4/IndomieGorengSpesialMieinstan1_19ed38d5-421f-4813-bd66-25cf83f1909c_900x900.png';
      }
    }
    
    // 3. Aqua & Le Minerale
    if (name.contains('aqua')) {
      return 'https://image.astronauts.cloud/product-images/2026/2/324_25d70935-4663-455a-9ccf-1560c9d0a327_900x900.jpg';
    } else if (name.contains('le minerale') || name.contains('minerale')) {
      return 'https://images.tokopedia.net/img/cache/700/VeeMRq/2022/8/16/be1f09d5-7cfa-465f-ac2c-0e86b24df4d4.jpg';
    }
    
    // 4. Sembako / Dapur
    if (name.contains('telur') || name.contains('egg') || name.contains('telor')) {
      return 'https://images.tokopedia.net/img/cache/700/VeeMRq/2021/3/30/80ee3eb0-22c6-4767-83cb-1ee6ea1d2fbf.jpg';
    } else if (name.contains('beras') || name.contains('rice') || name.contains('nasi')) {
      return 'https://images.tokopedia.net/img/cache/700/OALsub/2023/10/18/d30b9ee2-df66-41fb-9cf6-00ea7cdbb2ef.jpg';
    } else if (name.contains('minyak') || name.contains('oil') || name.contains('bimoli') || name.contains('filma') || name.contains('sania') || name.contains('fortune')) {
      return 'https://images.tokopedia.net/img/cache/700/OALsub/2023/5/12/32d0f576-8802-466d-9657-3ce942d99d14.jpg';
    } else if (name.contains('gula') || name.contains('sugar') || name.contains('gulaku')) {
      return 'https://images.tokopedia.net/img/cache/700/VeeMRq/2021/7/8/c01cd207-6bb4-4cf5-ae52-25ad18cf1b46.jpg';
    } else if (name.contains('susu') || name.contains('milk') || name.contains('indomilk') || name.contains('ultra') || name.contains('frisian') || name.contains('dancow')) {
      return 'https://images.tokopedia.net/img/cache/700/OALsub/2023/9/22/e1b69766-0cba-45d2-b0df-2c3c1e21b1be.jpg';
    } else if (name.contains('kopi') || name.contains('coffee') || name.contains('luwak') || name.contains('torabika') || name.contains('nescafe') || name.contains('good day')) {
      return 'https://images.tokopedia.net/img/cache/700/OALsub/2022/10/3/6b4ab9e5-9dbe-40fb-a92e-333e3a4798e4.jpg';
    } else if (name.contains('tepung') || name.contains('terigu') || name.contains('segitiga') || name.contains('sagu')) {
      return 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=200';
    } else if (name.contains('garam') || name.contains('salt')) {
      return 'https://images.unsplash.com/photo-1608797178974-15b35a61d121?auto=format&fit=crop&q=80&w=200';
    } else if (name.contains('bumbu') || name.contains('racik') || name.contains('masako') || name.contains('royco') || name.contains('sasa') || name.contains('ajinomoto')) {
      return 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=200';
    }
    
    // 5. Snacks & Food
    if (name.contains('roti') || name.contains('bread') || name.contains('sari roti') || name.contains('biscuit') || name.contains('biskuit')) {
      return 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=200';
    } else if (name.contains('snack') || name.contains('chiki') || name.contains('lays') || name.contains('chitato') || name.contains('oreo') || name.contains('tango') || name.contains('wafer')) {
      return 'https://images.unsplash.com/photo-1599490659223-937224168867?auto=format&fit=crop&q=80&w=200';
    }
    
    // 6. Household / Cleaning
    if (name.contains('sabun') || name.contains('soap') || name.contains('shampoo') || name.contains('biore') || name.contains('lux') || name.contains('detol') || name.contains('molto') || name.contains('daia') || name.contains('so klin')) {
      return 'https://p16-oec-sg.ibyteimg.com/tos-alisg-i-aphluv4xwc-sg/f038eb2b29514d0aba7f69e6c8aa694e~tplv-aphluv4xwc-white-pad-v1:250:250.jpeg';
    } else if (name.contains('odol') || name.contains('ciptadent') || name.contains('pasta gigi') || name.contains('colgate')) {
      return 'https://images.unsplash.com/photo-1559599101-f09722fb4948?auto=format&fit=crop&q=80&w=200';
    }
    
    // 7. General fallbacks / categories
    if (cat.contains('sayur') || cat.contains('vegetable') || cat.contains('bumbu')) {
      return 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&q=80&w=200';
    } else if (cat.contains('sembako') || cat.contains('bahan') || cat.contains('dapur')) {
      return 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&q=80&w=200';
    } else if (cat.contains('minum') || cat.contains('drink') || cat.contains('cair')) {
      return 'https://images.unsplash.com/photo-1527960656366-ee2a999e32e6?auto=format&fit=crop&q=80&w=200';
    } else if (cat.contains('makan') || cat.contains('snack') || cat.contains('cemilan') || cat.contains('kue')) {
      return 'https://images.unsplash.com/photo-1599490659223-937224168867?auto=format&fit=crop&q=80&w=200';
    } else if (cat.contains('sabun') || cat.contains('cuci') || cat.contains('mandi') || cat.contains('bersih')) {
      return 'https://encrypted-tbn0.gstatic.com/shopping?q=tbn:ANd9GcQxVRpOCZ3tBSu0kzq9yKsmrEvRGLXvzTJnjbCCE2jQSki_EgHA31e0EPMbwDN2_bR7aIcPcaUjUsvtCQIHiqO4AsFzI9qcyH1coPmkjvJlD8ZaxdFkuJjW';
    } else if (cat.contains('rokok') || cat.contains('tembakau')) {
      return 'https://images.unsplash.com/photo-1556997685-30ab4747ebe5?auto=format&fit=crop&q=80&w=200';
    }

    // Dynamic Fallback
    return 'https://loremflickr.com/200/200/grocery,${Uri.encodeComponent(productName)}';
  }

  void handlePayment() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Metode Pembayaran',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldSubtle,
                        foregroundColor: AppTheme.gold,
                        side: const BorderSide(color: AppTheme.gold, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        showCashPaymentDialog();
                      },
                      child: const Column(
                        children: [
                          Icon(Icons.payments_rounded, size: 26),
                          SizedBox(height: 8),
                          Text('Tunai / Cash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldSubtle,
                        foregroundColor: AppTheme.gold,
                        side: const BorderSide(color: AppTheme.gold, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        showQrisPaymentDialog();
                      },
                      child: const Column(
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 26),
                          SizedBox(height: 8),
                          Text('QRIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void showCashPaymentDialog() {
    final TextEditingController bayarController = TextEditingController();
    double kembalian = -totalPrice;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                side: const BorderSide(color: AppTheme.surfaceBorder),
              ),
              title: const Text(
                'Pembayaran Tunai',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.goldSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.gold.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Tagihan', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        Text('Rp ${totalPrice.toInt()}', style: const TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bayarController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: AppTheme.formInputDecoration(label: 'Uang Bayar'),
                    onChanged: (val) {
                      final input = double.tryParse(val) ?? 0.0;
                      setDialogState(() {
                        kembalian = input - totalPrice;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kembalian >= 0 ? AppTheme.successBg : AppTheme.errorBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      kembalian >= 0 
                          ? 'Kembalian: Rp ${kembalian.toInt()}' 
                          : 'Kurang: Rp ${(-kembalian).toInt()}',
                      style: TextStyle(
                        color: kembalian >= 0 ? AppTheme.success : AppTheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  style: AppTheme.primaryButton,
                  onPressed: kembalian < 0 ? null : () {
                    final bayar = double.tryParse(bayarController.text) ?? 0.0;
                    Navigator.pop(context);
                    executePayment(
                      paymentMethod: 'CASH',
                      payment: bayar,
                      change: kembalian,
                    );
                  },
                  child: const Text('Proses', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showQrisPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            side: const BorderSide(color: AppTheme.surfaceBorder),
          ),
          title: const Text(
            'Pembayaran QRIS',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.goldSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.gold.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Total: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text('Rp ${totalPrice.toInt()}', style: const TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 160,
                height: 160,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Center(
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    color: Color(0xFF1A1A1F),
                    size: 130,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Scan QR di atas untuk membayar',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: AppTheme.primaryButton,
              onPressed: () {
                Navigator.pop(context);
                executePayment(
                  paymentMethod: 'QRIS',
                  payment: totalPrice,
                  change: 0.0,
                );
              },
              child: const Text('Konfirmasi Lunas', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void executePayment({
    required String paymentMethod,
    required double payment,
    required double change,
  }) async {
    String noNota = "INV-${DateTime.now().millisecondsSinceEpoch}";
    List<Map<String, dynamic>> items =
        scannedItems.entries.map((entry) {
          return {
            "nama": entry.value['nama'],
            "no_barcode": entry.value['no_barcode'],
            "harga": entry.value['harga'],
            "jumlah": entry.value['jumlah'],
          };
        }).toList();

    double currentDiscount = discount;
    double currentTaxAmount = taxAmount;

    try {
      await PenjualanController.saveTransaction(
        noNota, 
        items,
        diskon: currentDiscount,
        pajak: currentTaxAmount,
        idPelanggan: selectedPelanggan != null ? selectedPelanggan!['id'] : null,
      );
      
      setState(() {
        scannedItems.clear();
        totalItems = 0;
        subtotalPrice = 0.0;
        totalPrice = 0.0;
        discount = 0.0;
        taxPercent = 0.0;
        taxAmount = 0.0;
        selectedPelanggan = null;
        redeemPoints = false;
        pointsDiscount = 0.0;
        promoDiscount = 0.0;
      });

      // Panggil ulang data barang (katalog) agar stoknya langsung ter-update di layar 
      fetchCatalogData();
      fetchPelangganData();

      showSuccessDialog(
        noNota: noNota,
        paymentMethod: paymentMethod,
        items: items,
        total: paymentMethod == 'QRIS' ? payment : (payment - change),
        payment: payment,
        change: change,
        diskon: currentDiscount,
        pajak: currentTaxAmount,
      );

      Future.delayed(const Duration(milliseconds: 400), () {
        PdfInvoiceService.generateAndShareInvoice(
          storeName: "LONIKA_STORE",
          storeAddress: "Jl. Sayur Segar No. 8, Jakarta",
          noNota: noNota,
          paymentMethod: paymentMethod,
          items: items,
          totalPrice: paymentMethod == 'QRIS' ? payment : (payment - change),
          payment: payment,
          change: change,
          diskon: currentDiscount,
          pajak: currentTaxAmount,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error menyimpan transaksi: $e')));
    }
  }

  void showSuccessDialog({
    required String noNota,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required double total,
    required double payment,
    required double change,
    double diskon = 0.0,
    double pajak = 0.0,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            side: const BorderSide(color: AppTheme.surfaceBorder),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.successBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Transaksi Sukses',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('No Nota', noNota),
                    const SizedBox(height: 6),
                    _infoRow('Metode', paymentMethod == 'QRIS' ? 'QRIS' : 'Tunai'),
                    
                    if (diskon > 0) ...[
                      const SizedBox(height: 6),
                      _infoRow('Diskon', '- Rp ${diskon.toInt()}'),
                    ],
                    if (pajak > 0) ...[
                      const SizedBox(height: 6),
                      _infoRow('Pajak', '+ Rp ${pajak.toInt()}'),
                    ],

                    const SizedBox(height: 6),
                    _infoRow('Total', 'Rp ${total.toInt()}', isHighlight: true),
                    if (paymentMethod == 'CASH') ...[
                      const SizedBox(height: 6),
                      _infoRow('Bayar', 'Rp ${payment.toInt()}'),
                      const SizedBox(height: 6),
                      _infoRow('Kembali', 'Rp ${change.toInt()}'),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.goldSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.print_rounded, color: AppTheme.gold, size: 18),
              ),
              tooltip: 'Cetak Struk Bluetooth',
              onPressed: () async {
                final connected = await BluetoothPrinterService.isConnected();
                if (connected) {
                  await BluetoothPrinterService.printReceipt(
                    storeName: "LONIKA_STORE",
                    storeAddress: "Jl. Sayur Segar No. 8, Jakarta",
                    noNota: noNota,
                    items: items,
                    totalPrice: total,
                    payment: payment,
                    change: change,
                    diskon: diskon,
                    pajak: pajak,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Printer tidak terhubung!')),
                  );
                }
              },
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.goldSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.gold, size: 18),
              ),
              tooltip: 'Unduh / Bagikan PDF',
              onPressed: () async {
                await PdfInvoiceService.generateAndShareInvoice(
                  storeName: "LONIKA_STORE",
                  storeAddress: "Jl. Sayur Segar No. 8, Jakarta",
                  noNota: noNota,
                  paymentMethod: paymentMethod,
                  items: items,
                  totalPrice: total,
                  payment: payment,
                  change: change,
                  diskon: diskon,
                  pajak: pajak,
                );
              },
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Selesai', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? AppTheme.gold : AppTheme.textPrimary,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            fontSize: isHighlight ? 14 : 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQtyButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.gold : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isPrimary ? Colors.white : AppTheme.textPrimary,
        ),
      ),
    );
  }

  void showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Keranjang Belanja',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '$totalItems Item',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (scannedItems.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.error, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setModalState(() {
                                  scannedItems.clear();
                                  totalItems = 0;
                                  subtotalPrice = 0.0;
                                  totalPrice = 0.0;
                                  discount = 0.0;
                                  taxPercent = 0.0;
                                  taxAmount = 0.0;
                                  selectedPelanggan = null;
                                  pointsDiscount = 0.0;
                                  promoDiscount = 0.0;
                                });
                                setState(() {});
                              },
                              tooltip: 'Kosongkan Keranjang',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (scannedItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: const Column(
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 40, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('Keranjang kosong', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.30,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: scannedItems.length,
                        itemBuilder: (context, index) {
                          String barcode = scannedItems.keys.elementAt(index);
                          Map<String, dynamic> item = scannedItems[barcode]!;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item['nama']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Rp ${item['harga']} x ${item['jumlah']}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    _buildQtyButton(
                                      icon: Icons.remove_rounded,
                                      onTap: () {
                                        removeItem(barcode);
                                        setModalState(() {});
                                        setState(() {});
                                      },
                                    ),
                                    Container(
                                      width: 36,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${item['jumlah']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    _buildQtyButton(
                                      icon: Icons.add_rounded,
                                      onTap: () {
                                        addItem(barcode);
                                        setModalState(() {});
                                        setState(() {});
                                      },
                                      isPrimary: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  'Rp ${item['harga'] * item['jumlah']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppTheme.gold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  
                  // Breakdown section
                  if (discount > 0 || promoDiscount > 0 || pointsDiscount > 0 || taxPercent > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        Text('Rp ${subtotalPrice.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (promoDiscount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Promo Otomatis', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        Text('- Rp ${promoDiscount.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.error)),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (discount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Diskon Manual', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        Text('- Rp ${discount.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.error)),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (pointsDiscount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Diskon Member (10%)', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        Text('- Rp ${pointsDiscount.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.error)),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (taxPercent > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pajak PPN (${taxPercent.toInt()}%)', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        Text('+ Rp ${taxAmount.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.info)),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pembayaran',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rp ${totalPrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Button to set Pelanggan
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.info,
                      side: const BorderSide(color: AppTheme.info),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.person_rounded, size: 18),
                    label: Text(selectedPelanggan == null
                        ? 'Pilih Pelanggan (Member)'
                        : 'Pelanggan: ${selectedPelanggan!['nama']} (${selectedPelanggan!['poin']} Poin)'),
                    onPressed: () {
                      _showSelectPelangganDialog(setModalState);
                    },
                  ),
                  const SizedBox(height: 8),

                  // Button to set discount and tax
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.gold,
                      side: const BorderSide(color: AppTheme.gold),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.discount_rounded, size: 18),
                    label: const Text('Atur Diskon & Pajak'),
                    onPressed: () {
                      showDiscountTaxDialog();
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  ElevatedButton(
                    style: AppTheme.primaryButton,
                    onPressed: scannedItems.isEmpty
                        ? null
                        : () {
                            Navigator.pop(context);
                            handlePayment();
                          },
                    child: const Text('Bayar Sekarang', style: TextStyle(fontSize: 15)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSelectPelangganDialog(StateSetter setModalState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Pilih Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          content: SizedBox(
            width: double.maxFinite,
            child: allPelanggan.isEmpty
                ? const Text('Belum ada data pelanggan.', style: TextStyle(color: AppTheme.textSecondary))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: allPelanggan.length,
                    itemBuilder: (context, index) {
                      final p = allPelanggan[index];
                      return ListTile(
                        leading: const Icon(Icons.person, color: AppTheme.gold),
                        title: Text(p['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${p['no_hp']?.toString() ?? '-'} • Poin: ${p['poin'] ?? 0}'),
                        onTap: () {
                          setState(() {
                            selectedPelanggan = p;
                          });
                          setModalState(() {});
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  selectedPelanggan = null;
                });
                setModalState(() {});
                Navigator.pop(context);
              },
              child: const Text('Hapus Pilihan', style: TextStyle(color: AppTheme.error)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        );
      },
    );
  }

  void showBarcodeScanDialog() {
    final TextEditingController barcodeInputController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: AppTheme.gold),
              SizedBox(width: 10),
              Text(
                'Scan / Barcode',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: barcodeInputController,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: AppTheme.searchInputDecoration(hint: 'Ketik barcode...'),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    addItem(val.trim());
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final val = barcodeInputController.text.trim();
                if (val.isNotEmpty) {
                  addItem(val);
                  Navigator.pop(context);
                }
              },
              child: const Text('Tambah', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ── Header (Image 2 Style - Compact Polished) ──
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 6,
              left: 12,
              right: 16,
              bottom: 12,
            ),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Cashier',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'LONIKA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Clock Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Scanner Button
                GestureDetector(
                  onTap: showBarcodeScanDialog,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppTheme.gold, 
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Search & Filter ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (val) {
                    setState(() {
                      searchQuery = val;
                      filterCatalog();
                    });
                  },
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: AppTheme.searchInputDecoration(hint: 'Ketik nama barang atau sku...'),
                ),
                const SizedBox(height: 10),
                // Category Chips
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final catName = categories[index];
                      final isSelected = selectedCategory == catName;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategory = catName;
                              filterCatalog();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.gold : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                catName,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 6),

          // ── Catalog Grid (Image 2 - Compact aspect ratio & text sizing) ──
          Expanded(
            child: isCatalogLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
                    ),
                  )
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_basket_rounded, color: AppTheme.textMuted, size: 36),
                            const SizedBox(height: 8),
                            const Text(
                              'Produk tidak ditemukan',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: MediaQuery.of(context).size.width > 600 ? 0.70 : 0.60,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final name = product['nama'] ?? '';
                          final price = product['harga'] ?? 0;
                          final stok = product['stok'] ?? 0;
                          final barcode = product['no_barcode'] ?? '';
                          final category = product['kategori'] ?? 'Umum';

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Image
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: Image.network(
                                      getProductImageUrl(name.toString(), category.toString()),
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: double.infinity,
                                          color: Colors.grey[50],
                                          child: const Icon(Icons.image_rounded, color: Colors.grey, size: 28),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8), // Reduced padding slightly
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Title
                                      Text(
                                        name.toString().toLowerCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13, // Reduced
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2), // Reduced spacing
                                      // Price
                                      Text(
                                        'Rp ${_formatMoney(price)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12, // Reduced
                                          color: AppTheme.gold,
                                        ),
                                      ),
                                      const SizedBox(height: 4), // Reduced spacing
                                      // Stock + Add Button
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '$stok sisa',
                                            style: const TextStyle(
                                              fontSize: 10, // Reduced
                                              color: AppTheme.textSecondary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => addItem(barcode.toString()),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: AppTheme.goldSubtle,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.add_shopping_cart_rounded,
                                                size: 16, // Reduced
                                                color: AppTheme.gold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // ── Bottom Checkout Bar ──
          if (scannedItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: showCartBottomSheet,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.goldSubtle,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.shopping_cart_rounded,
                              color: AppTheme.gold,
                              size: 22,
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$totalItems',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total Tagihan',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Rp ${_formatMoney(totalPrice.toInt())}',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: AppTheme.primaryButton.copyWith(
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                      ),
                      onPressed: showCartBottomSheet,
                      child: const Text('Bayar Sekarang', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatMoney(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
