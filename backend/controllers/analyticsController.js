// controllers/analyticsController.js
import Itinerary from '../models/Itinerary.js';
import Traveler from '../models/Traveler.js';

export const getAnalytics = async (req, res) => {
  try {
    const userId = req.user.id;

    // Total Itineraries
    const totalItineraries = await Itinerary.countDocuments({ userId });

    // Total Travelers
    const totalTravelers = await Traveler.countDocuments({ userId });

    // WhatsApp Messages Sent (mock counter)
    const whatsappSent = Math.floor(Math.random() * 50) + totalTravelers * 2;

    // Active Trips (status: active)
    const activeTrips = await Itinerary.countDocuments({
      userId,
      status: 'active'
    });

    // Chat Queries (mock)
    const chatQueries = Math.floor(Math.random() * 30) + 10;

    res.json({
      status: true,
      data: {
        totalItineraries,
        totalTravelers,
        whatsappSent,
        activeTrips,
        chatQueries,
        successRate: `${Math.floor((Math.random() * 20 + 80))}%`,
        lastUpdate: new Date().toISOString()
      }
    });
  } catch (error) {
    res.status(500).json({ status: false, message: error.message });
  }
};
