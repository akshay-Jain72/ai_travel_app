// backend/models/Itinerary.js - FIXED!
const mongoose = require("mongoose");

const itinerarySchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true
    },
    destination: {
      type: String,
      default: ""
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
    fileUrl: {
      type: String,
      required: true
    },
    fileSize: {
      type: Number
    },
    fileType: {
      type: String
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    days: [{
      date: String,
      activities: [{
        time: String,
        desc: String,
        location: String,
        type: String
      }]
    }],
    // 🔥 FIXED: Reference to Traveler model
    travelers: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Traveler'
    }],
    status: {
      type: String,
      enum: ['draft', 'active', 'completed'],
      default: 'draft'
    }
  },
  {
    timestamps: true
  }
);

itinerarySchema.index({ userId: 1, createdAt: -1 });
itinerarySchema.index({ title: "text" });

module.exports = mongoose.model("Itinerary", itinerarySchema);
