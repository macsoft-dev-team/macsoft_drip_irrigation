import { z } from "zod";
import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";

const createFieldSchema = z.object({
  name: z.string().min(1).max(150),
  locationName: z.string().max(255).optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  areaAcres: z.number().optional()
});

const updateFieldSchema = createFieldSchema.partial().extend({
  status: z.enum(["active", "inactive"]).optional()
});

async function assertFarmerOwnsField(farmerId: bigint, fieldId: bigint) {
  const field = await prisma.field.findFirst({
    where: { id: fieldId, farmerId }
  });
  if (!field) throw new AppError(404, "Field not found", "fieldNotFound");
  return field;
}

export const fieldService = {
  assertFarmerOwnsField,

  async listFields(auth: Express.Request["auth"]) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const where =
      auth.role === "farmer"
        ? { farmerId: auth.farmerId }
        : {};

    return prisma.field.findMany({
      where,
      include: {
        masterController: true,
        zones: {
          include: {
            valves: true
          }
        }
      },
      orderBy: { id: "desc" }
    });
  },

  async createField(farmerId: bigint, input: unknown) {
    const data = createFieldSchema.parse(input);

    return prisma.field.create({
      data: {
        farmerId,
        name: data.name,
        locationName: data.locationName,
        latitude: data.latitude,
        longitude: data.longitude,
        areaAcres: data.areaAcres
      }
    });
  },

  async getField(auth: Express.Request["auth"], fieldId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    if (auth.role === "farmer") {
      await assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    return prisma.field.findUnique({
      where: { id: fieldId },
      include: {
        masterController: true,
        zones: { include: { valves: true } }
      }
    });
  },

  async updateField(auth: Express.Request["auth"], fieldId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    if (auth.role === "farmer") {
      await assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    const data = updateFieldSchema.parse(input);

    return prisma.field.update({
      where: { id: fieldId },
      data
    });
  },

  async deleteField(auth: Express.Request["auth"], fieldId: bigint) {
    return this.updateField(auth, fieldId, { status: "inactive" });
  }
};
