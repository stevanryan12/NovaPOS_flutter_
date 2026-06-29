import 'package:flutter/material.dart';
import 'package:pemograman_mobile_2/app_theme.dart';
import 'package:pemograman_mobile_2/penjualan_controller.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final PenjualanController historyController = PenjualanController();
  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> filteredHistory = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  final Set<int> expandedIndices = {};
  
  String selectedFilter = 'Semua';
  final List<String> filterOptions = ['Semua', 'Harian', 'Mingguan', 'Bulanan', 'Tahunan'];

  @override
  void initState() {
    super.initState();
    fetchTransactionHistory();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchTransactionHistory() async {
    try {
      final data = await historyController.fetchHistory();
      setState(() {
        history = groupItemsByInvoice(data);
        history.sort((a, b) {
          final noNotaA = a['no_nota'] ?? '';
          final noNotaB = b['no_nota'] ?? '';
          final tsA = int.tryParse(noNotaA.split('-').last) ?? 0;
          final tsB = int.tryParse(noNotaB.split('-').last) ?? 0;
          return tsB.compareTo(tsA);
        });
        isLoading = false;
      });
      applyFilters();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching history: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  List<Map<String, dynamic>> groupItemsByInvoice(List<dynamic> data) {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in data) {
      String invoiceNumber = item['no_nota'] ?? 'Unknown';
      if (!grouped.containsKey(invoiceNumber)) {
        grouped[invoiceNumber] = [];
      }
      grouped[invoiceNumber]!.add(item);
    }

    return grouped.entries.map((entry) {
      DateTime? invoiceDate;
      if (entry.value.isNotEmpty) {
        final rawTanggal = entry.value[0]['tanggal'];
        if (rawTanggal != null) {
          invoiceDate = DateTime.tryParse(rawTanggal.toString())?.toLocal();
        }
        if (invoiceDate == null && entry.key.contains('-')) {
          final ts = int.tryParse(entry.key.split('-').last);
          if (ts != null) {
            invoiceDate = DateTime.fromMillisecondsSinceEpoch(ts);
          }
        }
      }
      return {
        'no_nota': entry.key, 
        'items': entry.value,
        'date': invoiceDate ?? DateTime.now(),
      };
    }).toList();
  }

  void applyFilters() {
    setState(() {
      final now = DateTime.now();
      filteredHistory = history.where((invoice) {
        // 1. Search Query
        final invoiceNo = (invoice['no_nota'] ?? '').toString().toLowerCase();
        final matchesItems = (invoice['items'] as List).any((item) {
          final itemName = (item['nama'] ?? '').toString().toLowerCase();
          return itemName.contains(searchQuery.toLowerCase());
        });
        final matchesSearch = invoiceNo.contains(searchQuery.toLowerCase()) || matchesItems;

        // 2. Time Filter
        bool matchesTime = true;
        final DateTime date = invoice['date'] ?? now;
        
        if (selectedFilter == 'Harian') {
          matchesTime = date.year == now.year && date.month == now.month && date.day == now.day;
        } else if (selectedFilter == 'Mingguan') {
          // Last 7 days
          final difference = now.difference(date).inDays;
          matchesTime = difference >= 0 && difference <= 7;
        } else if (selectedFilter == 'Bulanan') {
          matchesTime = date.year == now.year && date.month == now.month;
        } else if (selectedFilter == 'Tahunan') {
          matchesTime = date.year == now.year;
        }

        return matchesSearch && matchesTime;
      }).toList();
    });
  }

  void filterSearch(String query) {
    searchQuery = query;
    applyFilters();
  }

  void setTimeFilter(String filter) {
    selectedFilter = filter;
    applyFilters();
  }

  String _formatMoney(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ── Red Header (Image 5 Style) ──
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 16,
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFD32F2F), // Red header color
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 22, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Riwayat Transaksi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                    });
                    fetchTransactionHistory();
                  },
                ),
              ],
            ),
          ),

          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: searchController,
              onChanged: filterSearch,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: AppTheme.searchInputDecoration(hint: 'Cari no. invoice atau nama barang...'),
            ),
          ),

          // ── Filter Waktu ──
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filterOptions.length,
              itemBuilder: (context, index) {
                final option = filterOptions[index];
                final isSelected = selectedFilter == option;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.gold,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppTheme.gold : Colors.grey[300]!,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setTimeFilter(option);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // ── List ──
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
                    ),
                  )
                : filteredHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_rounded, color: AppTheme.textMuted, size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'Tidak ada data transaksi',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.gold,
                        backgroundColor: AppTheme.surface,
                        onRefresh: fetchTransactionHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: filteredHistory.length,
                          itemBuilder: (context, index) {
                            final invoice = filteredHistory[index];
                            return _buildInvoiceCard(index, invoice);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(int index, Map<String, dynamic> invoice) {
    final bool isExpanded = expandedIndices.contains(index);
    final String invoiceNumber = invoice['no_nota'] ?? 'INV-Unknown';
    
    double totalInvoicePrice = 0.0;
    String dateStr = '';
    String paymentMethod = 'Cash'; 
    double maxDiskon = 0.0;
    double maxPajak = 0.0;

    if (invoice['items'] != null && invoice['items'].isNotEmpty) {
      for (var item in invoice['items']) {
        final double harga = (item['harga'] ?? 0).toDouble();
        final double jumlah = (item['jumlah'] ?? 0).toDouble();
        totalInvoicePrice += harga * jumlah;
        
        final double diskon = (item['diskon'] ?? 0).toDouble();
        if (diskon > maxDiskon) maxDiskon = diskon;
        
        final double pajak = (item['pajak'] ?? 0).toDouble();
        if (pajak > maxPajak) maxPajak = pajak;
      }
      totalInvoicePrice = totalInvoicePrice - maxDiskon + maxPajak;
      

      final firstItem = invoice['items'][0];
      try {
        final rawTanggal = firstItem['tanggal'];
        if (rawTanggal != null) {
          final parsedDate = DateTime.parse(rawTanggal.toString()).toLocal();
          dateStr = "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
        }
      } catch (_) {}

      if (dateStr.isEmpty) {
        try {
          if (invoiceNumber.contains('-')) {
            final ts = int.tryParse(invoiceNumber.split('-').last);
            if (ts != null) {
              final parsedDate = DateTime.fromMillisecondsSinceEpoch(ts);
              dateStr = "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
            }
          }
        } catch (_) {}
      }
      
      if (dateStr.isEmpty) {
        dateStr = "2026-03-26 19:43"; 
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            onTap: () {
              setState(() {
                if (expandedIndices.contains(index)) {
                  expandedIndices.remove(index);
                } else {
                  expandedIndices.add(index);
                }
              });
            },
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            title: Text(
              invoiceNumber,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "$dateStr  ·  $paymentMethod",
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rp ${_formatMoney(totalInvoicePrice.toInt())}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
          
          if (isExpanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...invoice['items'].map<Widget>((item) {
                    final double harga = (item['harga'] ?? 0).toDouble();
                    final double jumlah = (item['jumlah'] ?? 0).toDouble();
                    final double subtotal = harga * jumlah;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item['nama']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Rp ${_formatMoney(harga.toInt())} x ${jumlah.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rp ${_formatMoney(subtotal.toInt())}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  
                  if (maxDiskon > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Diskon', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('-Rp ${_formatMoney(maxDiskon.toInt())}', style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  if (maxPajak > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pajak (PPN)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('+Rp ${_formatMoney(maxPajak.toInt())}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
