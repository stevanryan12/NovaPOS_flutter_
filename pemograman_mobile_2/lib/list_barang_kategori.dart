import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pemograman_mobile_2/config.dart';
import 'package:pemograman_mobile_2/app_theme.dart';
import 'package:pemograman_mobile_2/add_edit_barang.dart';
import 'package:pemograman_mobile_2/barang_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pemograman_mobile_2/penjualan_controller.dart';
import 'package:pemograman_mobile_2/add_edit_supplier.dart';

class ListBarangKategoriScreen extends StatefulWidget {
  @override
  _ListBarangKategoriScreenState createState() => _ListBarangKategoriScreenState();
}

class _ListBarangKategoriScreenState extends State<ListBarangKategoriScreen> {
  static final String baseUrl = AppConfig.baseUrl;
  final BarangController barangController = BarangController();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> barang = [];
  List<Map<String, dynamic>> filteredBarang = [];
  List<String> categories = ['Semua'];
  String selectedCategory = 'Semua';
  bool isLoading = true;

  double totalSales = 0.0;
  List<Map<String, dynamic>> recentTransactions = [];
  List<double> monthlySales = List.filled(12, 0);

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchBarang();
    fetchDashboardMetrics();
  }

  Future<void> fetchDashboardMetrics() async {
    try {
      final List<Map<String, dynamic>> historyData = await PenjualanController().fetchHistory();
      double tempSales = 0.0;
      List<double> tempMonthlySales = List.filled(12, 0);

      for (var item in historyData) {
        final double harga = (item['harga'] ?? 0).toDouble();
        final double jumlah = (item['jumlah'] ?? 0).toDouble();
        final double subtotal = harga * jumlah;
        tempSales += subtotal;

        try {
          if (item['tanggal'] != null) {
            final date = DateTime.parse(item['tanggal'].toString());
            tempMonthlySales[date.month - 1] += subtotal;
          } else {
            final String noNota = item['no_nota'] ?? '';
            if (noNota.contains('-')) {
              final parts = noNota.split('-');
              if (parts.length > 1) {
                final ts = int.tryParse(parts.last);
                if (ts != null) {
                  final date = DateTime.fromMillisecondsSinceEpoch(ts);
                  tempMonthlySales[date.month - 1] += subtotal;
                }
              }
            }
          }
        } catch (_) {}
      }

      setState(() {
        totalSales = tempSales;
        recentTransactions = historyData;
        monthlySales = tempMonthlySales;
      });
    } catch (e) {
      print('Error fetching metrics for product screen: $e');
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/kategori'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          categories = ['Semua', ...data.map((e) => e.toString())];
        });
      }
    } catch (e) {
      print('Gagal mengambil kategori: $e');
    }
  }

  Future<void> fetchBarang() async {
    setState(() => isLoading = true);
    try {
      List<Map<String, dynamic>> data;
      if (selectedCategory == 'Semua') {
        data = await barangController.fetchBarang();
      } else {
        final response = await http.get(Uri.parse('$baseUrl/barang/kategori/$selectedCategory'));
        if (response.statusCode == 200) {
          final List<dynamic> body = json.decode(response.body);
          data = body.map((item) => item as Map<String, dynamic>).toList();
        } else {
          throw Exception('Gagal mengambil barang berdasarkan kategori');
        }
      }

      setState(() {
        barang = data;
        filteredBarang = data;
        isLoading = false;
      });
      if (searchController.text.isNotEmpty) {
        filterSearch(searchController.text);
      }
    } catch (e) {
      setState(() => isLoading = false);
      showError(e.toString());
    }
  }

  void filterSearch(String query) {
    setState(() {
      filteredBarang = barang.where((item) {
        final nama = item['nama']?.toString().toLowerCase() ?? '';
        final barcode = item['no_barcode']?.toString().toLowerCase() ?? '';
        return nama.contains(query.toLowerCase()) || barcode.contains(query.toLowerCase());
      }).toList();
    });
  }

  void deleteBarang(String noBarcode) async {
    try {
      await barangController.deleteBarang(noBarcode);
      setState(() {
        barang.removeWhere((item) => item['no_barcode'] == noBarcode);
        filteredBarang.removeWhere((item) => item['no_barcode'] == noBarcode);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barang berhasil dihapus')),
      );
    } catch (e) {
      showError(e.toString());
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String getProductImageUrl(String productName, String categoryName) {
    final name = productName.toLowerCase();
    final cat = categoryName.toLowerCase();
    
    // 1. Specific Indonesian Brand Product Mappings
    if (name.contains('pucuk') || name.contains('teh pucuk')) {
      return 'https://coreimages.lottemart.co.id/ord/06/1051403000';
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
      return 'https://images.unsplash.com/photo-1607006342411-1a9032b2c12d?auto=format&fit=crop&q=80&w=200';
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
      return 'https://images.unsplash.com/photo-1563453392212-326f5e854473?auto=format&fit=crop&q=80&w=200';
    } else if (cat.contains('rokok') || cat.contains('tembakau')) {
      return 'https://images.unsplash.com/photo-1556997685-30ab4747ebe5?auto=format&fit=crop&q=80&w=200';
    }

    // Dynamic Fallback
    return 'https://loremflickr.com/200/200/grocery,${Uri.encodeComponent(productName)}';
  }

  String _formatMoney(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}J';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.gold,
        backgroundColor: AppTheme.surface,
        onRefresh: () async {
          await fetchBarang();
          await fetchDashboardMetrics();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header + Stats ──
              _buildHeaderAndStats(),
              const SizedBox(height: 52), // Spacing for metrics overlay

              // ── Bar Chart ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistik Penjualan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSalesChart(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // ── Category Chips ──
              if (categories.length > 2) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 28,
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
                              });
                              fetchBarang();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Center(
                                child: Text(
                                  catName,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Ringkasan Produk Section ──
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Ringkasan Produk',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Tombol Tambah (Dipindah dari FAB) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: _showAddOptionsSheet,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFEA580C)], // Orange gradient
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEA580C).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Tambah Barang/Pemasok',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Product Grid ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
                          ),
                        ),
                      )
                    : filteredBarang.isEmpty
                        ? SizedBox(height: 200, child: _buildEmptyState())
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 120),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 2.0,
                            ),
                            itemCount: filteredBarang.length,
                            itemBuilder: (context, index) {
                              final item = filteredBarang[index];
                              return _buildProductCard(item);
                            },
                          ),
              ),
              const SizedBox(height: 30), // bottom spacing
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAndStats() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Premium Dark Slate background header
        Container(
          height: 195,
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            bottom: 60,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A), // Slate 900
                Color(0xFF1E293B), // Slate 800
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top line: Store Name & Hi Lonika + Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'LONIKA_STORE',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Hi Lonika, ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        '✨',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.amberAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1.5),
                        ),
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey,
                          backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=150',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Search Input Row (from mockup)
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: filterSearch,
                  style: const TextStyle(color: Color(0xFF1F2937), fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Cari produk, transaksi, dll.',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Stat Cards Overlay
        Positioned(
          left: 16,
          right: 16,
          bottom: -40, // push it down to overlap the white background
          child: Row(
            children: [
              // Hari Ini Penjualan
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Hari Ini Penjualan',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 11,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${_formatMoney(totalSales.toInt())}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Total Transaksi
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.credit_card_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Transaksi',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  width: 11,
                                  height: 11,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'i',
                                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${recentTransactions.length} TRX',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '▲ 1.50%',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Color(0xFF22C55E),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalesChart() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    final maxValue = monthlySales.isEmpty ? 1.0 : (monthlySales.reduce((a, b) => a > b ? a : b));
    final safeMax = maxValue == 0 ? 1.0 : maxValue;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Juta Rp',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              AppTheme.badge(text: DateTime.now().year.toString(), fontSize: 9),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: safeMax * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 6,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final index = group.x.toInt();
                      final monthName = (index >= 0 && index < months.length) ? months[index] : '';
                      final salesVal = (index >= 0 && index < monthlySales.length) ? monthlySales[index] : 0.0;
                      return BarTooltipItem(
                        '$monthName\nRp ${_formatNumber(salesVal.toInt())}',
                        const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            months[index],
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Text(
                              'Rp 0',
                              textAlign: TextAlign.right,
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            _formatNumber(value.toInt()),
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMax / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.surfaceBorder,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(12, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: monthlySales[i],
                        width: 9,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFF1E293B),
                            Color(0xFF0F172A),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final String categoryLabel = item['kategori'] ?? 'Umum';
    final int stok = (item['stok'] ?? 0) as int;
    final int harga = (item['harga'] ?? 0) as int;
    final String name = item['nama'] ?? '';
    final isLowStock = stok <= 5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image fills the full height of the card
          Container(
            width: 75,
            color: const Color(0xFFF8FAFC),
            child: Image.network(
              getProductImageUrl(name, categoryLabel),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.image_rounded, color: Colors.grey, size: 32),
                );
              },
            ),
          ),
          // Text content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name.toLowerCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rp ${_formatMoney(harga)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Qty: $stok',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isLowStock) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Low stock',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditBarangScreen(data: item),
                                ),
                              );
                              if (result == true) {
                                fetchBarang();
                              }
                            },
                            child: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => deleteBarang(item['no_barcode']),
                            child: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: AppTheme.textMuted, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            barang.isEmpty ? 'Belum ada data barang' : 'Data barang tidak ditemukan',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showAddOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tambah Data Baru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.slate800,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.goldMuted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: AppTheme.gold),
                  ),
                  title: const Text(
                    'Tambah Barang Baru',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Input item, kategori, harga, dan stok awal'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddEditBarangScreen()),
                    );
                    if (result == true) {
                      fetchBarang();
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Color(0xFF0284C7)),
                  ),
                  title: const Text(
                    'Tambah Pemasok / Supplier Baru',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Input nama supplier, kontak, dan alamat'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddEditSupplierScreen()),
                    );
                    if (result == true) {
                      fetchBarang();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
