import { prisma } from "../db/prisma";

export const masterControllerRepository = {
  async createForField(fieldId: bigint, data: any) {
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

  async findByFieldId(fieldId: bigint) {
    return prisma.masterController.findUnique({
      where: { fieldId }
    });
  },

  async findById(id: bigint) {
    return prisma.masterController.findUnique({
      where: { id },
      include: { field: true }
    });
  },

  async update(id: bigint, data: any) {
    return prisma.masterController.update({
      where: { id },
      data
    });
  },

  async delete(id: bigint) {
    return prisma.masterController.delete({
      where: { id }
    });
  }
};
