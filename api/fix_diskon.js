const mysql = require("mysql");
require("dotenv").config();

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 3306,
});

db.connect((err) => {
  if (err) throw err;
  
  // Create a temporary table or just do an update with a join
  // To keep only the first diskon and pajak for each no_nota
  
  const sql = `
    UPDATE penjualan p
    JOIN (
      SELECT MIN(id) as first_id
      FROM penjualan
      GROUP BY no_nota
    ) first_items ON p.id != first_items.first_id AND p.no_nota = (SELECT no_nota FROM penjualan p2 WHERE p2.id = first_items.first_id LIMIT 1)
    SET p.diskon = 0, p.pajak = 0
  `;
  
  // Wait, the inner join is simpler:
  const sql2 = `
    UPDATE penjualan p
    LEFT JOIN (
      SELECT no_nota, MIN(id) as first_id
      FROM penjualan
      GROUP BY no_nota
    ) f ON p.id = f.first_id
    SET p.diskon = 0, p.pajak = 0
    WHERE f.first_id IS NULL;
  `;
  
  db.query(sql2, (err, result) => {
    if (err) {
      console.log("Error fixing data:", err.message);
    } else {
      console.log("Successfully fixed duplicated diskon/pajak. Rows affected:", result.affectedRows);
    }
    process.exit();
  });
});
