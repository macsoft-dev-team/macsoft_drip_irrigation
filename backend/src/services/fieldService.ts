import { z } from "zod";
import { prisma } from "../db/prisma.js";
import { AppError } from "../lib/AppError.js";
import { activityLogService } from "./activityLogService.js";

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
            valves: {
              include: {
                slaveBoard: true
              }
            }
          }
        }
      },
      orderBy: { id: "desc" }
    });
  },

  async createField(auth: Express.Request["auth"], input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const farmerId = auth.role === "farmer" ? auth.farmerId! : BigInt(input && typeof input === "object" && "farmerId" in input ? (input as any).farmerId : 1);
    const data = createFieldSchema.parse(input);

    const field = await prisma.field.create({
      data: {
        farmerId,
        name: data.name,
        locationName: data.locationName,
        latitude: data.latitude,
        longitude: data.longitude,
        areaAcres: data.areaAcres
      }
    });

    await activityLogService.log(auth.userId, "create", "field", field.id, { name: field.name });
    return field;
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
        zones: {
          include: {
            valves: {
              include: {
                slaveBoard: true
              }
            }
          }
        }
      }
    });
  },

  async updateField(auth: Express.Request["auth"], fieldId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    if (auth.role === "farmer") {
      await assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    const data = updateFieldSchema.parse(input);

    const updated = await prisma.field.update({
      where: { id: fieldId },
      data
    });

    await activityLogService.log(auth.userId, "update", "field", updated.id, { name: updated.name });
    return updated;
  },

  async deleteField(auth: Express.Request["auth"], fieldId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const deleted = await this.updateField(auth, fieldId, { status: "inactive" });
    await activityLogService.log(auth.userId, "delete", "field", fieldId);
    return deleted;
  }
};
