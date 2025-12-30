const express = require("express");
const router = express.Router();
const User = require("../models/User");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const twilio = require('twilio');
const nodemailer = require('nodemailer');

// 🔥 FIXED Twilio + Nodemailer Setup
const twilioClient = twilio(process.env.TWILIO_SID, process.env.TWILIO_AUTH_TOKEN);
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

// ------------------------------------------------------
// POST /api/auth/signup
// ------------------------------------------------------
router.post("/signup", async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;

    console.log("📝 SIGNUP:", {
      name,
      email,
      phone: phone?.substring(0, 4) + "****",
    });

    if (!name || !email || !phone || !password) {
      return res.status(400).json({
        status: false,
        message: "All fields required",
      });
    }

    const exists = await User.findOne({
      $or: [{ email: email.toLowerCase() }, { phone }],
    });

    if (exists) {
      console.log("❌ USER EXISTS:", exists.email);
      return res.status(400).json({
        status: false,
        message: "User already exists",
      });
    }

    const hash = await bcrypt.hash(password.toString().trim(), 12);

    const user = await User.create({
      name,
      email: email.toLowerCase(),
      phone,
      password: hash,
    });

    console.log("✅ SIGNUP SUCCESS:", user.email);

    return res.json({
      status: true,
      message: "Signup successful",
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
      },
    });
  } catch (err) {
    console.error("💥 SIGNUP ERROR:", err);
    return res.status(500).json({
      status: false,
      message: err.message,
    });
  }
});

// ------------------------------------------------------
// POST /api/auth/login
// ------------------------------------------------------
router.post("/login", async (req, res) => {
  try {
    let { email, password } = req.body;

    email = email?.toString().trim().toLowerCase().replace(/\s+/g, '');
    const normalizedPassword = password?.toString().trim().replace(/\s+/g, '');

    console.log("🔍 LOGIN EMAIL:", email);

    const user = await User.findOne({
      $or: [{ email }, { phone: email }],
    }).select("name email phone password");

    console.log("👤 USER FOUND:", user ? user.email : "NO USER");

    if (!user || !user.password || !normalizedPassword) {
      return res.status(400).json({
        status: false,
        message: "Invalid credentials",
      });
    }

    const match = await bcrypt.compare(normalizedPassword, user.password);
    console.log("✅ PASSWORD MATCH:", match);

    if (!match) {
      return res.status(400).json({
        status: false,
        message: "Invalid credentials",
      });
    }

    const token = jwt.sign(
      { id: user._id },
      process.env.JWT_SECRET || "secret",
      { expiresIn: "7d" }
    );

    console.log("🎉 LOGIN SUCCESS:", user.email);

    return res.json({
      status: true,
      message: "Login successful",
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
      },
    });
  } catch (err) {
    console.error("💥 LOGIN ERROR:", err);
    return res.status(500).json({
      status: false,
      message: err.message,
    });
  }
});

// ------------------------------------------------------
// 🔥 OTP ROUTES - WHATSAPP/SMS + EMAIL (100% FIXED!)
// ------------------------------------------------------
router.post("/send-otp", async (req, res) => {
  try {
    const { type, value } = req.body;
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    console.log(`📱 OTP GENERATED: ${otp} for ${value} (${type})`);

    // 🔥 REAL SMS/WhatsApp/Email भेजो!
    if (type === 'phone') {
      // ✅ WHATSAPP/SMS - FIXED FORMAT!
      const fromNumber = process.env.TWILIO_PHONE || process.env.TWILIO_WHATSAPP_FROM;

      // WhatsApp format check
      if (fromNumber.includes('whatsapp:')) {
        await twilioClient.messages.create({
          body: `Akshay Travels OTP: ${otp}\nValid for 5 minutes only.`,
          from: fromNumber,                    // whatsapp:+14155238886
          to: `whatsapp:${value}`              // whatsapp:+917230953540 ✅
        });
      } else {
        // Regular SMS
        await twilioClient.messages.create({
          body: `Akshay Travels OTP: ${otp}\nValid for 5 minutes only.`,
          from: fromNumber,                    // +12526665975
          to: value                            // +917230953540
        });
      }

      console.log(`✅ SMS/WHATSAPP SENT to ${value}: ${otp}`);
    } else {
      // ✅ Email via Nodemailer
      await transporter.sendMail({
        from: `"Akshay Travels" <${process.env.EMAIL_USER}>`,
        to: value,
        subject: 'Akshay Travels - Your OTP Code',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #2563eb;">Your OTP Code</h2>
            <div style="background: linear-gradient(135deg, #2563eb, #1d4ed8); color: white; padding: 20px; border-radius: 12px; text-align: center;">
              <h1 style="margin: 0; font-size: 48px; font-weight: bold;">${otp}</h1>
            </div>
            <p style="color: #666; margin-top: 20px;">This OTP is valid for <strong>5 minutes</strong> only.</p>
            <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
            <p style="color: #999; font-size: 14px;">Akshay Travels Team</p>
          </div>
        `
      });
      console.log(`✅ EMAIL SENT to ${value}: ${otp}`);
    }

    // DB में save
    const updateResult = await User.updateOne(
      { $or: [{ email: value }, { phone: value }] },
      {
        otp,
        otpExpire: Date.now() + 5 * 60 * 1000,
        isOtpVerified: false,
      }
    );

    if (updateResult.matchedCount === 0) {
      return res.status(404).json({
        status: false,
        message: "User not found",
      });
    }

    console.log(`✅ OTP SAVED + SENT for ${value}`);
    return res.json({
      status: true,
      message: `${type === 'phone' ? 'SMS/WhatsApp' : 'Email'} OTP sent successfully!`,
    });
  } catch (err) {
    console.error("💥 SEND OTP ERROR:", err);
    return res.status(500).json({
      status: false,
      message: err.message,
    });
  }
});

// ------------------------------------------------------
// POST /api/auth/verify-otp
// ------------------------------------------------------
router.post("/verify-otp", async (req, res) => {
  try {
    const { value, otp } = req.body;

    console.log(`🔍 VERIFYING OTP: ${otp} for ${value}`);

    const user = await User.findOne({
      $or: [
        { email: value, otp, otpExpire: { $gt: Date.now() }, isOtpVerified: false },
        { phone: value, otp, otpExpire: { $gt: Date.now() }, isOtpVerified: false }
      ]
    });

    if (!user) {
      console.log("❌ INVALID/EXPIRED OTP");
      return res.status(400).json({
        status: false,
        message: "Invalid or expired OTP",
      });
    }

    user.isOtpVerified = true;
    await user.save();

    console.log("✅ OTP VERIFIED SUCCESSFULLY:", user.email || user.phone);

    return res.json({
      status: true,
      message: "OTP verified successfully",
    });
  } catch (err) {
    console.error("💥 VERIFY OTP ERROR:", err);
    return res.status(500).json({
      status: false,
      message: err.message,
    });
  }
});

// ------------------------------------------------------
// POST /api/auth/reset-password
// ------------------------------------------------------
router.post("/reset-password", async (req, res) => {
  try {
    const { value, password } = req.body;

    console.log(`🔄 RESET PASSWORD for ${value}`);

    const user = await User.findOne({
      $or: [
        { email: value, isOtpVerified: true },
        { phone: value, isOtpVerified: true }
      ]
    });

    if (!user) {
      return res.status(400).json({
        status: false,
        message: "Complete OTP verification first",
      });
    }

    user.password = await bcrypt.hash(password.toString().trim(), 12);
    user.otp = null;
    user.otpExpire = null;
    user.isOtpVerified = false;
    await user.save();

    console.log("✅ PASSWORD RESET SUCCESS:", user.email || user.phone);

    return res.json({
      status: true,
      message: "Password reset successful",
    });
  } catch (err) {
    console.error("💥 RESET PASSWORD ERROR:", err);
    return res.status(500).json({
      status: false,
      message: err.message,
    });
  }
});

// ------------------------------------------------------
// DEBUG ROUTES
// ------------------------------------------------------
router.post("/debug-compare", async (req, res) => {
  try {
    const { email, testPassword } = req.body;
    const user = await User.findOne({ email: email.toLowerCase() }).select('password');
    if (!user) {
      return res.json({ error: 'User not found', status: false });
    }

    const cleanPass = testPassword.toString().trim().replace(/\s+/g, '');
    const match = await bcrypt.compare(cleanPass, user.password);

    res.json({
      status: true,
      match,
      success: match ? '✅ LOGIN WILL WORK!' : '❌ PASSWORD MISMATCH'
    });
  } catch (err) {
    res.json({ error: err.message, status: false });
  }
});

router.post("/force-reset", async (req, res) => {
  try {
    const { email, newPassword } = req.body;
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.json({ error: 'User not found', status: false });
    }

    const newHash = await bcrypt.hash(newPassword, 12);
    user.password = newHash;
    await user.save();

    res.json({
      status: true,
      message: "Password force reset complete",
    });
  } catch (err) {
    res.json({ error: err.message, status: false });
  }
});

module.exports = router;
