import Itinerary from "../models/Itinerary.js";

export const uploadItinerary = async (req, res) => {
  try {
    // Validation
    if (!req.file) {
      return res.status(400).json({
        status: false,
        message: "No file uploaded"
      });
    }

    if (!req.body.title) {
      return res.status(400).json({
        status: false,
        message: "Title is required"
      });
    }

    // File validation (PDF, CSV, JSON only)
    const allowedTypes = ['application/pdf', 'text/csv', 'application/json'];
    if (!allowedTypes.includes(req.file.mimetype)) {
      return res.status(400).json({
        status: false,
        message: "Only PDF, CSV, JSON files allowed"
      });
    }

    if (req.file.size > 10 * 1024 * 1024) { // 10MB
      return res.status(400).json({
        status: false,
        message: "File too large (max 10MB)"
      });
    }

    const fileUrl = `/uploads/${req.file.filename}`;

    const item = await Itinerary.create({
      title: req.body.title,
      destination: req.body.destination || '',
      startDate: req.body.startDate || null,
      endDate: req.body.endDate || null,
      travelerType: req.body.travelerType || '',
      description: req.body.description || '',
      userId: req.user.id,
      fileUrl,
      fileSize: req.file.size,
      fileType: req.file.mimetype
    });

    res.json({
      status: true,
      message: "Itinerary uploaded successfully",
      item: {
        id: item._id,
        title: item.title,
        destination: item.destination,
        fileUrl: item.fileUrl
      }
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({
      status: false,
      message: "Server error: " + error.message
    });
  }
};

export const getItineraries = async (req, res) => {
  try {
    const itineraries = await Itinerary.find({
      userId: req.user.id
    }).select('-fileUrl -__v').sort({ createdAt: -1 });

    res.json({
      status: true,
      data: itineraries
    });
  } catch (error) {
    console.error('Get itineraries error:', error);
    res.status(500).json({
      status: false,
      message: error.message
    });
  }
};

export const getItineraryDetail = async (req, res) => {
  try {
    const itinerary = await Itinerary.findOne({
      _id: req.params.id,
      userId: req.user.id
    });

    if (!itinerary) {
      return res.status(404).json({
        status: false,
        message: "Itinerary not found"
      });
    }

    res.json({
      status: true,
      data: itinerary
    });
  } catch (error) {
    res.status(500).json({
      status: false,
      message: error.message
    });
  }
};
