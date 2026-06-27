declare global {
  namespace Express {
    interface Request {
      auth?: {
        userId: bigint;
        role: string;
        farmerId?: bigint;
        distributorId?: bigint;
        dealerId?: bigint;
      };
    }
  }
}

export {};
