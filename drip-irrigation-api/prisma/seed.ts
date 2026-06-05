import { PrismaMariaDb } from "@prisma/adapter-mariadb";
import { PrismaClient } from "../generated/prisma/client";
import { hashPassword } from "../src/lib/password";
import { env } from "../src/config/env";

const adapter = new PrismaMariaDb({
  host: env.DATABASE_HOST,
  port: env.DATABASE_PORT,
  user: env.DATABASE_USER,
  password: env.DATABASE_PASSWORD,
  database: env.DATABASE_NAME,
  connectionLimit: env.DATABASE_CONNECTION_LIMIT
});

const prisma = new PrismaClient({ adapter });

async function main() {
  const adminPassword = await hashPassword("admin12345");
  const farmerPassword = await hashPassword("farmer12345");

  await prisma.user.upsert({
    where: { phone: "9999999999" },
    update: {},
    create: {
      name: "Admin",
      phone: "9999999999",
      passwordHash: adminPassword,
      role: "admin"
    }
  });

  const farmerUser = await prisma.user.upsert({
    where: { phone: "8888888888" },
    update: {},
    create: {
      name: "Demo Farmer",
      phone: "8888888888",
      passwordHash: farmerPassword,
      role: "farmer",
      farmer: {
        create: {
          village: "Demo Village",
          district: "Demo District",
          state: "Demo State"
        }
      }
    },
    include: { farmer: true }
  });

  const farmerId = farmerUser.farmer!.id;

  const field = await prisma.field.upsert({
    where: { id: BigInt(1) },
    update: {},
    create: {
      farmerId,
      name: "Field 1",
      locationName: "North plot",
      areaAcres: 2.5
    }
  });

  await prisma.masterController.upsert({
    where: { deviceUid: "master-demo-001" },
    update: {},
    create: {
      fieldId: field.id,
      deviceUid: "master-demo-001",
      simNumber: "9000000000",
      firmwareVersion: "1.0.0",
      connectionType: "gsm4g"
    }
  });

  const zoneA = await prisma.zone.upsert({
    where: { id: BigInt(1) },
    update: {},
    create: {
      fieldId: field.id,
      name: "Zone A"
    }
  });

  await prisma.valve.upsert({
    where: { deviceUid: "valve-demo-001" },
    update: {},
    create: {
      zoneId: zoneA.id,
      deviceUid: "valve-demo-001",
      name: "Valve 1",
      valveNumber: 1,
      status: "closed"
    }
  });

  await prisma.valve.upsert({
    where: { deviceUid: "valve-demo-002" },
    update: {},
    create: {
      zoneId: zoneA.id,
      deviceUid: "valve-demo-002",
      name: "Valve 2",
      valveNumber: 2,
      status: "closed"
    }
  });

  await prisma.product.upsert({
    where: { sku: "MASTER-4G-001" },
    update: {},
    create: {
      name: "4G Master Controller",
      sku: "MASTER-4G-001",
      type: "masterController",
      price: 8500
    }
  });

  await prisma.product.upsert({
    where: { sku: "VALVE-001" },
    update: {},
    create: {
      name: "Irrigation Valve",
      sku: "VALVE-001",
      type: "valve",
      price: 1200
    }
  });

  await prisma.product.upsert({
    where: { sku: "SERVICE-FEE-001" },
    update: {},
    create: {
      name: "Platform & Remote Support Fee",
      sku: "SERVICE-FEE-001",
      type: "serviceFee",
      price: 499
    }
  });

  console.log("Seed completed");
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
