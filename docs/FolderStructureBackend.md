backend/
│
├── src/
│   │
│   ├── main.ts
│   ├── app.module.ts
│   │
│   ├── config/
│   │   ├── app.config.ts
│   │   ├── database.config.ts
│   │   ├── mqtt.config.ts
│   │   ├── redis.config.ts
│   │   └── env.validation.ts
│   │
│   ├── common/
│   │   ├── decorators/
│   │   ├── filters/
│   │   ├── guards/
│   │   ├── interceptors/
│   │   ├── middleware/
│   │   ├── pipes/
│   │   ├── utils/
│   │   ├── constants/
│   │   └── types/
│   │
│   ├── prisma/
│   │   ├── prisma.module.ts
│   │   ├── prisma.service.ts
│   │   └── schema.prisma
│   │
│   ├── infrastructure/
│   │   ├── mqtt/
│   │   ├── redis/
│   │   ├── websocket/
│   │   ├── queues/
│   │   ├── logger/
│   │   └── monitoring/
│   │
│   ├── modules/
│   │   │
│   │   ├── auth/
│   │   │   ├── controllers/
│   │   │   ├── services/
│   │   │   ├── dto/
│   │   │   ├── entities/
│   │   │   ├── guards/
│   │   │   ├── strategies/
│   │   │   ├── auth.module.ts
│   │   │   └── auth.service.ts
│   │   │
│   │   ├── tenants/
│   │   ├── users/
│   │   ├── farms/
│   │   ├── devices/
│   │   ├── telemetry/
│   │   ├── commands/
│   │   ├── alerts/
│   │   ├── schedules/
│   │   └── analytics/
│   │
│   ├── workers/
│   │   ├── telemetry.worker.ts
│   │   ├── command.worker.ts
│   │   ├── alert.worker.ts
│   │   └── retry.worker.ts
│   │
│   └── shared/
│       ├── dto/
│       ├── interfaces/
│       ├── enums/
│       └── helpers/
│
├── test/
├── docker/
├── scripts/
├── .env
├── docker-compose.yml
├── package.json
└── README.md


devices/
├── controllers/
│   └── devices.controller.ts
│
├── services/
│   ├── devices.service.ts
│   └── device-status.service.ts
│
├── dto/
│   ├── create-device.dto.ts
│   ├── update-device.dto.ts
│   └── command-device.dto.ts
│
├── entities/
│   └── device.entity.ts
│
├── gateways/
│   └── devices.gateway.ts
│
├── repositories/
│   └── devices.repository.ts
│
└── devices.module.ts



telemetry/
├── controllers/
├── services/
├── dto/
├── repositories/
├── processors/
├── telemetry.module.ts