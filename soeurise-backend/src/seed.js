require("dotenv").config();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const User = require("./modules/users/models/User");
const Masterclass = require("./modules/masterclass/models/Masterclass");
const Event = require("./modules/events/models/Event");
const { MONGO_URI } = require("./config/env");

const masterclasses = [
  {
    title: "Introduction à l'entrepreneuriat",
    description: "Les bases pour démarrer votre projet",
    instructorName: "Fatima Al-Rashid",
    videoUrl: "https://example.com/video1",
    thumbnailUrl: "https://images.unsplash.com/photo-1573164713988-8665fc963095?auto=format&fit=crop&q=80",
  },
  {
    title: "Gestion financière pour femmes",
    description: "Maîtriser ses finances personnelles",
    instructorName: "Aisha Mohammed",
    videoUrl: "https://example.com/video2",
    thumbnailUrl: "https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&q=80",
  },
];

const events = [
  {
    title: "Webinaire: Femmes Leaders",
    dateTime: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    type: "online",
    location: "Zoom",
    imageUrl: "https://images.unsplash.com/photo-1542744173-8e7e53415bb0?auto=format&fit=crop&q=80",
  },
  {
    title: "Conférence Annuelle",
    dateTime: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
    type: "physical",
    location: "Casablanca, Maroc",
    imageUrl: "https://images.unsplash.com/photo-1505373877841-8d25f7d46678?auto=format&fit=crop&q=80",
  },
];

async function seedDB() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log("Connecté à MongoDB...");

    // Clear existing
    await Masterclass.deleteMany({});
    await Event.deleteMany({});
    console.log("Masterclasses et Événements supprimés.");

    // Insert new data
    await Masterclass.insertMany(masterclasses);
    await Event.insertMany(events);
    console.log("✅ Masterclasses et Événements insérés avec succès !");

    // Seed Admin account (upsert — won't duplicate if already exists)
    const adminEmail = "admin@soeurise.com";
    const existingAdmin = await User.findOne({ email: adminEmail });

    if (!existingAdmin) {
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash("Admin123!", salt);

      await User.create({
        firstName: "Admin",
        lastName: "Soeurise",
        username: "admin",
        email: adminEmail,
        passwordHash,
        role: "admin",
        isActive: true,
      });
      console.log("✅ Compte admin créé : admin@soeurise.com / Admin123!");
    } else {
      console.log("ℹ️  Compte admin existe déjà.");
    }

    process.exit(0);
  } catch (err) {
    console.error("Erreur de seeding :", err);
    process.exit(1);
  }
}

seedDB();
