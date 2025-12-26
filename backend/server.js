const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const csv = require("csv-parser");
const fs = require("fs");
const Itinerary = require("../models/Itinerary");
const Traveler = require("../models/Traveler");
const auth = require("../middleware/auth");

// ✅ RENDER FIXED Storage!
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dest = process.env.NODE_ENV === 'production' ? '/tmp/uploads/' : './uploads/';
    if (!fs.existsSync(dest)) fs.mkdirSync(dest, { recursive: true });
    console.log(`📁 Saving to: ${dest}`);
    cb(null, dest);
  },
  filename: (req, file, cb) => {
    cb(null, `itinerary-${Date.now()}-${Math.random().toString(36).substr(2, 9)}${path.extname(file.originalname)}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    if (['.pdf', '.csv', '.json'].includes(ext)) cb(null, true);
    else cb(new Error("Only PDF, CSV, JSON allowed"));
  }
});

// ✅ UPLOAD (Multer error handling!)
router.post("/upload", auth, (req, res, next) => {
  upload.single("file")(req, res, (err) => {
    if (err) {
      console.error('💥 MULTER ERROR:', err);
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ status: false, message: 'File बहुत बड़ी है (10MB max)' });
      }
      return res.status(400).json({ status: false, message: err.message });
    }
    next();
  });
}, async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ status: false, message: "No file uploaded" });

    console.log('✅ File:', req.file.filename, req.file.size, 'bytes');

    let days = [];
    if (req.file.mimetype.includes("csv")) {
      days = await new Promise((resolve, reject) => {
        const results = [];
        fs.createReadStream(req.file.path)
          .pipe(csv())
          .on("data", data => results.push(data))
          .on("end", () => {
            days = results.slice(0, 7).map((row, i) => ({
              day: i + 1,
              title: row.activity || row.title || `Day ${i + 1}`,
              time: row.time || "09:00 AM",
              location: row.location || "TBD",
              description: row.description || "Details"
            }));
            resolve(days);
          })
          .on("error", reject);
      });
    }

    const itinerary = new Itinerary({
      title: req.body.title,
      userId: req.user.id,
      fileUrl: `/uploads/${req.file.filename}`,
      fileSize: req.file.size,
      fileType: req.file.mimetype,
      days,
      travelers: [],
      status: "draft"
    });

    await itinerary.save();
    console.log(`✅ UPLOADED: ${req.body.title}`);

    res.json({
      status: true,
      message: `Itinerary uploaded! ${days.length ? `(${days.length} days)` : ''}`,
      item: {
        id: itinerary._id,
        title: itinerary.title,
        days: days,
        fileUrl: itinerary.fileUrl
      }
    });
  } catch (error) {
    console.error("💥 Upload error:", error);
    res.status(500).json({ status: false, message: error.message });
  }
});

// ✅ GET Itineraries
router.get("/", auth, async (req, res) => {
  const itineraries = await Itinerary.find({ userId: req.user.id })
    .sort({ createdAt: -1 })
    .limit(50);
  res.json({ status: true, data: itineraries, count: itineraries.length });
});

// ✅ GET Single
router.get("/:id", auth, async (req, res) => {
  const itinerary = await Itinerary.findOne({ _id: req.params.id, userId: req.user.id }).populate("travelers");
  if (!itinerary) return res.status(404).json({ status: false, message: "Not found" });
  res.json({ status: true, data: itinerary });
});

// ✅ Add Traveler
router.post("/:id/travelers/add", auth, async (req, res) => {
  const { id } = req.params;
  const { name, phone, email, language = "en", isPrimary = false } = req.body;

  const traveler = new Traveler({
    itineraryId: id,
    userId: req.user.id,
    name: name.trim(),
    phone: phone.trim(),
    email: email?.trim() || null,
    language,
    isPrimary
  });

  await traveler.save();
  await Itinerary.findByIdAndUpdate(id, { $push: { travelers: traveler._id }, $inc: { travelerCount: 1 } });

  res.json({ status: true, message: "Traveler added!", data: traveler });
});

module.exports = router;
