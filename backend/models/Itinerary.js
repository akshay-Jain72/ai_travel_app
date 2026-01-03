// backend/models/Itinerary.js - FLUTTER TIMELINE PERFECT!
const mongoose = require("mongoose");

const itinerarySchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  destination: {
    type: String,
    default: "Multiple Cities"
  },
  startDate: {
    type: Date
  },
  endDate: {
    type: Date
  },
  travelerType: {
    type: String,
    enum: ['Solo', 'Family', 'Couple', 'Business', 'Group'],
    default: 'Solo'
  },
  description: {
    type: String,
    default: ""
  },
  // ✅ FILE OPTIONAL (manual create ke liye)
  fileUrl: {
    type: String,
    default: null
  },
  fileSize: {
    type: Number,
    default: 0
  },
  fileType: {
    type: String,
    default: null
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  // 🔥 FLUTTER _timelineDay() PERFECT MATCH!
  days: [{
    day: {
      type: Number,
      required: true,
      min: 1
    },
    date: {
      type: String
    },
    title: {
      type: String,
      required: true
    },
    time: {
      type: String,
      default: "09:00"
    },
    location: {
      type: String,
      default: "TBD"
    },
    description: {
      type: String,
      default: "Details"
    }
  }],
  travelers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Traveler'
  }],
  status: {
    type: String,
    enum: ['draft', 'active', 'completed'],
    default: 'draft'
  }
}, {
  timestamps: true
});

// 🔥 FAST QUERIES
itinerarySchema.index({ userId: 1, createdAt: -1 });
itinerarySchema.index({ title: "text" });

module.exports = mongoose.model("Itinerary", itinerarySchema);
