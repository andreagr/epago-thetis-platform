import * as functions from "firebase-functions";

exports.logPublishedData = functions.https.onRequest((req, res) => {
    // Log the received data to the console
    console.log('Received data:', req.body);

    // Optionally, you can return a response
    res.status(200).send({ message: 'Data logged successfully!' });
});