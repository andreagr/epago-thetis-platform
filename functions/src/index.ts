import * as functions from "firebase-functions";
const mysql = require('mysql2/promise');

/*exports.logData = functions.https.onRequest((req, res) => {
    // Log the received data to the console
    console.log('Received data:', req.body);

    // Optionally, you can return a response
    res.status(200).send({ message: 'Data logged successfully!' });
});*/

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
      // Parse the JSON body
      let jsonData = JSON.parse(req.body);

      const sensor1Data = jsonData.sensor1;
      const sensor2Data = jsonData.sensor2;
      jsonData.topic = "test/topic"

      // Obtain the current Unix timestamp
      //const timestamp = Date..toLocaleString(); // Unix timestamp in seconds
      let date = new Date();
      const datetime = date.toISOString().split('T')[0] + ' '
        + date.toTimeString().split(' ')[0];
      const connection = await pool.getConnection();

      // Insert data for sensor 1
      await connection.query('INSERT INTO sensor_data (sensor_name, temperature, humidity, topic, timestamp) VALUES (?,?,?,?,?)', 
          ['sensor1', sensor1Data.t, sensor1Data.h, jsonData.topic, datetime]);
      
      // Insert data for sensor 2
      await connection.query('INSERT INTO sensor_data (sensor_name, temperature, humidity, topic, timestamp) VALUES (?,?,?,?,?)', 
          ['sensor2', sensor2Data.t, sensor2Data.h, jsonData.topic, datetime]);

      connection.release();

      res.status(200).send('Data written to database successfully');
  } catch (error) {
      console.log(req.body);
      console.error('Error writing to database:', error);
      res.status(500).send(error);
  }
});