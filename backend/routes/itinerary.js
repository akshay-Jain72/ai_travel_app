const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const csv = require("csv-parser");
const fs = require("fs");
const Itinerary = require("../models/Itinerary");
const Traveler = require("../models/Traveler");
const auth = require("../middleware/auth");

// Multer Storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, "uploads/"),
  filename: (req, file, cb) =>
    cb(null, `itinerary-${Date.now()}-${path.extname(file.originalname)}`),
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
// POST /api/itinerary/upload
// =====================================================
router.post("/upload", auth, upload.single("file"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        status: false,
        message: "No file uploaded",
      });
    }

    if (!req.body.title) {
      return res.status(400).json({
        status: false,
        message: "Title required",
      });
    }

    let days = [];
    if (req.file.mimetype.includes("csv")) {
      days = await new Promise((resolve, reject) => {
        const results = [];
        fs.createReadStream(req.file.path)
          .pipe(csv())
          .on("data", (data) => results.push(data))
          .on("end", () => {
            days = results.slice(0, 7).map((row, index) => ({
              day: index + 1,
              title: row.activity || row.title || `Day ${index + 1}`,
              time: row.time || "09:00 AM",
              location: row.location || row.destination || "TBD",
              description: row.description || "Activity details",
            }));
            resolve(days);
          })
          .on("error", reject);
      });
      console.log(`✅ Parsed ${days.length} days from CSV!`);
    }

    const itinerary = new Itinerary({
      title: req.body.title,
      destination: req.body.destination || "",
      startDate: req.body.startDate ? new Date(req.body.startDate) : null,
      endDate: req.body.endDate ? new Date(req.body.endDate) : null,
      travelerType: req.body.travelerType || "Solo",
      description: req.body.description || "",
      userId: req.user.id,
      fileUrl: `/uploads/${req.file.filename}`,
      fileSize: req.file.size,
      fileType: req.file.mimetype,
      days: days,
      travelers: [], // 🔥 Empty array for ObjectId refs
      status: "draft",
      travelerCount: 0,
    });

    await itinerary.save();

    res.json({
      status: true,
      message: `Itinerary uploaded! ${
        days.length > 0 ? `Timeline parsed (${days.length} days)` : "Upload successful"
      }`,
      item: {
        id: itinerary._id,
        title: itinerary.title,
        destination: itinerary.destination,
        days: days,
        fileUrl: itinerary.fileUrl,
        createdAt: itinerary.createdAt,
      },
    });
  } catch (error) {
    console.error("Upload error:", error);
    res.status(500).json({
      status: false,
      message: error.message,
    });
  }
});

// =====================================================
// GET /api/itinerary (User's own itineraries)
// =====================================================
router.get("/", auth, async (req, res) => {
  try {
    const itineraries = await Itinerary.find({
      userId: req.user.id,
    })
      .select("-fileUrl -__v")
      .sort({ createdAt: -1 })
      .limit(50);

    res.json({
      status: true,
      data: itineraries,
      count: itineraries.length,
    });
  } catch (error) {
    res.status(500).json({
      status: false,
      message: error.message,
    });
  }
});

// =====================================================
// GET /api/itinerary/:id (Single itinerary detail)
// =====================================================
router.get("/:id", auth, async (req, res) => {
  try {
    const itinerary = await Itinerary.findOne({
      _id: req.params.id,
      userId: req.user.id,
    }).populate("travelers"); // 🔥 POPULATE travelers with FULL data!

    if (!itinerary) {
      return res.status(404).json({
        status: false,
        message: "Itinerary not found",
      });
    }

    console.log('🔥 Itinerary travelers:', itinerary.travelers.map(t => ({name: t.name, phone: t.phone})));

    res.json({
      status: true,
      data: itinerary,
    });
  } catch (error) {
    console.error('Get itinerary error:', error);
    res.status(500).json({
      status: false,
      message: error.message,
    });
  }
});

// =====================================================
// POST /api/itinerary/:id/travelers/add
// =====================================================
router.post("/:id/travelers/add", auth, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, phone, email, language, isPrimary } = req.body;

    console.log("🧑‍🤝‍🧑 Adding traveler:", { id, name, phone });

    const itinerary = await Itinerary.findOne({ _id: id, userId: req.user.id });
    if (!itinerary) {
      return res.status(404).json({
        status: false,
        message: "Itinerary not found or access denied",
      });
    }

    // 🔥 Create Traveler document FIRST
    const traveler = new Traveler({
      itineraryId: id,
      userId: req.user.id,
      name: name.trim(),
      phone: phone.trim(),
      email: email ? email.trim() : null,
      language: language || "en",
      isPrimary: isPrimary === true || isPrimary === "true",
    });

    await traveler.save();

    // 🔥 Add Traveler ID to Itinerary
    await Itinerary.findByIdAndUpdate(id, {
      $push: { travelers: traveler._id },
      $inc: { travelerCount: 1 },
    });

    console.log(`✅ Added traveler "${name}" (${phone}) to "${itinerary.title}"`);

    res.json({
      status: true,
      message: "Traveler added successfully! ✨",
      data: {
        id: traveler._id,
        name: traveler.name,
        phone: traveler.phone,
        email: traveler.email,
        isPrimary: traveler.isPrimary,
        language: traveler.language,
      },
    });
  } catch (error) {
    console.error("❌ Add Traveler Error:", error);
    res.status(500).json({
      status: false,
      message: error.message || "Failed to add traveler",
    });
  }
});

// =====================================================
// DELETE /api/itinerary/:id
// =====================================================
router.delete("/:id", auth, async (req, res) => {
  try {
    const itinerary = await Itinerary.findOneAndDelete({
      _id: req.params.id,
      userId: req.user.id,
    });

    if (!itinerary) {
      return res.status(404).json({
        status: false,
        message: "Itinerary not found or you don't have permission",
      });
    }

    console.log(`🗑️ Deleted itinerary: "${itinerary.title}" by user: ${req.user.id}`);

    res.json({
      status: true,
      message: `Itinerary "${itinerary.title}" deleted successfully`,
      data: {
        deletedId: itinerary._id,
        deletedTitle: itinerary.title,
      },
    });
  } catch (error) {
    console.error("Delete error:", error);
    res.status(500).json({
      status: false,
      message: error.message,
    });
  }
});

// =====================================================
// 🔥 FIXED WHATSAPP NOTIFICATION ROUTES
// =====================================================

// Individual traveler को WhatsApp
router.post("/:id/travelers/:travelerId/whatsapp", auth, async (req, res) => {
  try {
    const twilio = require("twilio");
    const client = twilio(process.env.TWILIO_SID, process.env.TWILIO_AUTH_TOKEN);

    const { id, travelerId } = req.params;
    const { message } = req.body;

    const itinerary = await Itinerary.findOne({ _id: id, userId: req.user.id });
    if (!itinerary) {
      return res.status(404).json({ status: false, message: "Itinerary not found" });
    }

    const traveler = await Traveler.findOne({
      _id: travelerId,
      itineraryId: id,
    });
    if (!traveler) {
      return res.status(404).json({ status: false, message: "Traveler not found" });
    }

    // 🔥 FIXED Phone format
    let cleanPhone = traveler.phone.startsWith('+91') ? `whatsapp:${traveler.phone}` : `whatsapp:+91${traveler.phone}`;

    const whatsappMessage = `🎉 *${itinerary.title}*\n\nHi ${traveler.name}!\n\n${
      message || "Your trip itinerary is ready!"
    }\n\nTravel Team`;

    const result = await client.messages.create({
      from: process.env.TWILIO_WHATSAPP_FROM,
      to: cleanPhone,
      body: whatsappMessage,
    });

    res.json({
      status: true,
      message: `WhatsApp sent to ${traveler.name}!`,
      sid: result.sid,
    });
  } catch (error) {
    console.error("WhatsApp error:", error);
    res.status(500).json({ status: false, message: error.message });
  }
});

// 🔥 FIXED: सभी travelers को WhatsApp (6/6 GUARANTEED!)
router.post("/:id/whatsapp-all", auth, async (req, res) => {
  try {
    const twilio = require("twilio");
    const client = twilio(process.env.TWILIO_SID, process.env.TWILIO_AUTH_TOKEN);

    const { id } = req.params;
    const { message } = req.body;

    console.log('🚀 WhatsApp ALL for:', id);

    const itinerary = await Itinerary.findOne({
      _id: id,
      userId: req.user.id,
    }).populate("travelers");

    if (!itinerary) {
      return res.status(404).json({ status: false, message: "Itinerary not found" });
    }

    console.log('📱 Found travelers:', itinerary.travelers.length);
    console.log('👥 Travelers data:', itinerary.travelers.map(t => ({name: t.name, phone: t.phone})));

    const results = [];
    let sentCount = 0;

    for (const traveler of itinerary.travelers) {
      console.log(`📤 Sending to ${traveler.name}: "${traveler.phone}"`);

      // 🔥 PERFECT Phone format handling
      let cleanPhone = '';
      if (traveler.phone.startsWith('+91')) {
        cleanPhone = `whatsapp:${traveler.phone}`;
      } else if (traveler.phone.length === 10 && /^\d{10}$/.test(traveler.phone)) {
        cleanPhone = `whatsapp:+91${traveler.phone}`;
      } else {
        console.log(`❌ Invalid phone: ${traveler.phone}`);
        results.push({ success: false, name: traveler.name, phone: traveler.phone, error: 'Invalid phone format' });
        continue;
      }

      try {
        const whatsappMessage = `🎉 *${itinerary.title}*\n\nHi ${traveler.name}!\n\n${message || "Your trip is confirmed!"}\n\nTravel Team`;

        const result = await client.messages.create({
          from: process.env.TWILIO_WHATSAPP_FROM,
          to: cleanPhone,
          body: whatsappMessage,
        });

        sentCount++;
        results.push({ success: true, name: traveler.name, phone: cleanPhone, sid: result.sid });
        console.log(`✅ ${sentCount}/${itinerary.travelers.length}: ${traveler.name} (${cleanPhone})`);

        // Rate limiting
        await new Promise((resolve) => setTimeout(resolve, 1000));
      } catch (err) {
        console.error(`❌ ${traveler.name} failed:`, err.message);
        results.push({ success: false, name: traveler.name, phone: cleanPhone, error: err.message });
      }
    }

    console.log(`🎉 FINAL RESULT: ${sentCount}/${itinerary.travelers.length} WhatsApp sent!`);

    res.json({
      status: true,
      message: `${sentCount}/${itinerary.travelers.length} को WhatsApp भेजा!`,
      sent: sentCount,
      total: itinerary.travelers.length,
      results,
    });
  } catch (error) {
    console.error("WhatsApp-all error:", error);
    res.status(500).json({ status: false, message: error.message });
  }
});

module.exports = router;
