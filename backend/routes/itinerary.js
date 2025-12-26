const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const csv = require("csv-parser");
const fs = require("fs");
const Itinerary = require("../models/Itinerary");
const Traveler = require("../models/Traveler");
const auth = require("../middleware/auth");

// ✅ FIXED: Render + Local storage!
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // 🔥 RENDER FIX: /tmp/uploads (Writable!)
    const dest = process.env.NODE_ENV === 'production'
      ? '/tmp/uploads/'
      : './uploads/';

    // Folder auto-create
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }

    console.log(`📁 Saving to: ${dest}`);
    cb(null, dest);
  },
  filename: (req, file, cb) =>
    cb(null, `itinerary-${Date.now()}-${Math.random().toString(36).substr(2, 9)}${path.extname(file.originalname)}`),
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = [".pdf", ".csv", ".json"];
    const extname = path.extname(file.originalname).toLowerCase();
    if (allowedTypes.includes(extname)) {
      cb(null, true);
    } else {
      cb(new Error("Only PDF, CSV, JSON allowed"));
    }
  },
});

// =====================================================
// ✅ FIXED UPLOAD ROUTE (Error handling + Render ready!)
router.post("/upload", auth, (req, res, next) => {
  upload.single("file")(req, res, (err) => {
    if (err) {
      console.error('💥 MULTER ERROR:', err);
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return res.status(400).json({ status: false, message: 'File बहुत बड़ी है (10MB max)' });
        }
      }
      return res.status(400).json({ status: false, message: err.message });
    }
    next();
  });
}, async (req, res) => {
  // बाकी code same रहेगा...
  try {
    if (!req.file) {
      return res.status(400).json({ status: false, message: "No file uploaded" });
    }
    console.log('✅ File received:', req.file.filename, req.file.size, 'bytes');

    // बाकी upload logic same...
    let days = [];
    if (req.file.mimetype.includes("csv")) {
      // CSV parsing same...
    }

    const itinerary = new Itinerary({
      // same fields...
      fileUrl: `/uploads/${req.file.filename}`,  // ✅ Same URL serving
      // rest same...
    });

    await itinerary.save();
    console.log(`✅ ITINERARY UPLOADED: ${req.body.title}`);

    res.json({
      status: true,
      message: `Itinerary uploaded! ${days.length > 0 ? `(${days.length} days parsed)` : ''}`,
      item: { /* same response */ }
    });
  } catch (error) {
    console.error("💥 Upload error:", error);
    res.status(500).json({ status: false, message: error.message });
  }
});

// बाकी routes same रहेंगे...
module.exports = router;
