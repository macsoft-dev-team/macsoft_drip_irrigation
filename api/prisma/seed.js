const { prisma } = require('../prisma/client');
const bcrypt = require('bcrypt');
const fs = require('fs');
const path = require('path');

async function seed() {
    // 1. Create Default Tenants
    const systemTenantId = 'da7c191a-7b3b-4c5c-9db8-0245cfd3d4b9';
    const customerTenantId = 'ca8c191a-7b3b-4c5c-9db8-0245cfd3d4b9';

    await prisma.tenant.upsert({
        where: { id: systemTenantId },
        update: {},
        create: {
            id: systemTenantId,
            name: 'Macsoft System',
            slug: 'system',
            plan: 'enterprise',
            useSubRoles: false,
            isActive: true,
        },
    });

    await prisma.tenant.upsert({
        where: { id: customerTenantId },
        update: {
            useSubRoles: true,
        },
        create: {
            id: customerTenantId,
            name: 'Default Customer',
            slug: 'customer',
            plan: 'starter',
            useSubRoles: true,
            isActive: true,
        },
    });

    console.log('Seeded default tenants successfully.');

    // 2. Create Users
    const usersPath = path.join(__dirname, 'seeds', 'user.json');
    const users = JSON.parse(fs.readFileSync(usersPath, 'utf-8'));
    const password = 'admin123';

    for (const user of users) {
        const passwordHash = await bcrypt.hash(password, 10);
        const tenantId = (user.email.includes('macsoft.com'))
            ? systemTenantId
            : customerTenantId;

        await prisma.user.upsert({
            where: { email: user.email },
            update: {
                role: user.role,
                tenantId: tenantId,
            },
            create: {
                name: user.name,
                email: user.email,
                role: user.role,
                passwordHash: passwordHash,
                tenantId: tenantId,
            },
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
