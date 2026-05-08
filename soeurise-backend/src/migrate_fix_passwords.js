/**
 * Migration Script: Fix missing passwordHash for existing users
 * 
 * This script updates all users in the database that are missing a passwordHash.
 * It generates a temporary password for each user and hashes it.
 * 
 * Usage: node src/migrate_fix_passwords.js
 */

require("dotenv").config();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const User = require("./modules/users/models/User");
const { MONGO_URI } = require("./config/env");

async function migratePasswords() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log("🔗 Connecté à MongoDB...");

    // Find all users without passwordHash
    const usersWithoutPassword = await User.find({ passwordHash: { $exists: false } });
    
    if (usersWithoutPassword.length === 0) {
      console.log("✅ Aucun utilisateur sans passwordHash trouvé. Migration terminée!");
      process.exit(0);
      return;
    }

    console.log(`\n⚠️  Trouvé ${usersWithoutPassword.length} utilisateur(s) sans passwordHash`);
    console.log("📝 Génération de mots de passe temporaires...\n");

    let updated = 0;
    for (const user of usersWithoutPassword) {
      // Generate temporary password: TempPass_[username]_[random]
      const tempPassword = `TempPass_${user.username}_${Math.random().toString(36).substr(2, 8)}`;
      
      // Hash the temporary password
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(tempPassword, salt);
      
      // Update user with hashed password
      await User.updateOne(
        { _id: user._id },
        { passwordHash }
      );
      
      updated++;
      console.log(`✅ Utilisateur "${user.username}" (${user.email}) - Mot de passe temporaire défini`);
      console.log(`   Mot de passe temporaire: ${tempPassword}`);
      console.log(`   ⚠️  Demandez à l'utilisateur de réinitialiser son mot de passe au prochain login\n`);
    }

    console.log(`\n✅ Migration terminée! ${updated} utilisateur(s) mis à jour`);
    console.log("📌 Rappel: Les utilisateurs doivent réinitialiser leurs mots de passe au prochain login");
    
    process.exit(0);
  } catch (err) {
    console.error("❌ Erreur pendant la migration :", err);
    process.exit(1);
  }
}

migratePasswords();
