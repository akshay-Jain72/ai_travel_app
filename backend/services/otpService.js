const crypto = require('crypto');
const nodemailer = require('nodemailer');
const twilio = require('twilio');

// Twilio SMS
const twilioClient = twilio(process.env.TWILIO_SID, process.env.TWILIO_TOKEN);

// Email Transporter
const transporter = nodemailer.createTransporter({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

class OTPService {
  static generateOTP(value) {
    return new Promise((resolve, reject) => {
      const otp = Math.floor(100000 + Math.random() * 900000).toString(); // 6 digit
      const ttl = 5 * 60 * 1000; // 5 minutes
      const expires = Date.now() + ttl;

      // Create hash
      const data = `${value}.${otp}.${expires}`;
      const hash = crypto.createHmac('sha256', process.env.OTP_SECRET || 'secret').update(data).digest('hex');

      // Save to Redis/Mongo (for verification)
      // redis.set(value, hash, 'EX', 300); // 5 min expiry

      console.log(`OTP for ${value}: ${otp}`);

      // Send OTP
      this.sendOTP(value, otp, type)
        .then(() => resolve(hash))
        .catch(reject);
    });
  }

  static async sendOTP(value, otp, type) {
    if (type === 'email') {
      await transporter.sendMail({
        to: value,
        subject: 'Your OTP Code - Travel App',
        html: `
          <h2>Your OTP Code</h2>
          <h1 style="color: #007bff">${otp}</h1>
          <p>This code expires in 5 minutes.</p>
        `
      });
    } else if (type === 'phone') {
      await twilioClient.messages.create({
        body: `Your Travel App OTP: ${otp}. Valid for 5 minutes.`,
        from: process.env.TWILIO_PHONE,
        to: value
      });
    }
  }

  static verifyOTP(value, otp) {
    return new Promise((resolve, reject) => {
      // Redis.get(value, (err, hash) => {
      //   if (err) reject(err);

      //   const data = `${value}.${otp}.${expires}`;
      //   const newHash = crypto.createHmac('sha256', process.env.OTP_SECRET).update(data).digest('hex');

      //   resolve(hash === newHash);
      // });

      // TEMP: Simple verification (production mein Redis use karo)
      console.log(`Verifying OTP ${otp} for ${value}`);
      resolve(true); // Demo purpose
    });
  }
}

module.exports = OTPService;
