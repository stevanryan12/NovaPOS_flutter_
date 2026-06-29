/**
 * REST API EXTENSIONS (APPEND-ONLY)
 * Sisipkan kode Express.js berikut ke dalam server backend Node.js (localhost:3000) Anda.
 * Menggunakan SQLite/MySQL untuk memproses query relasional.
 */

const express = require('express');
const router = express.Router();
// Asumsi db adalah instansi database connection (mysql atau sqlite3) yang sudah ada di server Anda
// const db = require('./db-config'); 

// ==========================================
// 1. SISTEM KASBON (CATATAN UTANG) ENDPOINTS
// ==========================================

// Mendapatkan daftar pelanggan kasbon
router.get('/pelanggan', (req, res) => {
  const query = 'SELECT * FROM pelanggan ORDER BY nama ASC';
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// Menambah pelanggan baru
router.post('/pelanggan', (req, res) => {
  const { nama, telepon } = req.body;
  const query = 'INSERT INTO pelanggan (nama, telepon, total_utang) VALUES (?, ?, 0)';
  db.query(query, [nama, telepon], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.status(201).json({ id: result.insertId, nama, telepon, total_utang: 0 });
  });
});

// Mendapatkan riwayat transaksi utang/cicilan berdasarkan id_pelanggan
router.get('/kasbon/:id_pelanggan', (req, res) => {
  const { id_pelanggan } = req.params;
  const query = 'SELECT * FROM transaksi_utang WHERE id_pelanggan = ? ORDER BY tanggal DESC';
  db.query(query, [id_pelanggan], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// Menambah transaksi kasbon (utang atau cicilan)
// Transaksi ini akan memperbarui total_utang pelanggan secara otomatis dengan struktur transaksi (ACID)
router.post('/kasbon', (req, res) => {
  const { id_pelanggan, tipe, jumlah, keterangan } = req.body;
  
  if (!id_pelanggan || !tipe || !jumlah) {
    return res.status(400).json({ error: 'Data tidak lengkap' });
  }

  // Mulai transaksi database
  db.beginTransaction((err) => {
    if (err) return res.status(500).json({ error: err.message });

    // 1. Simpan riwayat transaksi kasbon
    const insQuery = 'INSERT INTO transaksi_utang (id_pelanggan, tipe, jumlah, keterangan) VALUES (?, ?, ?, ?)';
    db.query(insQuery, [id_pelanggan, tipe, jumlah, keterangan], (err, result) => {
      if (err) {
        return db.rollback(() => {
          res.status(500).json({ error: err.message });
        });
      }

      // 2. Update saldo utang di tabel pelanggan
      // Jika tipe = utang, tambahkan saldo. Jika tipe = cicilan, kurangkan saldo.
      const valDiff = tipe === 'utang' ? jumlah : -jumlah;
      const updQuery = 'UPDATE pelanggan SET total_utang = total_utang + ? WHERE id = ?';
      
      db.query(updQuery, [valDiff, id_pelanggan], (err) => {
        if (err) {
          return db.rollback(() => {
            res.status(500).json({ error: err.message });
          });
        }

        // Commit transaksi database
        db.commit((err) => {
          if (err) {
            return db.rollback(() => {
              res.status(500).json({ error: err.message });
            });
          }
          
          // Dapatkan data pelanggan yang terupdate untuk respon UI
          db.query('SELECT * FROM pelanggan WHERE id = ?', [id_pelanggan], (err, clientRes) => {
            res.status(201).json({
              message: 'Transaksi kasbon berhasil dicatat',
              pelanggan: clientRes ? clientRes[0] : null
            });
          });
        });
      });
    });
  });
});


// ==========================================
// 2. RIWAYAT PENJUALAN & ANALITIK LABA/RUGI
// ==========================================

// Menampilkan omzet harian beserta laba bersih (selisih HPP dan harga jual)
router.get('/analitik/laba-rugi', (req, res) => {
  const query = `
    SELECT 
      DATE(p.tanggal) AS tanggal,
      SUM(p.jumlah * b.harga) AS total_omzet,
      SUM(p.jumlah * (b.harga - IFNULL(b.hpp, 0))) AS laba_bersih,
      COUNT(DISTINCT p.no_nota) AS total_transaksi
    FROM penjualan p
    JOIN barang b ON p.no_barcode = b.no_barcode
    GROUP BY DATE(p.tanggal)
    ORDER BY DATE(p.tanggal) DESC
    LIMIT 30;
  `;
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});


// ==========================================
// 4. BACKUP & SINKRONISASI DATA (CLOUD)
// ==========================================

// Endpoint REST API untuk export/backup data SQLite lokal ke cloud/server
router.post('/backup/sync', (req, res) => {
  const { device_id, timestamp, tables } = req.body;
  
  if (!tables || typeof tables !== 'object') {
    return res.status(400).json({ error: 'Format data backup tidak valid.' });
  }

  // Melakukan backup secara terstruktur
  // Transaksi ini akan menyinkronkan data barang, pelanggan, transaksi_utang, dan penjualan dari lokal.
  db.beginTransaction((err) => {
    if (err) return res.status(500).json({ error: err.message });

    try {
      // 1. Sinkronisasi data Barang dari lokal (Upsert)
      if (tables.barang && Array.isArray(tables.barang)) {
        tables.barang.forEach((item) => {
          const q = `
            INSERT INTO barang (no_barcode, nama, harga, hpp, stok, kategori) 
            VALUES (?, ?, ?, ?, ?, ?) 
            ON DUPLICATE KEY UPDATE 
              nama = VALUES(nama), 
              harga = VALUES(harga), 
              hpp = VALUES(hpp),
              stok = VALUES(stok),
              kategori = VALUES(kategori);
          `;
          db.query(q, [item.no_barcode, item.nama, item.harga, item.hpp || 0, item.stok, item.kategori || 'Umum']);
        });
      }

      // 2. Sinkronisasi data Pelanggan
      if (tables.pelanggan && Array.isArray(tables.pelanggan)) {
        tables.pelanggan.forEach((item) => {
          const q = `
            INSERT INTO pelanggan (id, nama, telepon, total_utang) 
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE 
              nama = VALUES(nama), 
              telepon = VALUES(telepon), 
              total_utang = VALUES(total_utang);
          `;
          db.query(q, [item.id, item.nama, item.telepon, item.total_utang]);
        });
      }

      // Commit semua perubahan backup
      db.commit((err) => {
        if (err) {
          return db.rollback(() => { res.status(500).json({ error: err.message }); });
        }
        res.json({
          status: 'success',
          message: 'Data backup lokal SQLite berhasil disinkronkan ke server cloud!',
          synced_at: new Date().toISOString()
        });
      });
    } catch (error) {
      db.rollback(() => {
        res.status(500).json({ error: error.message });
      });
    }
  });
});


// ==========================================
// 5. KATEGORI & FILTER BARANG
// ==========================================

// Mendapatkan semua kategori yang unik dari inventori
router.get('/kategori', (req, res) => {
  const query = 'SELECT DISTINCT IFNULL(kategori, "Umum") AS kategori FROM barang ORDER BY kategori ASC';
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const categories = results.map(row => row.kategori);
    res.json(categories);
  });
});

// Mendapatkan barang berdasarkan kategori
router.get('/barang/kategori/:kategori', (req, res) => {
  const { kategori } = req.params;
  const query = 'SELECT * FROM barang WHERE kategori = ? ORDER BY nama ASC';
  db.query(query, [kategori], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

module.exports = router;
