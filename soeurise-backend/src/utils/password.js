const bcrypt = require("bcryptjs");

async function hashPassword(password) {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(password, salt);
}

async function comparePassword(password, hash) {
  // Validate inputs
  if (!password || typeof password !== 'string') {
    throw new Error('Le mot de passe ne peut pas être vide');
  }
  if (!hash || typeof hash !== 'string') {
    throw new Error('Hash du mot de passe manquant ou invalide');
  }
  return bcrypt.compare(password, hash);
}

module.exports = { hashPassword, comparePassword };
