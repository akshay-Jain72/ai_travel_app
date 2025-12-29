require("dotenv").config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const csv = require('csv-parser');
const fs = require('fs');
const twilio = require('twilio');
const path = require('path');

const app = express();

// ✅ Middleware - Render Compatible
app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// ✅ Render Uploads Static
app.use('/uploads', express.static('uploads'));
app.use('/uploads', express.static('/tmp/uploads'));

// MongoDB Atlas Connection
mongoose.connect(process.env.MONGODB_URI || process.env.MONGO_URL)
  .then(() => console.log('✅ MongoDB Connected'))
  .catch(err => console.error('❌ MongoDB Error:', err));

// User Schema
const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  name: String,
  phone: String
});
const User = mongoose.model('User', userSchema);

// Itinerary Schema
const itinerarySchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  userEmail: String,
  name: String,
  email: String,
  phone: String,
  destination: String,
  dates: String,
  budget: String,
  travelers: String,
  title: { type: String, required: true },  // ✅ Title required fix
  fileUrl: String,
  uploadedAt: { type: Date, default: Date.now }
});
const Itinerary = mongoose.model('Itinerary', itinerarySchema);

// ✅ Render Multer Storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dest = process.env.NODE_ENV === 'production' ? '/tmp/uploads/' : 'uploads/';
    if (!fs.existsSync(dest)) fs.mkdirSync(dest, { recursive: true });
    console.log(`📁 Saving to: ${dest}`);
    cb(null, dest);
  },
  filename: (req, file, cb) => {
    cb(null, `itinerary-${Date.now()}-${Math.random().toString(36).substr(2, 9)}${path.extname(file.originalname)}`);
  }
});
const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    if (['.pdf', '.csv', '.json'].includes(ext)) cb(null, true);
    else cb(new Error("Only PDF, CSV, JSON allowed"));
  }
});

const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-key';

// Middleware Auth
const auth = (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    if (!token) return res.status(401).json({ error: 'No token' });

    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Routes
app.get('/', (req, res) => res.json({ message: '🚀 Akshay Travels LIVE!' }));

// 1. Register
app.post('/api/register', async (req, res) => {
  try {
    const { email, password, name, phone } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({ email: email.toLowerCase(), password: hashedPassword, name, phone });
    await user.save();

    const token = jwt.sign({ userId: user._id }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user._id, email: user.email, name: user.name } });
  } catch (error) {
    res.status(400).json({ error: 'User already exists' });
  }
});

// 2. Login
app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email: email.toLowerCase() });

    if (!user || !await bcrypt.compare(password, user.password)) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign({ userId: user._id }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user._id, email: user.email, name: user.name } });
  } catch (error) {
    res.status(400).json({ error: 'Invalid credentials' });
  }
});

// 3. CSV Upload
app.post('/api/upload-itinerary', auth, upload.single('csvFile'), async (req, res) => {
  try {
    console.log('📤 REQ.BODY:', req.body);
    console.log('👤 USER.ID:', req.user.userId);

    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });

    const title = req.body.title?.trim() || `Trip ${new Date().toLocaleDateString()}`;
    const results = [];

    if (req.file.mimetype.includes('csv')) {
      await new Promise((resolve, reject) => {
        fs.createReadStream(req.file.path)
          .pipe(csv())
          .on('data', (data) => results.push(data))
          .on('end', resolve)
          .on('error', reject);
      });
    }

    for (let row of results.slice(0, 5)) {
      const itinerary = new Itinerary({
        userId: req.user.userId,
        userEmail: req.user.email,
        title,
        fileUrl: `/uploads/${req.file.filename}`,
        destination: row.destination || row.Destination || '',
        dates: row.dates || row.Dates || '',
        budget: row.budget || row.Budget || '',
        travelers: row.travelers || row.Travelers || ''
      });
      await itinerary.save();
    }

    fs.unlinkSync(req.file.path);
    res.json({ success: true, count: results.length, title });
  } catch (error) {
    console.error('Upload Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// 4. Get Itineraries
app.get('/api/itineraries', auth, async (req, res) => {
  const itineraries = await Itinerary.find({ userId: req.user.userId })
    .sort({ uploadedAt: -1 })
    .limit(20);
  res.json(itineraries);
});

// 5. AI Chat
app.post('/api/ai-chat', async (req, res) => {
  const { message, destination } = req.body;
  let response = 'Great choice! ';

  if (destination.toLowerCase().includes('udaipur')) {
    response += 'Udaipur के लिए Lake Pichola, City Palace must-visit हैं। December में perfect weather!';
  } else {
    response += `${destination} amazing destination है! Local food enjoy करो।`;
  }

  res.json({ reply: response });
});

// WhatsApp Notification
const sendWhatsAppNotification = (phone, itinerary) => {
  if (!process.env.TWILIO_ACCOUNT_SID) return;

  const client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
  client.messages.create({
    from: process.env.TWILIO_WHATSAPP_FROM,
    to: `whatsapp:${phone}`,
    body: `✈️ नया Itinerary!\n${itinerary.destination} | ₹${itinerary.budget}`
  }).catch(console.error);
};

// Test
app.get('/api/test', (req, res) => res.json({ status: 'Server LIVE ✅' }));

// 404
app.use('*', (req, res) => res.status(404).json({ error: 'Not found' }));

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server: ${PORT}`);
  console.log(`✅ Render LIVE!`);
});
