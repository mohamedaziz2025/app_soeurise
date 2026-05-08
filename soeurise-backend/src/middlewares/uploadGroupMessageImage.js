const multer = require("multer");
const path = require("path");
const fs = require("fs");

const destDir = "uploads/group-messages";
if (!fs.existsSync(destDir)) {
    fs.mkdirSync(destDir, { recursive: true });
}

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, destDir);
    },
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase();
        cb(null, `group_msg_${Date.now()}${ext}`);
    },
});

function fileFilter(req, file, cb) {
    const allowed = ["image/jpeg", "image/png", "image/webp"];
    if (!allowed.includes(file.mimetype)) {
        return cb(new Error("Format non supporte (jpg/png/webp uniquement)"));
    }
    cb(null, true);
}

const uploadGroupMessageImage = multer({
    storage,
    fileFilter,
    limits: { fileSize: 5 * 1024 * 1024 },
});

module.exports = { uploadGroupMessageImage };
