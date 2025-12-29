const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const csv = require("csv-parser");
const fs = require("fs");
const mongoose = require("mongoose");
const Itinerary = require("../models/Itinerary");
const Traveler = require("../models/Traveler");
const auth = require("../middleware/auth");

// ✅ Multer Storage (SAME)
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

// 🔥 FIXED UPLOAD - SIMPLIFIED (NO CRASH!)
router.post("/upload", auth, upload.single("file"), async (req, res) => {
  try {
    console.log('📤 REQ.BODY:', req.body);
    console.log('👤 USER.ID:', req.user.id);
    console.log('📁 FILE:', req.file?.filename);

    if (!req.file) {
      return res.status(400).json({ status: false, message: "No file uploaded" });
    }

    const { title, destination, startDate, endDate, travelerType, description } = req.body;
    const cleanTitle = title?.trim() || `Trip ${new Date().toLocaleDateString()}`;

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

    fs.unlinkSync(req.file.path);

    const itinerary = new Itinerary({
      title: cleanTitle,
      destination: destination || "Multiple Cities",
      startDate: startDate || null,
      endDate: endDate || null,
      travelerType: travelerType || "Solo",
      description: description || "",
      userId: req.user.id,
      fileUrl: `/uploads/${req.file.filename}`,
      fileSize: req.file.size,
      fileType: req.file.mimetype,
      days,
      travelers: [],
      status: "draft"
    });

    await itinerary.save();
    console.log(`✅ UPLOADED: ${cleanTitle} by user ${req.user.id}`);

    res.json({
      status: true,
      message: `Itinerary "${cleanTitle}" uploaded! ${days.length ? `(${days.length} days)` : ''}`,
      item: {
        id: itinerary._id,
        title: cleanTitle,
        destination: itinerary.destination,
        travelerCount: 0,
        days
      }
    });
  } catch (error) {
    console.error("💥 Upload error:", error);
    res.status(500).json({ status: false, message: error.message });
  }
});

// 🔥 FIXED GET - REAL TRAVELER COUNT!
router.get("/", auth, async (req, res) => {
  try {
    const itineraries = await Itinerary.find({ userId: req.user.id })
      .populate('travelers', 'name phone')
      .sort({ createdAt: -1 })
      .limit(50)
      .lean();

    const itinerariesWithCount = itineraries.map(itinerary => ({
      ...itinerary,
      travelerCount: itinerary.travelers?.length || 0,
      destination: itinerary.destination || 'Multiple Cities',
      startDate: itinerary.startDate || null,
      endDate: itinerary.endDate || null,
    }));

    console.log(`✅ ${itinerariesWithCount.length} itineraries with REAL traveler counts`);

    res.json({
      status: true,
      data: itinerariesWithCount,
      count: itinerariesWithCount.length
    });
  } catch (error) {
    console.error('💥 Get Itineraries Error:', error);
    res.status(500).json({ status: false, message: error.message });
  }
});

// ✅ GET Single
router.get("/:id", auth, async (req, res) => {
  try {
    const itinerary = await Itinerary.findOne({
      _id: req.params.id,
      userId: req.user.id
    }).populate("travelers", "name phone email");

    if (!itinerary) return res.status(404).json({ status: false, message: "Not found" });

    const itineraryWithCount = {
      ...itinerary.toObject(),
      travelerCount: itinerary.travelers?.length || 0
    };

    res.json({ status: true, data: itineraryWithCount });
  } catch (error) {
    console.error('💥 Get Single Error:', error);
    res.status(500).json({ status: false, message: error.message });
  }
});

// ✅ ADD TRAVELER
router.post('/:itineraryId/travelers/add', auth, async (req, res) => {
  try {
    console.log('🧑‍🤝‍🧑 ADD TRAVELER:', req.body);

    const { itineraryId, name, phone, email, language, isPrimary } = req.body;

    const itinerary = await Itinerary.findOne({
      _id: itineraryId,
      userId: req.user.id
    });
    if (!itinerary) {
      return res.status(404).json({ status: false, message: 'Itinerary not found' });
    }

    const traveler = new Traveler({
      itineraryId,
      userId: req.user.id,
      name,
      phone,
      email: email || null,
      language: language || 'en',
      isPrimary: isPrimary || false
    });
    await traveler.save();

    itinerary.travelers.push(traveler._id);
    await itinerary.save();

    console.log('✅ TRAVELER ADDED:', traveler.name);

    res.json({
      status: true,
      message: 'Traveler added successfully!',
      traveler: {
        id: traveler._id,
        name: traveler.name,
        phone: traveler.phone,
        isPrimary: traveler.isPrimary
      }
    });
  } catch (error) {
    console.error('💥 Add Traveler Error:', error);
    res.status(500).json({ status: false, message: error.message });
  }
});

// ✅ GET TRAVELERS
router.get('/:itineraryId/travelers', auth, async (req, res) => {
  try {
    const travelers = await Traveler.find({
      itineraryId: req.params.itineraryId,
      userId: req.user.id
    }).sort({ createdAt: -1 });

    res.json({
      status: true,
      data: travelers,
      count: travelers.length
    });
  } catch (error) {
    console.error('💥 Get Travelers Error:', error);
    res.status(500).json({ status: false, message: error.message });
  }
});

// ✅ DELETE TRAVELER
router.delete('/:itineraryId/travelers/:travelerId', auth, async (req, res) => {
  try {
    const { itineraryId, travelerId } = req.params;

    const traveler = await Traveler.findOne({
      _id: travelerId,
      itineraryId,
      userId: req.user.id
    });

    if (!traveler) {
      return res.status(404).json({ status: false, message: 'Traveler not found' });
    }

    await Traveler.deleteOne({ _id: travelerId });
    await Itinerary.updateOne(
      { _id: itineraryId, userId: req.user.id },
      { $pull: { travelers: travelerId } }
    );

    console.log('✅ TRAVELER DELETED:', travelerId);
    res.json({ status: true, message: 'Traveler deleted successfully' });
  } catch (error) {
    console.error('💥 Delete Traveler Error:', error);
    res.status(500).json({ status: false, message: error.message });
  }
});

module.exports = router;
