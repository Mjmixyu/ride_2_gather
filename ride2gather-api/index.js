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
    console.log('SIGNUP BODY:', req.body);  // <-- see what Flutter sends

    try {
        const { email, username, password } = req.body || {};
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
            data: { email, username, passwordHash: hash }
        });
        return res.status(201).json({ id: user.id, email: user.email, username: user.username });

    } catch (e) {
        //known Prisma duplicate error
        if (e && e.code === 'P2002') {
            return res.status(409).json({ error: 'email or username already exists' });
        }

        //log everything server-side
        console.error('SIGNUP_ERROR:', e);

        // surface the message to help you debug quickly - will remove comments/functionality like this in future release
        return res.status(500).json({ error: e?.message || 'server error' });

    }

});

//log unhandled promise rejections so nothing is swallowed
process.on('unhandledRejection', (e) => {
    console.error('UNHANDLED_REJECTION:', e);
});

app.listen(PORT, () => console.log(`API running on http://localhost:${PORT}`));
 