require("dotenv").config();
const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");
const path = require("path");
const fs = require("fs");

const app = express();

// ✅ Middleware - Render Compatible
app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// ✅ Render Uploads Static
app.use('/uploads', express.static('uploads'));
app.use('/uploads', express.static('/tmp/uploads'));

// MongoDB Atlas Connection
mongoose.connect(process.env.MONGODB_URI || process.env.MONGO_URL)
  .then(() => console.log('✅ MongoDB Connected'))
  .catch(err => console.error('❌ MongoDB Error:', err));

// 🔥 ROUTES - Perfect Structure!
app.use("/api/auth", require("./routes/auth"));           // तुम्हारा auth.js (signup/login/otp)
app.use("/api/itinerary", require("./routes/itinerary")); // itinerary upload/list

// Health check
app.get('/', (req, res) => res.json({
  message: '🚀 Akshay Travels LIVE!',
  endpoints: ['/api/auth/login', '/api/itinerary/upload']
}));

// Test endpoint
app.get('/api/test', (req, res) => res.json({ status: 'Server LIVE ✅' }));

// 404 handler
app.use('*', (req, res) => res.status(404).json({ error: 'Not found' }));

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server: ${PORT}`);
  console.log(`✅ Render LIVE!`);
  console.log(`📱 Auth: /api/auth/login`);
  console.log(`📁 Upload: /api/itinerary/upload`);
});
