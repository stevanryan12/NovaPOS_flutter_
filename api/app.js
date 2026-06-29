// Import dependencies
const express = require("express");
const bodyParser = require("body-parser");
const mysql = require("mysql");
const cors = require("cors");
require("dotenv").config();

// Create Express app
const app = express();
app.use(cors());
const port = 3000;

// Middleware
app.use(bodyParser.json());

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 3306,
});

// Connect to MySQL
db.connect((err) => {
  if (err) {
    console.error("Database connection failed:", err);
    process.exit(1);
  }
  console.log("Connected to MySQL database.");
});

// Routes for 'barang'
app.get("/barang", (req, res) => {
  db.query("SELECT * FROM barang", (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// Endpoint untuk mengambil semua kategori unik
app.get("/kategori", (req, res) => {
  db.query("SELECT DISTINCT kategori FROM barang", (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const listKategori = results
      .map((r) => r.kategori)
      .filter((k) => k !== null && k !== "");
    
    // Pastikan minimal ada kategori 'Umum'
    if (!listKategori.includes("Umum")) {
      listKategori.unshift("Umum");
    }
    res.json(listKategori);
  });
});

// Endpoint untuk menyaring barang berdasarkan kategori
app.get("/barang/kategori/:kategori", (req, res) => {
  const { kategori } = req.params;
  db.query("SELECT * FROM barang WHERE kategori = ?", [kategori], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

app.get("/barang/:no_barcode", (req, res) => {
  const { no_barcode } = req.params;

  db.query(
    "SELECT * FROM barang WHERE no_barcode = ?",
    [no_barcode],
    (err, results) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      if (results.length > 0) {
        res.json({ message: "Barang ditemukan", data: results[0] });
      } else {
        res.status(404).json({ message: "Barang tidak ada" });
      }
    }
  );
});

app.post("/barang", (req, res) => {
  const { no_barcode, nama, harga, harga_modal, stok, kategori } = req.body;
  db.query(
    "INSERT INTO barang SET ?",
    { no_barcode, nama, harga, harga_modal: harga_modal || 0, stok, kategori: kategori || 'Umum' },
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      res
        .status(201)
        .json({ message: "Barang added successfully", id: results.insertId });
    }
  );
});

app.put("/barang/:no_barcode", (req, res) => {
  const { no_barcode } = req.params;
  const { nama, harga, harga_modal, stok, kategori } = req.body;
  db.query(
    "UPDATE barang SET ? WHERE no_barcode = ?",
    [{ nama, harga, harga_modal: harga_modal || 0, stok, kategori: kategori || 'Umum' }, no_barcode],
    (err) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ message: "Barang updated successfully" });
    }
  );
});

app.delete("/barang/:no_barcode", (req, res) => {
  const { no_barcode } = req.params;
  db.query("DELETE FROM barang WHERE no_barcode = ?", [no_barcode], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Barang deleted successfully" });
  });
});

// Routes for 'supplier'
app.get("/supplier", (req, res) => {
  db.query("SELECT * FROM supplier", (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

app.post("/supplier", (req, res) => {
  const { id_sup, nama, alamat, no_hp } = req.body;
  db.query(
    "INSERT INTO supplier SET ?",
    { id_sup, nama, alamat, no_hp },
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      res
        .status(201)
        .json({ message: "Supplier added successfully", id: results.insertId });
    }
  );
});

app.put("/supplier/:id_sup", (req, res) => {
  const { id_sup } = req.params;
  const { nama, alamat, no_hp } = req.body;
  db.query(
    "UPDATE supplier SET ? WHERE id_sup = ?",
    [{ nama, alamat, no_hp }, id_sup],
    (err) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ message: "Supplier updated successfully" });
    }
  );
});

app.delete("/supplier/:id_sup", (req, res) => {
  const { id_sup } = req.params;
  db.query("DELETE FROM supplier WHERE id_sup = ?", [id_sup], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Supplier deleted successfully" });
  });
});

// Routes for 'penjualan'
app.get("/penjualan", (req, res) => {
  db.query(
    "SELECT * FROM penjualan JOIN barang ON penjualan.no_barcode = barang.no_barcode ORDER BY penjualan.tanggal DESC",
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(results);
    }
  );
});

app.post("/penjualan", (req, res) => {
  const { no_nota, no_barcode, jumlah, diskon, pajak, id_pelanggan } = req.body;

  // Periksa apakah barang ada dan stok mencukupi
  db.query(
    "SELECT stok, harga FROM barang WHERE no_barcode = ?",
    [no_barcode],
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });

      if (results.length === 0) {
        return res.status(404).json({ error: "Barang tidak ditemukan" });
      }

      const stokSaatIni = results[0].stok;

      if (stokSaatIni < jumlah) {
        return res.status(400).json({ error: "Stok tidak mencukupi" });
      }

      const stokBaru = stokSaatIni - jumlah;
      db.query(
        "UPDATE barang SET stok = ? WHERE no_barcode = ?",
        [stokBaru, no_barcode],
        (err) => {
          if (err) return res.status(500).json({ error: err.message });

          // Simpan transaksi penjualan dengan tanggal, diskon, pajak, id_pelanggan
          const tanggal = new Date().toISOString().slice(0, 19).replace('T', ' '); // YYYY-MM-DD HH:mm:ss
          db.query(
            "INSERT INTO penjualan SET ?",
            { no_nota, no_barcode, jumlah, tanggal, diskon: diskon || 0, pajak: pajak || 0, id_pelanggan: id_pelanggan || null },
            (err, insertResults) => {
              if (err) return res.status(500).json({ error: err.message });
              
              // Tambahkan poin ke pelanggan jika ada
              if (id_pelanggan) {
                const harga = results[0].harga;
                const totalHarga = harga * jumlah;
                const poinDidapat = Math.floor(totalHarga / 1000); // 1 poin setiap Rp 1.000 belanja
                
                if (poinDidapat > 0) {
                  db.query(
                    "UPDATE pelanggan SET poin = poin + ? WHERE id = ?",
                    [poinDidapat, id_pelanggan],
                    (err) => {
                      if (err) console.error("Error updating points:", err);
                    }
                  );
                }
              }

              res.status(201).json({
                message: "Penjualan added successfully",
                id: insertResults.insertId,
              });
            }
          );
        }
      );
    }
  );
});

app.put("/penjualan/:no_nota", (req, res) => {
  const { no_nota } = req.params;
  const { no_barcode, jumlah } = req.body;
  db.query(
    "UPDATE penjualan SET ? WHERE no_nota = ?",
    [{ no_barcode, jumlah }, no_nota],
    (err) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ message: "Penjualan updated successfully" });
    }
  );
});

app.delete("/penjualan/:no_nota", (req, res) => {
  const { no_nota } = req.params;
  db.query("DELETE FROM penjualan WHERE no_nota = ?", [no_nota], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Penjualan deleted successfully" });
  });
});

// Routes for 'analitik'
app.get("/analitik/laba-rugi", (req, res) => {
  const query = `
    SELECT 
      DATE(p.tanggal) as tanggal,
      COUNT(DISTINCT p.no_nota) as total_transaksi,
      SUM(p.jumlah * b.harga) as total_omzet,
      SUM(p.jumlah * b.harga_modal) as total_modal,
      SUM(p.jumlah * (b.harga - b.harga_modal)) as laba_bersih
    FROM penjualan p
    JOIN barang b ON p.no_barcode = b.no_barcode
    WHERE p.tanggal IS NOT NULL
    GROUP BY DATE(p.tanggal)
    ORDER BY DATE(p.tanggal) DESC
    LIMIT 30
  `;
  
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// File signin
app.post('/login', (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: 'Username dan password wajib diisi' });
  }

  db.query(
    'SELECT * FROM signin WHERE username = ? AND password = ?', [username, password],
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });

      if (results.length === 0) {
        return res.status(401).json({ error: 'Username atau password salah' });
      }

      res.json({ message: 'Login berhasil', user: results[0] });
    }
  );
});

// ==========================================
// FITUR KASBON & UTANG (DATABASE INTEGRATION)
// ==========================================
app.get("/pelanggan", (req, res) => {
  db.query("SELECT * FROM pelanggan ORDER BY nama ASC", (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

app.post("/pelanggan", (req, res) => {
  const { nama, telepon } = req.body;
  db.query(
    "INSERT INTO pelanggan (nama, telepon, total_utang) VALUES (?, ?, 0)",
    [nama, telepon],
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      res.status(201).json({ 
        message: "Pelanggan added successfully", 
        id: results.insertId,
        nama,
        telepon,
        total_utang: 0
      });
    }
  );
});

app.get("/kasbon/:id_pelanggan", (req, res) => {
  const { id_pelanggan } = req.params;
  db.query(
    "SELECT * FROM transaksi_utang WHERE id_pelanggan = ? ORDER BY tanggal DESC",
    [id_pelanggan],
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(results);
    }
  );
});

app.post("/kasbon", (req, res) => {
  const { id_pelanggan, tipe, jumlah, keterangan } = req.body;
  
  if (!id_pelanggan || !tipe || !jumlah) {
    return res.status(400).json({ error: 'Data tidak lengkap' });
  }
  
  db.beginTransaction((err) => {
    if (err) return res.status(500).json({ error: err.message });
    
    db.query(
      "INSERT INTO transaksi_utang (id_pelanggan, tipe, jumlah, keterangan) VALUES (?, ?, ?, ?)",
      [id_pelanggan, tipe, jumlah, keterangan],
      (err, results) => {
        if (err) {
          return db.rollback(() => {
            res.status(500).json({ error: err.message });
          });
        }
        
        const valDiff = tipe === 'utang' ? jumlah : -jumlah;
        db.query(
          "UPDATE pelanggan SET total_utang = total_utang + ? WHERE id = ?",
          [valDiff, id_pelanggan],
          (updateErr) => {
            if (updateErr) {
              return db.rollback(() => {
                res.status(500).json({ error: updateErr.message });
              });
            }
            
            db.commit((commitErr) => {
              if (commitErr) {
                return db.rollback(() => {
                  res.status(500).json({ error: commitErr.message });
                });
              }
              
              db.query("SELECT * FROM pelanggan WHERE id = ?", [id_pelanggan], (err, clientRes) => {
                res.status(201).json({
                  message: "Transaksi kasbon added successfully",
                  id_utang: results.insertId,
                  pelanggan: clientRes ? clientRes[0] : null
                });
              });
            });
          }
        );
      }
    );
  });
});

// ==========================================
// FITUR RIWAYAT PENJUALAN & LABA/RUGI (ANALITIK)
// ==========================================
app.get("/analitik/laba-rugi", (req, res) => {
  const query = `
    SELECT 
      tanggal,
      SUM(omzet_nota - diskon_nota + pajak_nota) as total_omzet,
      SUM(laba_kotor_nota - diskon_nota) as laba_bersih,
      COUNT(no_nota) as total_transaksi
    FROM (
        SELECT 
          p.no_nota,
          DATE_FORMAT(p.tanggal, '%Y-%m-%d') as tanggal,
          SUM(p.jumlah * b.harga) as omzet_nota,
          SUM(p.jumlah * (b.harga - IFNULL(b.hpp, 0))) as laba_kotor_nota,
          MAX(p.diskon) as diskon_nota,
          MAX(p.pajak) as pajak_nota
        FROM penjualan p
        JOIN barang b ON p.no_barcode = b.no_barcode
        GROUP BY p.no_nota, DATE_FORMAT(p.tanggal, '%Y-%m-%d')
    ) summary
    GROUP BY tanggal
    ORDER BY tanggal DESC
    LIMIT 30;
  `;
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// ==========================================
// FITUR BACKUP & SINKRONISASI DATA (CLOUD)
// ==========================================
app.post("/backup/sync", (req, res) => {
  const { tables } = req.body;
  if (!tables) {
    return res.status(400).json({ error: "Missing tables data in payload" });
  }

  const { barang, pelanggan } = tables;
  let errors = [];
  let syncPromises = [];

  // Sinkronisasi barang
  if (barang && barang.length > 0) {
    barang.forEach(item => {
      const { no_barcode, nama, harga, hpp, stok, kategori } = item;
      const sql = `
        INSERT INTO barang (no_barcode, nama, harga, hpp, stok, kategori)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          nama = VALUES(nama),
          harga = VALUES(harga),
          hpp = VALUES(hpp),
          stok = VALUES(stok),
          kategori = VALUES(kategori)
      `;
      syncPromises.push(new Promise((resolve) => {
        db.query(sql, [no_barcode, nama, harga, hpp || 0, stok, kategori || 'Umum'], (err) => {
          if (err) errors.push(`Barang error (${no_barcode}): ${err.message}`);
          resolve();
        });
      }));
    });
  }

  // Sinkronisasi pelanggan
  if (pelanggan && pelanggan.length > 0) {
    pelanggan.forEach(c => {
      const { id, nama, telepon, total_utang } = c;
      const sql = `
        INSERT INTO pelanggan (id, nama, telepon, total_utang)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          nama = VALUES(nama),
          telepon = VALUES(telepon),
          total_utang = VALUES(total_utang)
      `;
      syncPromises.push(new Promise((resolve) => {
        db.query(sql, [id, nama, telepon, total_utang || 0], (err) => {
          if (err) errors.push(`Pelanggan error (${id}): ${err.message}`);
          resolve();
        });
      }));
    });
  }

  Promise.all(syncPromises).then(() => {
    if (errors.length > 0) {
      res.status(500).json({ 
        message: "Sinkronisasi cloud selesai dengan beberapa error", 
        errors, 
        synced_at: new Date() 
      });
    } else {
      res.json({ 
        message: "Sinkronisasi cloud berhasil diselesaikan sepenuhnya.", 
        synced_at: new Date() 
      });
    }
  });
});

// ==========================================
// FITUR PELANGGAN (MEMBERSHIP / CRM)
// ==========================================
app.get("/pelanggan", (req, res) => {
  db.query("SELECT * FROM pelanggan ORDER BY nama ASC", (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

app.post("/pelanggan", (req, res) => {
  const { nama, no_hp, telepon } = req.body;
  const noHpToSave = telepon || no_hp;
  db.query("INSERT INTO pelanggan SET ?", { nama, telepon: noHpToSave, poin: 0 }, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.status(201).json({ message: "Pelanggan added successfully", id: results.insertId });
  });
});

app.put("/pelanggan/:id", (req, res) => {
  const { id } = req.params;
  const { nama, no_hp, telepon } = req.body;
  const noHpToSave = telepon || no_hp;
  db.query("UPDATE pelanggan SET nama = ?, telepon = ? WHERE id = ?", [nama, noHpToSave, id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Pelanggan updated successfully" });
  });
});

app.put("/pelanggan/:id/potong-poin", (req, res) => {
  const { id } = req.params;
  const { poin_dipotong } = req.body;
  db.query(
    "UPDATE pelanggan SET poin = GREATEST(0, poin - ?) WHERE id = ?",
    [poin_dipotong || 0, id],
    (err) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ message: "Points deducted successfully" });
    }
  );
});

app.delete("/pelanggan/:id", (req, res) => {
  const { id } = req.params;
  db.query("DELETE FROM pelanggan WHERE id = ?", [id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: "Pelanggan deleted successfully" });
  });
});

// ==========================================
// FITUR SHIFT KASIR
// ==========================================
app.get("/shift/status", (req, res) => {
  db.query("SELECT * FROM shift_kasir WHERE status = 'BUKA' ORDER BY id DESC LIMIT 1", (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results.length > 0) {
      res.json({ active: true, data: results[0] });
    } else {
      res.json({ active: false });
    }
  });
});

app.post("/shift/buka", (req, res) => {
  const { nama_kasir, modal_awal } = req.body;
  const waktu_buka = new Date().toISOString().slice(0, 19).replace('T', ' ');
  db.query(
    "INSERT INTO shift_kasir (nama_kasir, modal_awal, waktu_buka, status) VALUES (?, ?, ?, 'BUKA')", 
    [nama_kasir, modal_awal, waktu_buka], 
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      res.status(201).json({ message: "Shift opened successfully", id: results.insertId });
    }
  );
});

app.post("/shift/tutup/:id", (req, res) => {
  const { id } = req.params;
  // Calculate total_penjualan during this shift
  db.query("SELECT waktu_buka, modal_awal FROM shift_kasir WHERE id = ?", [id], (err, shiftRes) => {
    if (err || shiftRes.length === 0) return res.status(500).json({ error: "Shift not found" });
    const waktu_buka = shiftRes[0].waktu_buka;
    const modal_awal = parseFloat(shiftRes[0].modal_awal);

    // Sum penjualan
    db.query(
      "SELECT SUM(p.jumlah * b.harga) as total_penjualan FROM penjualan p JOIN barang b ON p.no_barcode = b.no_barcode WHERE p.tanggal >= ?", 
      [waktu_buka], 
      (err, pRes) => {
        let total_penjualan = 0;
        if (!err && pRes.length > 0 && pRes[0].total_penjualan) {
          total_penjualan = parseFloat(pRes[0].total_penjualan);
        }
        
        const total_uang_di_laci = modal_awal + total_penjualan;
        const waktu_tutup = new Date().toISOString().slice(0, 19).replace('T', ' ');
        
        db.query(
          "UPDATE shift_kasir SET total_penjualan = ?, total_uang_di_laci = ?, waktu_tutup = ?, status = 'TUTUP' WHERE id = ?",
          [total_penjualan, total_uang_di_laci, waktu_tutup, id],
          (err) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ message: "Shift closed successfully", total_penjualan, total_uang_di_laci });
          }
        );
      }
    );
  });
});

// Start server
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
