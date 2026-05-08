# 🔒 Fix: Password Authentication Error

## Problem
When attempting to login, you may encounter this error:
```
Error: Illegal arguments: string, undefined
    at comparePassword (src/utils/password.js:9:17)
    at Object.login (src/modules/auth/services/auth.service.js:68:20)
```

## Root Cause
This error occurs when `bcrypt.compare()` is called with an undefined password hash. This happens when:

1. **Existing users** in the database were created without a `passwordHash` field
2. **Data corruption** - passwordHash field is missing or null
3. **Incomplete user registration** - users created without proper password hashing

## Solutions Applied

### ✅ 1. Enhanced Input Validation (`password.js`)
Added explicit checks before comparing passwords:
```javascript
if (!password || typeof password !== 'string') {
  throw new Error('Le mot de passe ne peut pas être vide');
}
if (!hash || typeof hash !== 'string') {
  throw new Error('Hash du mot de passe manquant ou invalide');
}
```

### ✅ 2. Defensive Check in Login Service (`auth.service.js`)
Added validation to catch missing passwordHash:
```javascript
if (!user.passwordHash) {
  const err = new Error("Erreur serveur: données utilisateur corrompues");
  err.statusCode = 500;
  throw err;
}
```

### ✅ 3. Migration Script (`migrate_fix_passwords.js`)
Automatically fixes all existing users without passwords.

## How to Fix Existing Data

### Option A: Use the Migration Script (Recommended)
```bash
# From the soeurise-backend directory
node src/migrate_fix_passwords.js
```

**What it does:**
- Finds all users missing a `passwordHash`
- Generates a temporary secure password for each user
- Hashes and stores it in the database
- Displays temporary passwords (save these!)
- Users will need to reset their passwords on first login

**Output example:**
```
✅ Utilisateur "john" (john@email.com) - Mot de passe temporaire défini
   Mot de passe temporaire: TempPass_john_a1b2c3d4
```

### Option B: Manual Database Fix
If you have MongoDB access, you can directly update users:

```javascript
// MongoDB Shell or MongoDB Compass
db.users.updateMany(
  { passwordHash: { $exists: false } },
  [
    {
      $set: {
        passwordHash: "$username"  // Temporary - users must reset
      }
    }
  ]
);
```

**⚠️ Warning:** This is NOT secure. Use Option A instead.

### Option C: Delete and Re-seed
If you're in development and can lose existing data:

```bash
# Delete MongoDB collection
# Then run the seed script
npm run seed
# Creates fresh admin account: admin@soeurise.com / Admin123!
```

## Testing the Fix

### After Migration
1. Try logging in with a test account:
   ```bash
   POST /api/auth/login
   {
     "emailOrUsername": "testuser@email.com",
     "password": "TempPass_testuser_abc123"
   }
   ```

2. You should receive:
   ```json
   {
     "success": true,
     "user": { ... },
     "token": "eyJhbG..."
   }
   ```

3. User should reset password on first login (implement password reset flow)

## Prevention: Future Best Practices

### ✅ User Creation
Always ensure password hashing in registration:
```javascript
const passwordHash = await hashPassword(password);
const user = await User.create({
  email,
  username,
  passwordHash,  // ← Must be included
  ...
});
```

### ✅ Data Validation
Add schema validation to catch issues early:
```javascript
const userSchema = new mongoose.Schema({
  passwordHash: { 
    type: String, 
    required: true,  // ← Enforce in schema
    validate: {
      validator: function(v) {
        return v && v.length > 0;
      },
      message: 'Password hash is required'
    }
  }
});
```

### ✅ Monitoring
Add logging to track authentication issues:
```javascript
console.warn(`[AUTH] User ${email} missing passwordHash`);
```

## Related Files Modified
- `src/utils/password.js` - Added input validation
- `src/modules/auth/services/auth.service.js` - Added defensive check
- `src/migrate_fix_passwords.js` - New migration script

## Support
If issues persist after migration:
1. Check MongoDB: Are all users now having `passwordHash`?
   ```javascript
   db.users.find({ passwordHash: { $exists: false } }).count()
   ```
2. Verify password hashing in registration endpoint
3. Check server logs for detailed error messages
4. Ensure Node dependencies are up to date: `npm install`
