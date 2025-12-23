// utils/sendOtp.js
import nodemailer from "nodemailer";
import Fast2SMS from "fast2sms"; // npm install fast2sms

export const sendOTP = async (value, otp, type = 'email') => {
  try {
    console.log(`📤 Sending ${type.toUpperCase()} OTP ${otp} to ${value}`);

    if (type === 'email') {
      // ✅ GMAIL EMAIL OTP (Working NOW!)
      const transporter = nodemailer.createTransporter({
        service: "gmail",
        auth: {
          user: process.env.EMAIL_USER,        // jain47699@gmail.com
          pass: process.env.EMAIL_PASS         // App Password
        }
      });

      const mailOptions = {
        from: `"Akshay Travels AI" <${process.env.EMAIL_USER}>`,
        to: value,
        subject: "🔐 Your OTP Code - Valid for 5 Minutes",
        html: `
          <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="text-align: center; padding: 20px;">
              <h2 style="color: #2563eb; margin: 0;">Your OTP Code</h2>
              <p style="color: #666; margin: 10px 0;">Enter this code to verify your account</p>
            </div>

            <div style="
              background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
              color: white;
              padding: 30px 20px;
              text-align: center;
              border-radius: 20px;
              font-size: 36px;
              font-weight: 800;
              letter-spacing: 8px;
              box-shadow: 0 20px 40px rgba(37, 99, 235, 0.4);
              margin: 20px 0;
            ">
              ${otp}
            </div>

            <div style="background: #f8fafc; padding: 20px; border-radius: 15px; text-align: center;">
              <p style="color: #475569; margin: 0; font-size: 16px;">
                <strong>This code expires in 5 minutes.</strong><br>
                If you didn't request this, please ignore this email.
              </p>
            </div>

            <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #e2e8f0;">
              <p style="color: #94a3b8; font-size: 14px; margin: 0;">
                Akshay Travels AI<br>
                <a href="https://akshaytravels.com" style="color: #2563eb;">akshaytravels.com</a>
              </p>
            </div>
          </div>
        `
      };

      await transporter.sendMail(mailOptions);
      console.log(`✅ Email OTP ${otp} sent to ${value}`);

    } else if (type === 'phone') {
      // ✅ FAST2SMS (India Cheapest)
      if (!process.env.FAST2SMS_API_KEY) {
        throw new Error('FAST2SMS_API_KEY not configured');
      }

      const phoneNumber = value.replace('+91', '').replace(/\s/g, ''); // +919876543210 → 9876543210

      const smsResponse = await Fast2SMS.send({
        authorization: process.env.FAST2SMS_API_KEY,
        message: `Akshay Travels AI OTP: ${otp}. Valid for 5 minutes. Do not share.`,
        numbers: [phoneNumber],
        sender_id: "AKSHAY", // Your sender ID from Fast2SMS
        route: "q" // Quick route
      });

      if (smsResponse.return === true) {
        console.log(`✅ SMS OTP ${otp} sent to ${value}`);
      } else {
        throw new Error('SMS delivery failed');
      }
    }

    return { success: true, message: `${type.toUpperCase()} OTP sent successfully` };

  } catch (error) {
    console.error(`❌ OTP Send Error [${type}]:`, error.message);
    throw new Error(`Failed to send ${type} OTP: ${error.message}`);
  }
};
