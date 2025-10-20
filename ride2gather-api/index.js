require('dotenv').config();

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');                // <= pure JS, safer on Windows
const { PrismaClient } = require('@prisma/client');
const app = express();
const prisma = new PrismaClient({ log: ['query', 'warn', 'error'] });
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '1mb' }));

//health
app.get('/', (_req, res) => res.json({ ok: true, service: 'ride2gather-api' }));

//list users quickly - debugging
app.get('/debug/users', async (_req, res) => {
    const users = await prisma.user.findMany({
        select: { id: true, email: true, username: true, createdAt: true }
    });
    res.json(users);
});

//signup functionality
app.post('/signup', async (req, res) => {
    console.log('SIGNUP BODY:', req.body); //debugging purpose

    try {
        const { email, username, password, country_code = "" } = req.body || {};
        //basic validation
        if (!email || !username || !password) {
            return res.status(422).json({ error: 'email, username, and password are required' });
        }

        if (String(username).length < 3) {
            return res.status(422).json({ error: 'username must be at least 3 chars' });
        }

        if (String(password).length < 6) {
            return res.status(422).json({ error: 'password must be at least 6 chars' });
        }

        //manual duplicate check (friendly error before Prisma throws)
        const exists = await prisma.user.findFirst({
            where: { OR: [{ email }, { username }] },
            select: { id: true }
        });

        if (exists) return res.status(409).json({ error: 'email or username already exists' });

        //hash & create
        const hash = await bcrypt.hash(password, 10);
        const user = await prisma.user.create({
            data: { email, username, passwordHash: hash, country_code }
        });
        console.log('Created user:', user);
        return res.status(201).json({ id: user.id, email: user.email, username: user.username, country_code: user.country_code });

    } catch (e) {
        if (e && e.code === 'P2002') {
            return res.status(409).json({ error: 'email or username already exists' });
        }
        console.error('SIGNUP_ERROR:', e);
        return res.status(500).json({ error: e?.message || 'server error' });
    }
});

// LOGIN ENDPOINT: Accept email OR username in 'identity' field
app.post('/login', async (req, res) => {
    const { identity, password } = req.body || {};
    if (!identity || !password) {
        return res.status(422).json({ error: 'username/email and password are required' });
    }
    try {
        const user = await prisma.user.findFirst({
            where: {
                OR: [
                    { email: identity },
                    { username: identity }
                ]
            }
        });
        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }
        const valid = await bcrypt.compare(password, user.passwordHash);
        if (!valid) {
            return res.status(401).json({ error: "Invalid password" });
        }
        // For real-world use, issue a JWT here and return it. For now:
        return res.json({
            id: user.id,
            email: user.email,
            username: user.username,
            country_code: user.country_code
        });
    } catch (e) {
        console.error('LOGIN_ERROR:', e);
        return res.status(500).json({ error: e?.message || "server error" });
    }
});

/**
 * Get user by username (including their primary bike info if set)
 * returns 200 with user object or 404 if not found
 * user object example:
 * {
 *   id, email, username, bio, pfp, country_code, myBikeId, myBike: { id, name, image }
 * }
 */
app.get('/user/:username', async (req, res) => {
    try {
        const { username } = req.params;
        const user = await prisma.user.findUnique({
            where: { username },
            include: { myBike: true }
        });
        if (!user) return res.status(404).json({ error: 'User not found' });
        // return selected fields only
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
        return res.status(500).json({ error: e?.message || 'server error' });
    }
});

/**
 * Update user settings (bio and bike)
 * Accepts JSON body: { bio?: string, bike_name?: string }
 *
 * Note: Prisma.upsert requires a unique field in `where`. In this project's Prisma schema the Bike.name
 * field is not marked unique, so upsert({ where: { name } }) fails.  To avoid that we:
 *  - try to find a Bike by name (findFirst)
 *  - if found, reuse it
 *  - otherwise create a new Bike row (create)
 */
app.patch('/user/:id', async (req, res) => {
    try {
        const id = parseInt(req.params.id, 10);
        if (isNaN(id)) return res.status(400).json({ error: 'invalid user id' });
        const { bio, bike_name } = req.body || {};

        // Make sure user exists
        const exists = await prisma.user.findUnique({ where: { id } });
        if (!exists) return res.status(404).json({ error: 'User not found' });

        const dataToUpdate = {};
        if (typeof bio !== 'undefined') dataToUpdate.bio = bio;

        if (typeof bike_name !== 'undefined') {
            if (bike_name === null || String(bike_name).trim() === '') {
                // clear the bike selection
                dataToUpdate.myBikeId = null;
            } else {
                const bikeName = String(bike_name).trim();

                // Try to find an existing bike with this name (name is not unique in schema,
                // so we cannot upsert by name). If none found, create a new bike row.
                let bike = await prisma.bike.findFirst({
                    where: { name: bikeName },
                    // optionally include other distinguishing fields if you want
                });

                if (!bike) {
                    bike = await prisma.bike.create({
                        data: { name: bikeName }
                    });
                }

                dataToUpdate.myBikeId = bike.id;
            }
        }

        const updated = await prisma.user.update({
            where: { id },
            data: dataToUpdate,
            include: { myBike: true }
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
        return res.status(500).json({ error: e?.message || 'server error' });
    }
});

//log unhandled promise rejections so nothing is swallowed
process.on('unhandledRejection', (e) => {
    console.error('UNHANDLED_REJECTION:', e);
});

app.listen(PORT, () => console.log(`API running on http://localhost:${PORT}`));