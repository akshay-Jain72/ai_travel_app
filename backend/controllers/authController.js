import User from "../models/User.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { sendOTP } from "../utils/sendOtp.js";

export const signup = async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;

    if (!name || !email || !phone || !password) {
      return res.status(400).json({ status: false, message: "All fields required" });
    }

    const existingUser = await User.findOne({
      $or: [{ email: email.toLowerCase() }, { phone }]
    });
    if (existingUser) {
      return res.status(400).json({ status: false, message: "User already exists" });
    }

    const hashed = await bcrypt.hash(password.toString().trim(), 10);
    const user = await User.create({
      name,
      email: email.toLowerCase(),
      phone,
      password: hashed
    });

    res.json({
      status: true,
      message: "Signup successful",
      user: { id: user._id, name: user.name, email: user.email, phone: user.phone }
    });
  } catch (error) {
    res.status(500).json({ status: false, message: error.message });
  }
};

export const login = async (req, res) => {
  try {
    let { email, password } = req.body;
    email = email?.toString().trim().toLowerCase().replace(/\s+/g, '');

    const user = await User.findOne({
      $or: [{ email }, { phone: email }]
    }).select('+password');

    if (!user) {
      return res.status(400).json({ status: false, message: "Invalid credentials" });
    }

    const correct = await bcrypt.compare(password.toString().trim(), user.password);
    if (!correct) {
      return res.status(400).json({ status: false, message: "Invalid credentials" });
    }

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '7d' });

    res.json({
      status: true,
      message: "Login successful",
      token,
      user: { id: user._id, name: user.name, email: user.email, phone: user.phone }
    });
  } catch (error) {
    res.status(500).json({ status: false, message: error.message });
  }
};

// 🔥 REAL OTP SENDING!
export const sendOtp = async (req, res) => {
  try {
    const { type, value } = req.body;
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    console.log(`📱 OTP: ${otp} for ${value} (${type})`);

    const updated = await User.updateOne(
      { $or: [{ email: value }, { phone: value }] },
      {
        otp,
        otpExpire: Date.now() + 5 * 60 * 1000,
        isOtpVerified: false
      }
    );

    if (updated.matchedCount === 0) {
      return res.status(404).json({ status: false, message: "User not found - First signup!" });
    }

    // 🔥 REAL EMAIL/SMS!
    await sendOTP(value, otp, type);
    console.log(`✅ REAL OTP SENT to ${value}`);

    res.json({ status: true, message: "OTP sent successfully!" });
  } catch (error) {
    console.error("💥 SEND OTP ERROR:", error);
    res.status(500).json({ status: false, message: error.message });
  }
};

export const verifyOtp = async (req, res) => {
  try {
    const { value, otp } = req.body;

    console.log(`🔍 VERIFY OTP: ${otp} for ${value}`);

    const user = await User.findOne({
      $or: [
        { email: value, otp, otpExpire: { $gt: Date.now() }, isOtpVerified: false },
        { phone: value, otp, otpExpire: { $gt: Date.now() }, isOtpVerified: false }
      ]
    });

    if (!user) {
      console.log("❌ INVALID/EXPIRED OTP");
      return res.status(400).json({ status: false, message: "Invalid or expired OTP" });
    }

    user.isOtpVerified = true;
    await user.save();

    console.log("✅ OTP VERIFIED:", user.email || user.phone);
    res.json({ status: true, message: "OTP verified successfully" });
  } catch (error) {
    console.error("💥 VERIFY OTP ERROR:", error);
    res.status(500).json({ status: false, message: error.message });
  }
};

export const resetPassword = async (req, res) => {
  try {
    const { value, password } = req.body;

    console.log(`🔄 RESET PASS for ${value}`);

    const user = await User.findOne({
      $or: [
        { email: value, isOtpVerified: true },
        { phone: value, isOtpVerified: true }
      ]
    });

    if (!user) {
      return res.status(400).json({ status: false, message: "Complete OTP verification first" });
    }

    user.password = await bcrypt.hash(password.toString().trim(), 10);
    user.otp = null;
    user.otpExpire = null;
    user.isOtpVerified = false;
    await user.save();

    console.log("✅ PASS RESET:", user.email || user.phone);
    res.json({ status: true, message: "Password reset successful" });
  } catch (error) {
    console.error("💥 RESET PASS ERROR:", error);
    res.status(500).json({ status: false, message: error.message });
  }
};
