
const { prisma } = require('../prisma/client');
const bcrypt = require('bcrypt');
const fs = require('fs');
const path = require('path');

async function seed() {
    const usersPath = path.join(__dirname, 'seeds', 'user.json');
    const users = JSON.parse(fs.readFileSync(usersPath, 'utf-8'));
    const password = 'admin123';
    for (const user of users) {
        const passwordHash = await bcrypt.hash(password, 10);
        await prisma.user.upsert({
            where: { email: user.email },
            update: {},
            create: {
                name: user.name,
                email: user.email,
                role: user.role,
                password: passwordHash,
                phone: user.phone
            }
        });
    }
    console.log('Seeded users successfully.');
}

seed()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
