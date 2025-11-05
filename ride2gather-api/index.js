/**
 * index.js
 *
 * File-level JSDoc:
 * Express-based API server for the ride2gather application. This file sets up
 * middleware (CORS, JSON body parsing, static file serving), configures file
 * uploads with multer, and exposes endpoints for health, signup, login,
 * user retrieval, user update, and profile picture upload. It uses Prisma as
 * the ORM and bcryptjs for password hashing.
 *
 * Endpoints return JSON and follow a simple { ok|error } pattern as needed.
 */

require('dotenv').config();

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const {PrismaClient} = require('@prisma/client');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const prisma = new PrismaClient({log: ['query', 'warn', 'error']});
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({limit: '5mb'}));

/**
 * Ensure uploads directory exists and expose it at /uploads so uploaded files
 * can be served directly by the Express static middleware.
 */
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, {recursive: true});
}
app.use('/uploads', express.static(uploadsDir));

/**
 * Multer storage configuration using simple disk storage.
 *
 * The filename function creates a reasonably unique filename by combining
 * a timestamp and a short random string, preserving the original extension.
 */
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, uploadsDir),
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname) || '';
        const name = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}${ext}`;
        cb(null, name);
    },
});
const upload = multer({
    storage,
    limits: {fileSize: 5 * 1024 * 1024},
});

/**
 * Health check endpoint.
 *
 * Responds with a small JSON payload indicating the service is running.
 */
app.get('/', (_req, res) => res.json({ok: true, service: 'ride2gather-api'}));

/**
 * Debug endpoint that lists users with minimal fields.
 *
 * Useful for development to quickly inspect created users.
 */
app.get('/debug/users', async (_req, res) => {
    const users = await prisma.user.findMany({
        select: {id: true, email: true, username: true, createdAt: true}
    });
    res.json(users);
});

/**
 * Signup endpoint.
 *
 * Validates input, checks for duplicates, hashes the password, and creates a
 * new user record. On success returns the created user's id, email and username.
 *
 * @param req Express request with JSON body { email, username, password, country_code? }
 * @param res Express response used to return JSON and appropriate HTTP status codes.
 */
app.post('/signup', async (req, res) => {
    console.log('SIGNUP BODY:', req.body);

    try {
        const {email, username, password, country_code = ""} = req.body || {};
        if (!email || !username || !password) {
            return res.status(422).json({error: 'email, username, and password are required'});
        }

        if (String(username).length < 3) {
            return res.status(422).json({error: 'username must be at least 3 chars'});
        }

        if (String(password).length < 6) {
            return res.status(422).json({error: 'password must be at least 6 chars'});
        }

        const exists = await prisma.user.findFirst({
            where: {OR: [{email}, {username}]},
            select: {id: true}
        });

        if (exists) return res.status(409).json({error: 'email or username already exists'});

        const hash = await bcrypt.hash(password, 10);
        const user = await prisma.user.create({
            data: {email, username, passwordHash: hash, country_code}
        });
        console.log('Created user:', user);
        return res.status(201).json({
            id: user.id,
            email: user.email,
            username: user.username,
            country_code: user.country_code
        });

    } catch (e) {
        if (e && e.code === 'P2002') {
            return res.status(409).json({error: 'email or username already exists'});
        }
        console.error('SIGNUP_ERROR:', e);
        return res.status(500).json({error: e?.message || 'server error'});
    }
});

/**
 * Login endpoint.
 *
 * Accepts an identity (email or username) and password. Validates credentials
 * and returns basic user info on success. In production a JWT should be issued
 * instead of returning raw user data.
 *
 * @param req Express request with JSON body { identity, password }
 * @param res Express response used to return JSON and HTTP status codes.
 */
app.post('/login', async (req, res) => {
    const {identity, password} = req.body || {};
    if (!identity || !password) {
        return res.status(422).json({error: 'username/email and password are required'});
    }
    try {
        const user = await prisma.user.findFirst({
            where: {
                OR: [
                    {email: identity},
                    {username: identity}
                ]
            }
        });
        if (!user) {
            return res.status(404).json({error: "User not found"});
        }
        const valid = await bcrypt.compare(password, user.passwordHash);
        if (!valid) {
            return res.status(401).json({error: "Invalid password"});
        }
        return res.json({
            id: user.id,
            email: user.email,
            username: user.username,
            country_code: user.country_code
        });
    } catch (e) {
        console.error('LOGIN_ERROR:', e);
        return res.status(500).json({error: e?.message || "server error"});
    }
});

/**
 * Get user by username.
 *
 * Returns public profile information and the user's primary bike if set.
 *
 * @route GET /user/:username
 * @param req Express request with params.username
 * @param res Express response
 */
app.get('/user/:username', async (req, res) => {
    try {
        const {username} = req.params;
        const user = await prisma.user.findUnique({
            where: {username},
            include: {myBike: true}
        });
        if (!user) return res.status(404).json({error: 'User not found'});
        const out = {
            id: user.id,
            email: user.email,
            username: user.username,
            bio: user.bio || '',
            pfp: user.pfp || '',
            country_code: user.country_code || '',
            myBikeId: user.myBikeId || null,
            myBike: user.myBike || null
        };
        return res.json(out);
    } catch (e) {
        console.error('GET_USER_ERROR:', e);
        return res.status(500).json({error: e?.message || 'server error'});
    }
});

/**
 * Update user settings (bio and bike).
 *
 * Accepts a JSON body with optional 'bio' and 'bike_name'. If 'bike_name' is
 * provided and non-empty the server will find or create a Bike by name and
 * set it as the user's primary bike.
 *
 * @route PATCH /user/:id
 * @param req Express request with params.id and JSON body { bio?, bike_name? }
 * @param res Express response
 */
app.patch('/user/:id', async (req, res) => {
    try {
        const id = parseInt(req.params.id, 10);
        if (isNaN(id)) return res.status(400).json({error: 'invalid user id'});
        const {bio, bike_name} = req.body || {};

        const exists = await prisma.user.findUnique({where: {id}});
        if (!exists) return res.status(404).json({error: 'User not found'});

        const dataToUpdate = {};
        if (typeof bio !== 'undefined') dataToUpdate.bio = bio;

        if (typeof bike_name !== 'undefined') {
            if (bike_name === null || String(bike_name).trim() === '') {
                dataToUpdate.myBikeId = null;
            } else {
                const bikeName = String(bike_name).trim();

                let bike = await prisma.bike.findFirst({
                    where: {name: bikeName},
                });

                if (!bike) {
                    bike = await prisma.bike.create({
                        data: {name: bikeName}
                    });
                }

                dataToUpdate.myBikeId = bike.id;
            }
        }

        const updated = await prisma.user.update({
            where: {id},
            data: dataToUpdate,
            include: {myBike: true}
        });

        return res.json({
            id: updated.id,
            email: updated.email,
            username: updated.username,
            bio: updated.bio || '',
            pfp: updated.pfp || '',
            myBikeId: updated.myBikeId || null,
            myBike: updated.myBike || null
        });
    } catch (e) {
        console.error('UPDATE_USER_ERROR:', e);
        return res.status(500).json({error: e?.message || 'server error'});
    }
});

/**
 * Upload or change profile picture.
 *
 * Expects multipart/form-data with field name 'pfp'. Saves the uploaded file to
 * the uploads directory, constructs an accessible URL, and updates the user's
 * pfp field in the database with that URL.
 *
 * @route POST /user/:id/pfp
 * @param req Express request (multipart) with file in req.file
 * @param res Express response
 */
app.post('/user/:id/pfp', upload.single('pfp'), async (req, res) => {
    try {
        const id = parseInt(req.params.id, 10);
        if (isNaN(id)) return res.status(400).json({error: 'invalid user id'});
        if (!req.file) return res.status(400).json({error: 'no file uploaded (field name must be "pfp")'});

        const fileUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

        const updated = await prisma.user.update({
            where: {id},
            data: {pfp: fileUrl},
        });

        return res.json({
            ok: true,
            id: updated.id,
            pfp: updated.pfp,
        });
    } catch (e) {
        console.error('UPLOAD_PFP_ERROR:', e);
        return res.status(500).json({error: e?.message || 'server error'});
    }
});

//get users in friends list
app.get('/users', async (_req, res) => {
    try {
        const users = await prisma.user.findMany({
            select: { id: true, username: true, pfp: true, lastOnline: true },
            orderBy: { username: 'asc' },
        });
        return res.json({ ok: true, data: users });
    } catch (e) {
        console.error('GET_USERS_ERROR:', e);
        return res.status(500).json({ error: e?.message || 'server error' });
    }
});

/**
 * Log unhandled promise rejections to avoid silent failures.
 *
 * Keeps a console trace for debugging unexpected promise errors.
 */
process.on('unhandledRejection', (e) => {
    console.error('UNHANDLED_REJECTION:', e);
});

/**
 * Start the HTTP server on the configured port.
 */
app.listen(PORT, () => console.log(`API running on http://localhost:${PORT}`));