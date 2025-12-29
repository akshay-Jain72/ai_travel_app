const jwt = require("jsonwebtoken");
const mongoose = require('mongoose');

module.exports = function (req, res, next) {
  const authHeader = req.header("Authorization");
  console.log('🔑 Full Auth Header:', authHeader);

  if (!authHeader) {
    console.log('❌ No auth header');
    return res.status(401).json({ status: false, message: "No token, authorization denied" });
  }

  const token = authHeader.replace("Bearer ", "").trim();
  console.log('🔑 Token (first 50 chars):', token.substring(0, 50) + '...');

  if (!token) {
    console.log('❌ Token empty after Bearer remove');
    return res.status(401).json({ status: false, message: "Token missing" });
  }

  try {
    console.log('🔑 Verifying token with secret...');
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret');
    console.log('✅ Token DECODED:', decoded);

    // 🔥 CRITICAL: ObjectId validation for Mongoose!
    if (!mongoose.Types.ObjectId.isValid(decoded.id)) {
      console.log('❌ Invalid ObjectId:', decoded.id);
      return res.status(401).json({ status: false, message: "Invalid user ID format" });
    }

    // ✅ PERFECT ObjectId for Itinerary model!
    req.user = { id: decoded.id };
    console.log('✅ AUTH SUCCESS - USER ID:', req.user.id);

    next();
  } catch (err) {
    console.log('❌ JWT ERROR:', err.name, ':', err.message);
    console.log('🔑 Secret preview:', (process.env.JWT_SECRET || 'secret').substring(0, 10) + '...');
    return res.status(401).json({ status: false, message: "Token is not valid" });
  }
};
