-- SQL SCHEMA & DATABASE ALTERATIONS (APPEND-ONLY)
-- Gunakan file ini untuk memperbarui skema database Anda tanpa merusak data asli.

-- ==========================================
-- 1. FITUR KATEGORI & FILTER BARANG (ALTER TABLE)
-- ==========================================
-- Menambahkan kolom 'kategori' ke tabel 'barang' yang sudah ada.
-- Default value diatur ke 'Umum' agar data lama tidak bernilai null dan merusak UI.
ALTER TABLE barang ADD COLUMN kategori VARCHAR(100) DEFAULT 'Umum';

-- ==========================================
-- 2. FITUR ANALITIK LABA/RUGI (ALTER TABLE)
-- ==========================================
-- Menambahkan kolom 'hpp' (Harga Pokok Penjualan / Modal barang) ke tabel 'barang'.
-- Kolom ini digunakan untuk menghitung selisih keuntungan bersih (harga jual - hpp).
ALTER TABLE barang ADD COLUMN hpp INT DEFAULT 0;

-- ==========================================
-- 3. FITUR KASBON (CATATAN UTANG - TABEL BARU)
-- ==========================================
-- Membuat tabel 'pelanggan' untuk mencatat identitas pelanggan kasbon.
CREATE TABLE IF NOT EXISTS pelanggan (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(255) NOT NULL,
    telepon VARCHAR(20),
    total_utang INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Membuat tabel 'transaksi_utang' untuk menyimpan riwayat utang dan cicilan pelanggan.
-- Tipe 'utang' akan menambah saldo total_utang pelanggan, sedangkan tipe 'cicilan' (bayar) akan menguranginya.
CREATE TABLE IF NOT EXISTS transaksi_utang (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_pelanggan INT NOT NULL,
    tipe ENUM('utang', 'cicilan') NOT NULL,
    jumlah INT NOT NULL,
    tanggal TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    keterangan TEXT,
    status_lunas VARCHAR(20) DEFAULT 'Belum Lunas', -- 'Lunas' atau 'Belum Lunas'
    FOREIGN KEY (id_pelanggan) REFERENCES pelanggan(id) ON DELETE CASCADE
);

-- ==========================================
-- 4. OPTIMASI QUERY & INDEXING (ANALITIK & RIWAYAT)
-- ==========================================
-- Menambahkan index pada kolom 'tanggal' di tabel 'penjualan' untuk mempercepat filter omzet harian.
CREATE INDEX idx_penjualan_tanggal ON penjualan(tanggal);
-- Menambahkan index pada barcode barang untuk mengoptimalkan JOIN antara penjualan dan barang.
CREATE INDEX idx_barang_barcode ON barang(no_barcode);
CREATE INDEX idx_penjualan_barcode ON penjualan(no_barcode);
