import * as functions from "firebase-functions";
const mysql = require('mysql2/promise');

exports.logData = functions.https.onRequest((req, res) => {
    // Log the received data to the console
    console.log('Received data:', req.body);

    // Optionally, you can return a response
    res.status(200).send({ message: 'Data logged successfully!' });
});

const INSTANCE_CONNECTION_NAME = 'epago-b4676:us-central1:mqtt-db-test';

// Replace with your database credentials
const DB_USER = 'andrea';
const DB_PASS = "GomiSumitomo_1";
const DB_NAME = 'mqtt-data';

// Create a connection pool
const pool = mysql.createPool({
  user: DB_USER,
  password: DB_PASS,
  database: DB_NAME,
  socketPath: `/cloudsql/${INSTANCE_CONNECTION_NAME}`,
});

exports.writeJsonToDatabase = functions.https.onRequest(async (req, res) => {
  try {
    const jsonData = req.body; // Assuming JSON data is sent in the request body

    // Example: Assuming jsonData has fields 'name' and 'value'
    const { name, value } = jsonData;

    const connection = await pool.getConnection();
    await connection.query('INSERT INTO your_table_name (name, value) VALUES (?, ?)', [name, value]);
    connection.release();

    res.status(200).send('Data written to database successfully');
  } catch (error) {
    console.error('Error writing to database:', error);
    //res.status(500).send('Error writing to database');
    res.status(500).send(error);

  }
});