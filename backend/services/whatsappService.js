class WhatsAppService {
  static async sendMessage(phone, message, itineraryTitle = '') {
    // 🔥 MOCK MODE (Safe - No Twilio crash!)
    if (!process.env.TWILIO_SID || process.env.TWILIO_SID === 'skip') {
      const mockMsg = `📱 MOCK WhatsApp [${itineraryTitle}]\n${phone}: ${message.substring(0, 50)}...`;
      console.log(mockMsg);
      return {
        success: true,
        sid: 'mock-sid-123',
        message: 'WhatsApp sent (Mock Mode)',
        phone: phone,
        preview: message.substring(0, 30) + '...'
      };
    }

    // 🔥 REAL TWILIO (Only if .env has valid keys)
    try {
      const twilio = require('twilio');
      const client = twilio(process.env.TWILIO_SID, process.env.TWILIO_AUTH_TOKEN);

      const formattedMessage = itineraryTitle
        ? `✈️ *${itineraryTitle}*\n\n${message}\n\n👨‍💼 Travel Agent Support`
        : message;

      const response = await client.messages.create({
        body: formattedMessage,
        from: process.env.TWILIO_PHONE || 'whatsapp:+14155238886',
        to: `whatsapp:${phone}`
      });

      console.log(`✅ REAL WhatsApp sent: ${response.sid}`);
      return {
        success: true,
        sid: response.sid,
        message: 'WhatsApp sent successfully!'
      };
    } catch (error) {
      console.error('❌ WhatsApp Error:', error.message);
      return {
        success: false,
        error: error.message,
        message: 'WhatsApp send failed'
      };
    }
  }
}

module.exports = WhatsAppService;
