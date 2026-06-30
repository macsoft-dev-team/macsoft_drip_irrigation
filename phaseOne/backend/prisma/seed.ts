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
  console.log("Cleaning up old command, valve, and device records...");
  await prisma.supportTicket.deleteMany();
  await prisma.scheduleRun.deleteMany();
  await prisma.irrigationSchedule.deleteMany();
  await prisma.masterHeartbeat.deleteMany();
  await prisma.valveStatusLog.deleteMany();
  await prisma.commandItem.deleteMany();
  await prisma.command.deleteMany();
  await prisma.valve.deleteMany();
  await prisma.slaveBoard.deleteMany();
  await prisma.masterController.deleteMany();
  await prisma.zone.deleteMany();

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
    where: { phone: "9876543211" },
    update: {},
    create: {
      name: "Demo Distributor",
      phone: "9876543211",
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
    where: { phone: "9876543212" },
    update: {},
    create: {
      name: "Demo Dealer",
      phone: "9876543212",
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
    where: { phone: "9876543213" },
    update: {},
    create: {
      name: "Demo Sales",
      phone: "9876543213",
      passwordHash: salesPassword,
      role: "sales"
    }
  });

  const csPassword = await hashPassword("support12345");
  await prisma.user.upsert({
    where: { phone: "9876543214" },
    update: {},
    create: {
      name: "Demo Support",
      phone: "9876543214",
      passwordHash: csPassword,
      role: "customer_service"
    }
  });

  const techPassword = await hashPassword("tech12345");
  await prisma.user.upsert({
    where: { phone: "9876543215" },
    update: {},
    create: {
      name: "Demo Technician",
      phone: "9876543215",
      passwordHash: techPassword,
      role: "technician"
    }
  });

  const tenantAdminPassword = await hashPassword("tenant12345");
  await prisma.user.upsert({
    where: { phone: "9876543216" },
    update: {},
    create: {
      name: "Demo Tenant Admin",
      phone: "9876543216",
      passwordHash: tenantAdminPassword,
      role: "tenant_admin",
      belongsToDistributorId: distributorUser.distributor!.id
    }
  });

  const farmerUser = await prisma.user.upsert({
    where: { phone: "8888888888" },
    update: {
      name: "John"
    },
    create: {
      name: "John",
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
    update: {
      name: "North Farm",
      locationName: "North plot"
    },
    create: {
      id: BigInt(1),
      farmerId,
      name: "North Farm",
      locationName: "North plot",
      areaAcres: 2.5
    }
  });

  const master = await prisma.masterController.upsert({
    where: { deviceUid: "MASTER-001" },
    update: {
      status: "online"
    },
    create: {
      fieldId: field.id,
      deviceUid: "MASTER-001",
      simNumber: "9000000000",
      firmwareVersion: "1.0.0",
      connectionType: "gsm4g",
      tankLevel: 80,
      motorStatus: "off",
      status: "online"
    }
  });

  // Create Slaves 1-3
  const slave1 = await prisma.slaveBoard.upsert({
    where: { deviceUid: "slave-001" },
    update: {
      modbusAddress: 1
    },
    create: {
      masterControllerId: master.id,
      deviceUid: "slave-001",
      name: "Slave Board 1",
      modbusAddress: 1,
      status: "active"
    }
  });

  const slave2 = await prisma.slaveBoard.upsert({
    where: { deviceUid: "slave-002" },
    update: {
      modbusAddress: 2
    },
    create: {
      masterControllerId: master.id,
      deviceUid: "slave-002",
      name: "Slave Board 2",
      modbusAddress: 2,
      status: "active"
    }
  });

  const slave3 = await prisma.slaveBoard.upsert({
    where: { deviceUid: "slave-003" },
    update: {
      modbusAddress: 3
    },
    create: {
      masterControllerId: master.id,
      deviceUid: "slave-003",
      name: "Slave Board 3",
      modbusAddress: 3,
      status: "active"
    }
  });

  // Create Zones Tomato and Banana
  const zoneTomato = await prisma.zone.upsert({
    where: { id: BigInt(1) },
    update: {
      name: "Tomato"
    },
    create: {
      id: BigInt(1),
      fieldId: field.id,
      name: "Tomato",
      description: "Tomato field section"
    }
  });

  const zoneBanana = await prisma.zone.upsert({
    where: { id: BigInt(2) },
    update: {
      name: "Banana"
    },
    create: {
      id: BigInt(2),
      fieldId: field.id,
      name: "Banana",
      description: "Banana field section"
    }
  });

  // Tomato Valves (A, B, C)
  await prisma.valve.upsert({
    where: { deviceUid: "valve-001" },
    update: {
      name: "Valve A",
      coilAddress: 0,
      zoneId: zoneTomato.id,
      slaveBoardId: slave1.id
    },
    create: {
      zoneId: zoneTomato.id,
      slaveBoardId: slave1.id,
      deviceUid: "valve-001",
      name: "Valve A",
      coilAddress: 0,
      status: "closed"
    }
  });

  await prisma.valve.upsert({
    where: { deviceUid: "valve-002" },
    update: {
      name: "Valve B",
      coilAddress: 1,
      zoneId: zoneTomato.id,
      slaveBoardId: slave2.id
    },
    create: {
      zoneId: zoneTomato.id,
      slaveBoardId: slave2.id,
      deviceUid: "valve-002",
      name: "Valve B",
      coilAddress: 1,
      status: "closed"
    }
  });

  await prisma.valve.upsert({
    where: { deviceUid: "valve-003" },
    update: {
      name: "Valve C",
      coilAddress: 2,
      zoneId: zoneTomato.id,
      slaveBoardId: slave3.id
    },
    create: {
      zoneId: zoneTomato.id,
      slaveBoardId: slave3.id,
      deviceUid: "valve-003",
      name: "Valve C",
      coilAddress: 2,
      status: "closed"
    }
  });

  // Banana Valves (D, E)
  await prisma.valve.upsert({
    where: { deviceUid: "valve-004" },
    update: {
      name: "Valve D",
      coilAddress: 1,
      zoneId: zoneBanana.id,
      slaveBoardId: slave1.id
    },
    create: {
      zoneId: zoneBanana.id,
      slaveBoardId: slave1.id,
      deviceUid: "valve-004",
      name: "Valve D",
      coilAddress: 1,
      status: "closed"
    }
  });

  await prisma.valve.upsert({
    where: { deviceUid: "valve-005" },
    update: {
      name: "Valve E",
      coilAddress: 0,
      zoneId: zoneBanana.id,
      slaveBoardId: slave2.id
    },
    create: {
      zoneId: zoneBanana.id,
      slaveBoardId: slave2.id,
      deviceUid: "valve-005",
      name: "Valve E",
      coilAddress: 0,
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
