import * as functions from "firebase-functions";

// // Start writing functions
// // https://firebase.google.com/docs/functions/typescript
//
// export const helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
exports.logData = functions.https.onCall((data, context) => {
    // Log the received data to the console
    console.log('Received data:', data);

    // Optionally, you can return a response
    return { message: 'Data logged successfully!' };
});