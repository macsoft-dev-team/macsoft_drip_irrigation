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

  const adminUser = await prisma.user.upsert({
    where: { phone: "9999999999" },
    update: {},
    create: {
      name: "Admin",
      phone: "9999999999",
      passwordHash: adminPassword,
      role: "admin"
    }
  });

  const distributorPassword = await hashPassword("distributor12345");
  const distributorUser = await prisma.user.upsert({
    where: { phone: "7777777777" },
    update: {},
    create: {
      name: "Demo Distributor",
      phone: "7777777777",
      passwordHash: distributorPassword,
      role: "distributor",
      distributor: {
        create: {
          businessName: "Macro Drip Distributors",
          gstNumber: "GST123456789",
          address: "Distributor Hub, Industrial Area"
        }
      }
    },
    include: { distributor: true }
  });

  const dealerPassword = await hashPassword("dealer12345");
  const dealerUser = await prisma.user.upsert({
    where: { phone: "6666666666" },
    update: {},
    create: {
      name: "Demo Dealer",
      phone: "6666666666",
      passwordHash: dealerPassword,
      role: "dealer",
      hasWholesalePricing: true, // Optional wholesale enabled
      dealer: {
        create: {
          businessName: "Agri Drip Retailers",
          gstNumber: "GST987654321",
          address: "Dealer Shop, Market Street"
        }
      }
    },
    include: { dealer: true }
  });

  const salesPassword = await hashPassword("sales12345");
  await prisma.user.upsert({
    where: { phone: "5555555555" },
    update: {},
    create: {
      name: "Demo Sales",
      phone: "5555555555",
      passwordHash: salesPassword,
      role: "sales"
    }
  });

  const csPassword = await hashPassword("support12345");
  await prisma.user.upsert({
    where: { phone: "4444444444" },
    update: {},
    create: {
      name: "Demo Support",
      phone: "4444444444",
      passwordHash: csPassword,
      role: "customer_service"
    }
  });

  const techPassword = await hashPassword("tech12345");
  await prisma.user.upsert({
    where: { phone: "3333333333" },
    update: {},
    create: {
      name: "Demo Technician",
      phone: "3333333333",
      passwordHash: techPassword,
      role: "technician"
    }
  });

  const tenantAdminPassword = await hashPassword("tenant12345");
  await prisma.user.upsert({
    where: { phone: "2222222222" },
    update: {},
    create: {
      name: "Demo Tenant Admin",
      phone: "2222222222",
      passwordHash: tenantAdminPassword,
      role: "tenant_admin",
      belongsToDistributorId: distributorUser.distributor!.id
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
          state: "Demo State",
          distributorId: distributorUser.distributor!.id,
          dealerId: dealerUser.dealer!.id
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

  const master = await prisma.masterController.upsert({
    where: { deviceUid: "master-demo-001" },
    update: {},
    create: {
      fieldId: field.id,
      deviceUid: "master-demo-001",
      simNumber: "9000000000",
      firmwareVersion: "1.0.0",
      connectionType: "gsm4g",
      tankLevel: 80,
      motorStatus: "off"
    }
  });

  const slaveBoard = await prisma.slaveBoard.upsert({
    where: { deviceUid: "slave-demo-001" },
    update: {},
    create: {
      masterControllerId: master.id,
      deviceUid: "slave-demo-001",
      name: "Slave Board 1",
      status: "active"
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
      slaveBoardId: slaveBoard.id,
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
      slaveBoardId: slaveBoard.id,
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
      price: 8500,
      wholesalePrice: 7000
    }
  });

  await prisma.product.upsert({
    where: { sku: "VALVE-001" },
    update: {},
    create: {
      name: "Irrigation Valve",
      sku: "VALVE-001",
      type: "valve",
      price: 1200,
      wholesalePrice: 950
    }
  });

  await prisma.product.upsert({
    where: { sku: "SERVICE-FEE-001" },
    update: {},
    create: {
      name: "Platform & Remote Support Fee",
      sku: "SERVICE-FEE-001",
      type: "serviceFee",
      price: 499,
      wholesalePrice: 400
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
