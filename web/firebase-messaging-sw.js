importScripts(
  'https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js'
);

importScripts(
  'https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js'
);

firebase.initializeApp({
  apiKey: 'AIzaSyBJ5nQJj7re84he93bDxmMAoyxH32ldi5U',
  authDomain: 'classcue-77029.firebaseapp.com',
  projectId: 'classcue-77029',
  storageBucket: 'classcue-77029.firebasestorage.app',
  messagingSenderId: '768778503722',
  appId: '1:768778503722:web:1e598c24f8d996e4086553',
  measurementId: 'G-QFDJTXSVLZ',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log(
    '[firebase-messaging-sw.js] Background message received:',
    payload
  );
});