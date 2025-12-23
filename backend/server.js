require("dotenv").config();
const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");
const path = require("path");
const fs = require("fs");

// ✅ ALL ROUTES (Phase 4 COMPLETE!)
const authRoutes = require("./routes/auth");
const itineraryRoutes = require("./routes/itinerary");
const chatbotRoutes = require("./routes/chatbot");
const notificationsRoutes = require("./routes/notifications");
const analyticsRoutes = require("./routes/analytics");

const app = express();

// ✅ CORS (Flutter Web + Mobile + Postman)
app.use(
  cors({
    origin: true,
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

// ✅ Body parsers (10MB files for CSV/PDF)
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// 📂 Uploads folder (CSV/PDF files)
const uploadsDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
  console.log("📁 uploads/ folder created");
}
app.use("/uploads", express.static(uploadsDir));

// ✅ STATIC FILES (Analytics Dashboard + Future assets)
app.use(express.static('public'));

// 🔥 HEALTH CHECK + API STATUS (Phase 4 Updated!)
app.get("/", (req, res) => {
  res.json({
    message: "🚀 Akshay Travels Backend - ALL PHASES COMPLETE! ✅",
    timestamp: new Date().toISOString(),
    version: "v2.1 - FULLSTACK PRODUCTION READY",
    routes: [
      "/api/auth → Login/Signup/OTP",
      "/api/itinerary → Upload/List/Add Travelers (CSV Parser)",
      "/api/chatbot → AI Chat (Mock → OpenAI Ready)",
      "/api/notifications → WhatsApp Sender (Twilio LIVE)",
      "/api/analytics → 📊 Dashboard Stats (Phase 4)",
      "/analytics.html → Web Analytics Dashboard"
    ],
    mongodb: mongoose.connection.readyState === 1 ? "✅ Connected" : "⏳ Connecting...",
    features: {
      auth: "✅ JWT + bcrypt",
      upload: "✅ Multer + CSV Parser",
      whatsapp: "✅ Twilio (Real + Mock)",
      analytics: "✅ Real MongoDB counts"
    },
    uploads: `http://192.168.1.5:3000/uploads`,
    flutter: `http://192.168.1.5:3000/api`,
    postman: "Bearer token from /api/auth/login"
  });
});

// 🛣️ ALL API ROUTES (COMPLETE!)
app.use("/api/auth", authRoutes);
app.use("/api/itinerary", itineraryRoutes);
app.use("/api/chatbot", chatbotRoutes);
app.use("/api/notifications", notificationsRoutes);
app.use("/api/analytics", analyticsRoutes);

// 404 Handler (Professional)
app.use("*", (req, res) => {
  res.status(404).json({
    error: "Route not found ❌",
    available: [
      "/api/auth",
      "/api/itinerary",
      "/api/chatbot",
      "/api/notifications",
      "/api/analytics",
      "/analytics.html"
    ],
    docs: "http://192.168.1.5:3000/"
  });
});

// 🚀 MONGODB CONNECTION + SERVER START
mongoose
  .connect(process.env.MONGO_URL)
  .then(() => {
    console.log("✅ MongoDB Connected: ai_travel DB");

    const PORT = 3000;  // 👈 FIXED PORT 3000 (NO CONFLICT!)
    const server = app.listen(PORT, '0.0.0.0', () => {
      console.log(`\n🚀 Server LIVE: http://192.168.1.5:${PORT}`);
      console.log(`📱 Flutter Mobile: http://192.168.1.5:${PORT}/api`);
      console.log(`🌐 Flutter Web: http://localhost:${PORT}`);
      console.log(`🔗 Health Check: http://192.168.1.5:${PORT}/`);
      console.log(`📊 Analytics API: http://192.168.1.5:${PORT}/api/analytics`);
      console.log(`📈 Web Dashboard: http://192.168.1.5:${PORT}/analytics.html`);
      console.log(`📂 File Uploads: http://192.168.1.5:${PORT}/uploads`);
      console.log(`✅ FEATURES LIVE:`);
      console.log(`   • Auth (Login/Signup/OTP)`);
      console.log(`   • CSV Parser + Timeline`);
      console.log(`   • Traveler Management`);
      console.log(`   • REAL WhatsApp (Twilio)`);
      console.log(`   • AI Chat (Mock Ready)`);
      console.log(`   • Analytics Dashboard`);
      console.log(`\n🎉 AKSHAY TRAVELS - MOBILE READY! 🚀✈️📱`);
    });

    // 🛡️ Graceful shutdown
    process.on('SIGINT', async () => {
      console.log('\n👋 Graceful shutdown started...');
      await mongoose.connection.close();
      server.close(() => {
        console.log('✅ Server stopped cleanly');
        process.exit(0);
      });
    });

    process.on('SIGTERM', async () => {
      console.log('\n👋 SIGTERM received...');
      await mongoose.connection.close();
      server.close(() => {
        console.log('✅ Server stopped');
        process.exit(0);
      });
    });
  })
  .catch((err) => {
    console.error("❌ MongoDB Connection FAILED:", err.message);
    console.log("💡 Fix: Check .env → MONGO_URL=mongodb://127.0.0.1:27017/ai_travel");
    process.exit(1);
  });

module.exports = app;
