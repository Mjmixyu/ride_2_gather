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

//log unhandled promise rejections so nothing is swallowed
process.on('unhandledRejection', (e) => {
    console.error('UNHANDLED_REJECTION:', e);
});

app.listen(PORT, () => console.log(`API running on http://localhost:${PORT}`));