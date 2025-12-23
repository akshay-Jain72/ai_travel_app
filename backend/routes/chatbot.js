const express = require('express');
const router = express.Router();

router.post('/query', (req, res) => {
  console.log('🤖 AI Chat:', req.body.message);

  const responses = [
    'Great question! Your trip is all set! ✈️',
    'Flight status: On time! Check-in opens 3 hours before departure.',
    'Hotel confirmed! Check-in at 2 PM tomorrow. 🏨',
    'Weather looks perfect! ☀️ 25°C, clear skies.',
    'Restaurant recommendations sent to your dashboard! 🍽️'
  ];

  setTimeout(() => {
    res.json({
      status: true,
      data: { message: responses[Math.floor(Math.random() * responses.length)] }
    });
  }, 1200); // Typing delay
});

module.exports = router;
