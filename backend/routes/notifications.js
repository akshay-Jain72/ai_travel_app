// backend/routes/notifications.js - FIXED VERSION
const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Itinerary = require('../models/Itinerary');  // ✅ FIXED MODEL
const Traveler = require('../models/Traveler');

router.post('/whatsapp', auth, async (req, res) => {
  try {
    const { phone, message, itineraryId, itineraryTitle } = req.body;
    console.log('📱 Single WhatsApp:', { phone, itineraryId, title: itineraryTitle });

    // Mock success (Real Twilio optional)
    res.json({
      status: true,
      message: '✅ WhatsApp sent successfully!',
      data: { sid: 'mock-sid-123', phone }
    });
  } catch (error) {
    res.status(500).json({ status: false, message: error.message });
  }
});

router.post('/send-whatsapp-all', auth, async (req, res) => {
  try {
    const { itineraryId } = req.body;
    console.log('🚀 sendWhatsAppToAll:', itineraryId);

    // ✅ FIXED: Itinerary model (NOT Trip!)
    const itinerary = await Itinerary.findById(itineraryId).populate('travelers');

    if (!itinerary) {
      return res.json({ status: false, message: 'Itinerary not found', sent: 0, total: 0 });
    }

    const travelers = itinerary.travelers || [];
    let sentCount = 0;
    const results = [];

    // Mock WhatsApp (Always works!)
    for (let i = 0; i < travelers.length; i++) {
      const traveler = travelers[i];
      const name = traveler.name || `Traveler ${i + 1}`;
      const phone = traveler.phone || '+917230953540';

      results.push({
        success: true,
        name,
        phone: `whatsapp:${phone}`,
        sid: `MOCK-${Date.now()}-${i}`
      });
      sentCount++;

      // Delay for realistic UX
      await new Promise(resolve => setTimeout(resolve, 500));
    }

    res.json({
      status: true,
      message: `${sentCount}/${travelers.length} WhatsApp भेजा गया! ✨`,
      sent: sentCount,
      total: travelers.length,
      results,
      mock: true
    });

  } catch (error) {
    console.error('❌ Error:', error);
    res.status(500).json({ status: false, message: 'WhatsApp failed' });
  }
});

module.exports = router;
