# Phase 1 Drip Irrigation API & Frontend Integration Plan (Centralized Architecture)

Restructure the Node.js + Express + Prisma backend codebase to strictly follow a centralized, resource-based layer flow:
`Route (src/routes/) -> Controller (src/controllers/) -> Validation (src/validations/) -> Service (src/services/) -> Repository (src/repositories/) -> Prisma (src/db/)`

Remove the unwanted `src/modules/` directory, update all endpoints to conform to this structure, and integrate them with the React + Vite frontend.

## User Review Required

> [!IMPORTANT]
> The database schema is fully aligned with the models. We will populate the MySQL database using the seed script, run the dev server, and perform transparent syncing from the React frontend.

> [!WARNING]
> We will delete the `src/modules/` directory entirely, consolidating all routing and business logic into the centralized layered folders:
> - `src/routes/`
> - `src/controllers/`
> - `src/validations/`
> - `src/services/`
> - `src/repositories/`

## Open Questions

None. The user has clarified they prefer the centralized `src/controllers/`, `src/services/` structure.

## Proposed Changes

### Central Routing & Layers Setup

#### [MODIFY] [index.ts](file:///home/ubuntu/develop/workspace/macsoft_drip_irrigation/phaseOne/backend/src/routes/index.ts)
Register all routing endpoints directly from central routers:
- `/auth` -> `authRoutes`
- `/users` -> `userRoutes`
- `/farmers` -> `farmerRoutes`
- `/fields` -> `fieldRoutes`
- `/masters` -> `masterControllerRoutes`
- `/slaves` -> `slaveBoardRoutes`
- `/valves` -> `valveRoutes`
- `/zones` -> `zoneRoutes`
- `/irrigation` -> `irrigationRoutes`
- `/schedules` -> `scheduleRoutes`
- `/monitoring` -> `monitoringRoutes`
- `/tickets` -> `supportTicketRoutes`
- `/dashboard` -> `dashboardRoutes`

#### [NEW] [userRepository.ts](file:///home/ubuntu/develop/workspace/macsoft_drip_irrigation/phaseOne/backend/src/repositories/userRepository.ts) (and other repositories)
Create individual repositories for each resource under `src/repositories/` to wrap Prisma queries.

#### [NEW] [userValidation.ts](file:///home/ubuntu/develop/workspace/macsoft_drip_irrigation/phaseOne/backend/src/validations/userValidation.ts) (and other validations)
Create validations under `src/validations/` to wrap Zod schema definitions.

#### [DELETE] [modules](file:///home/ubuntu/develop/workspace/macsoft_drip_irrigation/phaseOne/backend/src/modules)
Delete the `src/modules/` directory entirely.

### Layers Implementation List
We will implement/refactor the following resources across all layers:
- **Auth**: `authRoutes.ts`, `authController.ts`, `authValidation.ts`, `authService.ts`, `authRepository.ts`
- **Users**: `userRoutes.ts`, `userController.ts`, `userValidation.ts`, `userService.ts`, `userRepository.ts`
- **Farmers**: `farmerRoutes.ts`, `farmerController.ts`, `farmerValidation.ts`, `farmerService.ts`, `farmerRepository.ts`
- **Fields**: `fieldRoutes.ts`, `fieldController.ts`, `fieldValidation.ts`, `fieldService.ts`, `fieldRepository.ts`
- **Master Controllers**: `masterControllerRoutes.ts`, `masterControllerController.ts`, `masterControllerValidation.ts`, `masterControllerService.ts`, `masterControllerRepository.ts`
- **Slave Boards**: `slaveBoardRoutes.ts`, `slaveBoardController.ts`, `slaveBoardValidation.ts`, `slaveBoardService.ts`, `slaveBoardRepository.ts`
- **Valves**: `valveRoutes.ts`, `valveController.ts`, `valveValidation.ts`, `valveService.ts`, `valveRepository.ts`
- **Zones**: `zoneRoutes.ts`, `zoneController.ts`, `zoneValidation.ts`, `zoneService.ts`, `zoneRepository.ts`
- **Irrigation**: `irrigationRoutes.ts`, `irrigationController.ts`, `irrigationValidation.ts`, `irrigationService.ts`, `irrigationRepository.ts`, `commandService.ts`
- **Schedules**: `scheduleRoutes.ts`, `scheduleController.ts`, `scheduleValidation.ts`, `scheduleService.ts`, `scheduleRepository.ts`, `scheduler.ts`
- **Monitoring**: `monitoringRoutes.ts`, `monitoringController.ts`, `monitoringValidation.ts`, `monitoringService.ts`, `monitoringRepository.ts`
- **Support Tickets**: `supportTicketRoutes.ts`, `supportTicketController.ts`, `supportTicketValidation.ts`, `supportTicketService.ts`, `supportTicketRepository.ts`
- **Dashboard**: `dashboardRoutes.ts`, `dashboardController.ts`, `dashboardValidation.ts`, `dashboardService.ts`, `dashboardRepository.ts`

### Frontend API Integration

#### [MODIFY] [App.jsx](file:///home/ubuntu/develop/workspace/macsoft_drip_irrigation/phaseOne/frontend/src/App.jsx)
Integrate the frontend with the Node + Express backend API using transparent syncing and status polling.

## Verification Plan

### Automated Tests
- Run `npm run lint` and `npm run build` in backend and frontend to verify compile accuracy.

### Manual Verification
- Seed the database using `npm run prisma:seed`.
- Start servers: `npm run dev` in backend and frontend.
- Actuate a valve in the UI and verify that a command is created in the database and logged in the terminal.
