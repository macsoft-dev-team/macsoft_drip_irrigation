import { z } from "zod";
import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";
import { fieldService } from "./fieldService";

const createMasterSchema = z.object({
  deviceUid: z.string().min(2).max(100),
  imei: z.string().max(50).optional(),
  simNumber: z.string().max(30).optional(),
  firmwareVersion: z.string().max(50).optional(),
  connectionType: z.enum(["gsm4g", "gsm5g", "wifi", "loraGateway"]).default("gsm4g")
});

const updateMasterSchema = createMasterSchema.partial().extend({
  status: z.enum(["online", "offline", "error", "disabled"]).optional()
});

export const masterControllerService = {
  async createForField(auth: Express.Request["auth"], fieldId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await fieldService.assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    const data = createMasterSchema.parse(input);

    return prisma.masterController.create({
      data: {
        fieldId,
        deviceUid: data.deviceUid,
        imei: data.imei,
        simNumber: data.simNumber,
        firmwareVersion: data.firmwareVersion,
        connectionType: data.connectionType
      }
    });
  },

  async getByField(auth: Express.Request["auth"], fieldId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await fieldService.assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    return prisma.masterController.findUnique({
      where: { fieldId }
    });
  },

  async update(auth: Express.Request["auth"], masterControllerId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const master = await prisma.masterController.findUnique({
      where: { id: masterControllerId },
      include: { field: true }
    });
    if (!master) throw new AppError(404, "Master controller not found", "masterNotFound");

    if (auth.role === "farmer" && master.field.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = updateMasterSchema.parse(input);

    return prisma.masterController.update({
      where: { id: masterControllerId },
      data
    });
  }
};
