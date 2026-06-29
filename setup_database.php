<?php
/**
 * Setup Database Script - Expert Backend Developer Version
 * 
 * File ini digunakan untuk membuat tabel baru dan menambahkan kolom yang diperlukan
 * tanpa merusak atau menghapus data yang sudah ada (DILARANG KERAS DROP TABLE).
 * 
 * Aturan yang diterapkan:
 * 1. Tanpa DROP TABLE.
 * 2. Menggunakan CREATE TABLE IF NOT EXISTS.
 * 3. Logika PHP untuk mengecek kolom 'kategori' di tabel barang sebelum menjalankan ALTER TABLE.
 * 4. Terhubung dengan file koneksi database (koneksi.php).
 */

// 1. Hubungkan ke file koneksi database
$koneksi_file = 'koneksi.php';
$koneksi_loaded = false;
$error_msg = '';

if (file_exists($koneksi_file)) {
    try {
        include_once $koneksi_file;
        $koneksi_loaded = true;
    } catch (Exception $e) {
        $error_msg = "Error saat memuat file koneksi: " . $e->getMessage();
    }
} else {
    $error_msg = "File '$koneksi_file' tidak ditemukan di direktori utama project.";
}

// Deteksi variabel koneksi yang didefinisikan di koneksi.php
$db = null;
if ($koneksi_loaded) {
    // Mengecek variabel koneksi yang sering digunakan di PHP (mysqli atau PDO)
    if (isset($koneksi)) {
        $db = $koneksi;
    } elseif (isset($conn)) {
        $db = $conn;
    } elseif (isset($db_conn)) {
        $db = $db_conn;
    } elseif (isset($link)) {
        $db = $link;
    }
}

// 2. Fungsi pembantu untuk menjalankan query secara aman (Mendukung MySQLi (Objek/Prosedural) dan PDO)
function jalankanQuery($db, $sql) {
    if (!$db) return false;
    
    if ($db instanceof PDO) {
        try {
            return $db->exec($sql) !== false;
        } catch (PDOException $e) {
            return false;
        }
    } elseif ($db instanceof mysqli) {
        return $db->query($sql);
    } elseif (is_resource($db) || (is_object($db) && get_class($db) === 'mysqli')) {
        return mysqli_query($db, $sql);
    }
    return false;
}

// Fungsi untuk mendapatkan detail error query
function dapatkanError($db) {
    if (!$db) return 'Koneksi database tidak tersedia.';
    
    if ($db instanceof PDO) {
        $info = $db->errorInfo();
        return isset($info[2]) ? $info[2] : 'PDO Error';
    } elseif ($db instanceof mysqli) {
        return $db->error;
    } elseif (is_resource($db) || (is_object($db) && get_class($db) === 'mysqli')) {
        return mysqli_error($db);
    }
    return 'Koneksi database tidak dikenal.';
}

// 3. Fungsi untuk mendeteksi apakah tabel ada di database
function cekTabelAda($db, $tableName) {
    if (!$db) return false;
    
    $sql = "SHOW TABLES LIKE '$tableName'";
    if ($db instanceof PDO) {
        try {
            $stmt = $db->query($sql);
            return $stmt && $stmt->rowCount() > 0;
        } catch (Exception $e) {
            return false;
        }
    } elseif ($db instanceof mysqli) {
        $result = $db->query($sql);
        return $result && $result->num_rows > 0;
    } else {
        $result = mysqli_query($db, $sql);
        return $result && mysqli_num_rows($result) > 0;
    }
}

// 4. Fungsi untuk mendeteksi apakah kolom ada di tabel tertentu
function cekKolomAda($db, $tableName, $columnName) {
    if (!$db) return false;
    
    $sql = "SHOW COLUMNS FROM `$tableName` LIKE '$columnName'";
    if ($db instanceof PDO) {
        try {
            $stmt = $db->query($sql);
            return $stmt && $stmt->rowCount() > 0;
        } catch (Exception $e) {
            return false;
        }
    } elseif ($db instanceof mysqli) {
        $result = $db->query($sql);
        return $result && $result->num_rows > 0;
    } else {
        $result = mysqli_query($db, $sql);
        return $result && mysqli_num_rows($result) > 0;
    }
}

// Status eksekusi
$status_pelanggan = 'pending';
$status_utang = 'pending';
$status_kategori = 'pending';
$target_barang_table = '';
$err_pelanggan = '';
$err_utang = '';
$err_kategori = '';

if ($db) {
    // A. Buat tabel tb_pelanggan
    $sql_pelanggan = "CREATE TABLE IF NOT EXISTS `tb_pelanggan` (
        `id_pelanggan` INT AUTO_INCREMENT PRIMARY KEY,
        `nama_pelanggan` VARCHAR(255) NOT NULL,
        `no_hp` VARCHAR(20) NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;";
    
    if (jalankanQuery($db, $sql_pelanggan)) {
        $status_pelanggan = 'success';
    } else {
        $status_pelanggan = 'error';
        $err_pelanggan = dapatkanError($db);
    }
    
    // B. Buat tabel tb_transaksi_utang
    // Catatan: Gunakan foreign key yang mengarah ke tb_pelanggan(id_pelanggan)
    $sql_utang = "CREATE TABLE IF NOT EXISTS `tb_transaksi_utang` (
        `id_utang` INT AUTO_INCREMENT PRIMARY KEY,
        `id_pelanggan` INT NOT NULL,
        `total_utang` INT DEFAULT 0,
        `sudah_dibayar` INT DEFAULT 0,
        `status_lunas` VARCHAR(50) DEFAULT 'Belum Lunas',
        `tanggal_jatuh_tempo` DATE NULL,
        FOREIGN KEY (`id_pelanggan`) REFERENCES `tb_pelanggan`(`id_pelanggan`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;";
    
    if (jalankanQuery($db, $sql_utang)) {
        $status_utang = 'success';
    } else {
        $status_utang = 'error';
        $err_utang = dapatkanError($db);
    }
    
    // C. Cek kolom kategori di tabel barang
    // Kami memeriksa tb_barang sesuai instruksi. Namun, jika tb_barang tidak ada,
    // kami melakukan fallback ke tabel 'barang' untuk kemudahan Anda jika tabelnya tanpa prefix 'tb_'.
    if (cekTabelAda($db, 'tb_barang')) {
        $target_barang_table = 'tb_barang';
    } elseif (cekTabelAda($db, 'barang')) {
        $target_barang_table = 'barang';
    } else {
        $target_barang_table = 'tb_barang'; // Default fallback tetap tb_barang untuk ALTER
    }
    
    if (cekTabelAda($db, $target_barang_table)) {
        if (cekKolomAda($db, $target_barang_table, 'kategori')) {
            $status_kategori = 'exists';
        } else {
            $sql_alter = "ALTER TABLE `$target_barang_table` ADD COLUMN `kategori` VARCHAR(50) DEFAULT 'Umum';";
            if (jalankanQuery($db, $sql_alter)) {
                $status_kategori = 'success';
            } else {
                $status_kategori = 'error';
                $err_kategori = dapatkanError($db);
            }
        }
    } else {
        $status_kategori = 'not_found';
        $err_kategori = "Tabel '$target_barang_table' tidak ditemukan di database.";
    }
}
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Database Setup Wizard</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-color: #121214;
            --card-bg: #1a1a1e;
            --text-primary: #f3f4f6;
            --text-secondary: #9ca3af;
            --primary: #a98c6a;
            --success: #10b981;
            --error: #ef4444;
            --info: #3b82f6;
            --warning: #f59e0b;
        }
        
        body {
            font-family: 'Inter', sans-serif;
            background-color: var(--bg-color);
            color: var(--text-primary);
            margin: 0;
            padding: 40px 20px;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            box-sizing: border-box;
        }
        
        .container {
            width: 100%;
            max-width: 650px;
            background: var(--card-bg);
            border-radius: 16px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
            border: 1px solid rgba(255, 255, 255, 0.05);
            padding: 35px;
            box-sizing: border-box;
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
            padding-bottom: 20px;
        }
        
        .header h1 {
            font-size: 24px;
            font-weight: 700;
            color: var(--primary);
            margin: 0 0 10px 0;
            letter-spacing: 0.5px;
            text-transform: uppercase;
        }
        
        .header p {
            color: var(--text-secondary);
            font-size: 14px;
            margin: 0;
        }
        
        .status-list {
            margin-bottom: 30px;
        }
        
        .status-item {
            background: rgba(255, 255, 255, 0.02);
            border-radius: 10px;
            padding: 18px 20px;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-left: 4px solid var(--text-secondary);
            transition: all 0.3s ease;
        }
        
        .status-item.success {
            border-left-color: var(--success);
            background: rgba(16, 185, 129, 0.04);
        }
        
        .status-item.error {
            border-left-color: var(--error);
            background: rgba(239, 68, 68, 0.04);
        }
        
        .status-item.info {
            border-left-color: var(--info);
            background: rgba(59, 130, 246, 0.04);
        }
        
        .status-item.warning {
            border-left-color: var(--warning);
            background: rgba(245, 158, 11, 0.04);
        }
        
        .item-info {
            display: flex;
            flex-direction: column;
            max-width: 70%;
        }
        
        .item-title {
            font-weight: 600;
            font-size: 15px;
            margin-bottom: 4px;
        }
        
        .item-desc {
            font-size: 12px;
            color: var(--text-secondary);
            line-height: 1.4;
        }
        
        .badge {
            font-size: 10px;
            font-weight: 700;
            text-transform: uppercase;
            padding: 6px 12px;
            border-radius: 20px;
            letter-spacing: 0.5px;
            white-space: nowrap;
        }
        
        .badge.success {
            background: rgba(16, 185, 129, 0.15);
            color: var(--success);
            border: 1px solid rgba(16, 185, 129, 0.3);
        }
        
        .badge.error {
            background: rgba(239, 68, 68, 0.15);
            color: var(--error);
            border: 1px solid rgba(239, 68, 68, 0.3);
        }
        
        .badge.info {
            background: rgba(59, 130, 246, 0.15);
            color: var(--info);
            border: 1px solid rgba(59, 130, 246, 0.3);
        }
        
        .badge.warning {
            background: rgba(245, 158, 11, 0.15);
            color: var(--warning);
            border: 1px solid rgba(245, 158, 11, 0.3);
        }
        
        .alert-box {
            background: rgba(239, 68, 68, 0.08);
            border: 1px solid rgba(239, 68, 68, 0.2);
            border-radius: 10px;
            padding: 15px 20px;
            margin-bottom: 25px;
            color: #fca5a5;
            font-size: 14px;
            line-height: 1.5;
        }
        
        .alert-box strong {
            color: var(--error);
        }

        .alert-success-connection {
            background: rgba(16, 185, 129, 0.08);
            border: 1px solid rgba(16, 185, 129, 0.2);
            border-radius: 10px;
            padding: 12px 20px;
            margin-bottom: 25px;
            color: #a7f3d0;
            font-size: 14px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        
        .footer {
            text-align: center;
            font-size: 12px;
            color: var(--text-secondary);
            margin-top: 25px;
            border-top: 1px solid rgba(255, 255, 255, 0.08);
            padding-top: 20px;
        }
        
        .btn-refresh {
            display: inline-block;
            background: var(--primary);
            color: #121214;
            text-decoration: none;
            padding: 12px 24px;
            border-radius: 8px;
            font-weight: 600;
            margin-top: 15px;
            transition: all 0.2s ease;
            border: none;
            cursor: pointer;
            width: 100%;
            text-align: center;
            box-sizing: border-box;
        }
        
        .btn-refresh:hover {
            opacity: 0.9;
            transform: translateY(-1px);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Database Setup Wizard</h1>
            <p>Konfigurasi skema database otomatis secara aman.</p>
        </div>
        
        <?php if (!$db): ?>
            <div class="alert-box">
                <strong>Koneksi Database Gagal:</strong><br>
                <?php echo htmlspecialchars($error_msg); ?><br><br>
                <em>Pastikan file <code>koneksi.php</code> ada di folder yang sama dan mendefinisikan variabel koneksi (seperti <code>$koneksi</code> atau <code>$conn</code>) dengan benar.</em>
            </div>
        <?php else: ?>
            <div class="alert-success-connection">
                <span>⚡ Koneksi ke database berhasil terhubung.</span>
                <span class="badge success">Koneksi OK</span>
            </div>
        <?php endif; ?>
        
        <div class="status-list">
            <!-- Tabel tb_pelanggan -->
            <div class="status-item <?php echo ($status_pelanggan === 'success') ? 'success' : (($status_pelanggan === 'error') ? 'error' : 'info'); ?>">
                <div class="item-info">
                    <span class="item-title">Pembuatan Tabel: <code>tb_pelanggan</code></span>
                    <span class="item-desc">
                        <?php 
                        if ($status_pelanggan === 'success') {
                            echo "Tabel 'tb_pelanggan' berhasil diverifikasi / dibuat dengan kolom id_pelanggan, nama_pelanggan, no_hp.";
                        } elseif ($status_pelanggan === 'error') {
                            echo "Gagal: " . htmlspecialchars($err_pelanggan);
                        } else {
                            echo "Menunggu koneksi database...";
                        }
                        ?>
                    </span>
                </div>
                <span class="badge <?php echo ($status_pelanggan === 'success') ? 'success' : (($status_pelanggan === 'error') ? 'error' : 'info'); ?>">
                    <?php echo ($status_pelanggan === 'success') ? 'Dibuat/OK' : (($status_pelanggan === 'error') ? 'Gagal' : 'Tertunda'); ?>
                </span>
            </div>
            
            <!-- Tabel tb_transaksi_utang -->
            <div class="status-item <?php echo ($status_utang === 'success') ? 'success' : (($status_utang === 'error') ? 'error' : 'info'); ?>">
                <div class="item-info">
                    <span class="item-title">Pembuatan Tabel: <code>tb_transaksi_utang</code></span>
                    <span class="item-desc">
                        <?php 
                        if ($status_utang === 'success') {
                            echo "Tabel 'tb_transaksi_utang' berhasil diverifikasi / dibuat dengan relasi kunci tamu ke tb_pelanggan.";
                        } elseif ($status_utang === 'error') {
                            echo "Gagal: " . htmlspecialchars($err_utang);
                        } else {
                            echo "Menunggu koneksi database...";
                        }
                        ?>
                    </span>
                </div>
                <span class="badge <?php echo ($status_utang === 'success') ? 'success' : (($status_utang === 'error') ? 'error' : 'info'); ?>">
                    <?php echo ($status_utang === 'success') ? 'Dibuat/OK' : (($status_utang === 'error') ? 'Gagal' : 'Tertunda'); ?>
                </span>
            </div>
            
            <!-- Kolom kategori pada tb_barang -->
            <div class="status-item <?php 
                if ($status_kategori === 'success') echo 'success';
                elseif ($status_kategori === 'exists') echo 'info';
                elseif ($status_kategori === 'error') echo 'error';
                elseif ($status_kategori === 'not_found') echo 'warning';
                else echo 'info';
            ?>">
                <div class="item-info">
                    <span class="item-title">Kolom Kategori: <code><?php echo htmlspecialchars($target_barang_table); ?></code></span>
                    <span class="item-desc">
                        <?php 
                        if ($status_kategori === 'success') {
                            echo "Kolom 'kategori' (VARCHAR 50) berhasil ditambahkan ke tabel '$target_barang_table' via ALTER TABLE.";
                        } elseif ($status_kategori === 'exists') {
                            echo "Kolom 'kategori' sudah ada sebelumnya di tabel '$target_barang_table' (Aksi dilewati secara aman).";
                        } elseif ($status_kategori === 'not_found') {
                            echo "Peringatan: " . htmlspecialchars($err_kategori);
                        } elseif ($status_kategori === 'error') {
                            echo "Gagal: " . htmlspecialchars($err_kategori);
                        } else {
                            echo "Menunggu koneksi database...";
                        }
                        ?>
                    </span>
                </div>
                <span class="badge <?php 
                    if ($status_kategori === 'success') echo 'success';
                    elseif ($status_kategori === 'exists') echo 'info';
                    elseif ($status_kategori === 'error') echo 'error';
                    elseif ($status_kategori === 'not_found') echo 'warning';
                    else echo 'info';
                ?>">
                    <?php 
                    if ($status_kategori === 'success') echo 'Ditambahkan';
                    elseif ($status_kategori === 'exists') echo 'Sudah Ada';
                    elseif ($status_kategori === 'not_found') echo 'Tidak Ada';
                    elseif ($status_kategori === 'error') echo 'Gagal';
                    else echo 'Tertunda';
                    ?>
                </span>
            </div>
        </div>

        <button onclick="window.location.reload();" class="btn-refresh">Jalankan Ulang Setup (Refresh)</button>
        
        <div class="footer">
            Database Setup Wizard &bull; Developer Mode &bull; <?php echo date('Y-m-d H:i:s'); ?>
        </div>
    </div>
</body>
</html>
