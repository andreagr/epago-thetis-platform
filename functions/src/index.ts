import * as functions from "firebase-functions";

const mysql = require('mysql2/promise');
const admin = require('firebase-admin');

admin.initializeApp();

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


// TODO
// We need to save the deviceId for each message as well as the id of the single sensor that gives the reading
exports.writeJsonToDatabase = functions.https.onRequest(async (req, res) => {
  try {
    // Parse the JSON body
    let jsonData = req.body;//JSON.parse(req.body);

    const sensor1Data = jsonData.sensor1;
    const sensor2Data = jsonData.sensor2;
    jsonData.topic = ""

    // Obtain the current Unix timestamp
    //const timestamp = Date..toLocaleString(); // Unix timestamp in seconds
    let date = new Date();
    const datetime = date.toISOString().split('T')[0] + ' '
      + date.toTimeString().split(' ')[0];
    const connection = await pool.getConnection();

    // Insert data for sensor 1
    await connection.query('INSERT INTO sensor_data (deviceId, sensor_name, temperature, humidity, topic, timestamp) VALUES (?,?,?,?,?,?)',
      [jsonData.deviceId,'sensor1', sensor1Data.t, sensor1Data.h, jsonData.topic, datetime]);

    // Insert data for sensor 2
    await connection.query('INSERT INTO sensor_data (deviceId, sensor_name, temperature, humidity, topic, timestamp) VALUES (?,?,?,?,?,?)',
      [jsonData.deviceId, 'sensor2', sensor2Data.t, sensor2Data.h, jsonData.topic, datetime]);

    connection.release();

    res.status(200).send('Data written to database successfully');
  } catch (error) {
    console.log(req.body);
    console.error('Error writing to database:', error);
    res.status(500).send(error);
  }
});

exports.getDataByDateRange = functions.https.onRequest(async (req, res) => {
  const { startDate, endDate } = req.query;

  res.set("Access-Control-Allow-Origin", "*"); // you can also whitelist a specific domain like "http://127.0.0.1:4000"
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (!startDate || !endDate) {
    res.status(400).json({ error: 'Start date and end date are required' });
  }

  try {
    const [rows] = await pool.execute(
      'SELECT * FROM sensor_data WHERE timestamp BETWEEN ? AND ?',
      [startDate, endDate]
    );

    if (rows.length === 0) {
      res.status(204).json({ message: 'No data found for the specified date range' });
    }
    
    res.status(200).json({ data: rows });
  } catch (error) {
    console.error('Error querying database:', error);
    res.status(500).json({ error: 'Internal server error'});
  }
});

exports.registerNewSensor = functions.https.onRequest(async (req, res) => {
  // Check if the request method is POST
  if (req.method !== 'POST') {
       res.status(405).send('Method Not Allowed');
  }
  
  // Extracting data from the request body
  //const { deviceId, deviceOwnerId, placementId, placementNumber } = req.body;
  const { deviceId } = req.body;

  // Validate input data
  /*if (!deviceOwnerId || !placementId || typeof placementNumber !== 'number') {
       res.status(400).send('Invalid input data');
  }*/

  // Create a new document in the Firestore collection 'sensors'
  const sensorData = {
      deviceOwnerId: "ownerId",
      placementId: "placementId", //represent the cabinet in which it is places
      placementNumber: 1, // a number to represent the single device in case of multiple present in the same cabinet
      creationTimestamp: Date.now() // Automatically set server timestamp
  };

  try {
      const docRef = await admin.firestore().collection('devices').doc(deviceId).set(sensorData);
       res.status(201).send(`Sensor data saved with ID: ${docRef.id}`);
  } catch (error) {
      console.error('Error saving sensor data:', error);
       res.status(500).send('Error saving data');
  }
});

exports.loginUser = functions.https.onCall(async (data, context) => {
  const { email, password } = data;

  if (!email || !password) {
      throw new functions.https.HttpsError('invalid-argument', 'The function must be called with two arguments "email" and "password".');
  }

  try {
      // Use Firebase Admin SDK to verify the user's credentials
      const userRecord = await admin.auth().getUserByEmail(email);
      
      // Here we would typically check the password against a database or authentication service
      // However, Firebase Admin SDK does not support password verification directly.
      // You would need to implement a custom authentication method or use client-side auth.

      // For demonstration purposes, we will assume the password check is done on the client-side.
      // If successful, return user information.
      return { uid: userRecord.uid, email: userRecord.email };
  } catch (error) {
      if (error === 'auth/user-not-found') {
          throw new functions.https.HttpsError('not-found', 'No user found for this email.');
      } else if (error === 'auth/invalid-email') {
          throw new functions.https.HttpsError('invalid-argument', 'The provided email is not valid.');
      } else {
  
          throw new functions.https.HttpsError('internal', 'check logs');
      }
  }
});