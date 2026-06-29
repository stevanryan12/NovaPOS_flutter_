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
  
  db.query("ALTER TABLE pelanggan ADD COLUMN poin INT DEFAULT 0", (err) => {
    if (err) {
      console.log("Column may already exist or error:", err.message);
    } else {
      console.log("Successfully added poin column!");
    }
    
    // Also let's fix the column name if they ever expected no_hp
    // Actually we don't need to if we fix app.js to use telepon
    process.exit();
  });
});
