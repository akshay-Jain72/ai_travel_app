// controllers/analyticsController.js
import Itinerary from '../models/Itinerary.js';
import Traveler from '../models/Traveler.js';

export const getAnalytics = async (req, res) => {
  try {
    const userId = req.user.id;

    // ✅ REAL COUNTS ONLY - NO FAKE DATA
    const totalItineraries = await Itinerary.countDocuments({ userId });
    const totalTravelers = await Traveler.countDocuments({ userId });
    const activeTrips = await Itinerary.countDocuments({ userId, status: 'active' });

    // ✅ TODAY'S ACTIVITY (REAL)
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayTravelers = await Traveler.countDocuments({
      userId,
      createdAt: { $gte: today }
    });

    // ✅ THIS MONTH (REAL)
    const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
    const thisMonthItineraries = await Itinerary.countDocuments({
      userId,
      createdAt: { $gte: monthStart }
    });

    // ✅ PROFESSIONAL METRICS
    const avgTravelersPerTrip = totalItineraries > 0 ? Math.round(totalTravelers / totalItineraries) : 0;
    const completionRate = totalItineraries > 0 ? Math.round((activeTrips / totalItineraries) * 100) : 0;
    const draftTrips = totalItineraries - activeTrips;

    res.json({
      status: true,
      data: {
        // 📊 CORE COUNTS
        totalItineraries,
        totalTravelers,
        activeTrips,
        draftTrips,

        // 🔥 ACTIVITY METRICS
        todayTravelers,
        thisMonthItineraries,

        // 📈 BUSINESS INSIGHTS
        avgTravelersPerTrip,
        completionRate,

        // 🕐 STATUS
        lastActivity: todayTravelers > 0 ? 'Today' : 'No recent activity',
        lastUpdate: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('💥 Analytics Error:', error);
    res.status(500).json({ status: false, message: error.message });
  }
};
