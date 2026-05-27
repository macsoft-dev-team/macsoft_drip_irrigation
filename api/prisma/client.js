const { PrismaPg } = require("@prisma/adapter-pg");
const { PrismaClient } = require("../generated/prisma/client");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") ,quiet: true});

const connectionString = `${process.env.DATABASE_URL}`;

// Initialize the Postgres adapter
const adapter = new PrismaPg({ connectionString });

// Instantiate the Prisma Client with the adapter
const prisma = new PrismaClient({ adapter });

module.exports = { prisma };