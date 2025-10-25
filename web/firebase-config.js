const firebaseConfig = {
  apiKey: "AIzaSyB2YZHZwvthIYmp7ryQyFZabSipghaCkhc",
  authDomain: "rkbillsoft.firebaseapp.com",
  projectId: "rkbillsoft",
  storageBucket: "rkbillsoft.firebasestorage.app",
  messagingSenderId: "123295930773",
  appId: "1:123295930773:web:731b098f502063baa5be9c",
  measurementId: "G-JTH0J28GRR"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);